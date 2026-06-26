import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Importante: Gerador de IDs offline
import '../models/fornecedor.dart';
import 'fornecedor_service.dart';
import 'fornecedor_db_helper.dart';

class FornecedorServiceHibrido implements FornecedorService {
  final _supabase = Supabase.instance.client;
  final _dbLocal = FornecedorDbHelper.instance;
  final _uuid = const Uuid();

  // Função interna para varrer o SQLite e enviar os atrasados para o Supabase
  Future<void> _sincronizarPendentes() async {
    try {
      final pendentes = await _dbLocal.listarPendentes();
      for (var json in pendentes) {
        final mapaAjustado = Map<String, dynamic>.from(json);
        mapaAjustado['ativo'] = json['ativo'] == 1;
        // Remove a flag local antes de mandar para a nuvem
        mapaAjustado.remove('sincronizado');

        // Faz o Upsert (Se não existe, insere. Se existe, atualiza)
        await _supabase.from('fornecedores').upsert(mapaAjustado);

        // Se deu certo, marca no celular que a sincronização foi feita
        await _dbLocal.marcarComoSincronizado(json['id'] as String);
      }
    } catch (e) {
      // Se falhar a sincronização, apenas ignora. Tenta novamente na próxima vez.
      print('Sincronização em background falhou: $e');
    }
  }

  @override
  Future<void> deletarFornecedor(String id) async {
    // 1. Apaga do banco local imediatamente
    await _dbLocal.deletarLocal(id);

    // 2. Tenta apagar na nuvem
    try {
      await _supabase.from('fornecedores').delete().eq('id', id);
    } catch (e) {
      print('Aviso: Exclusão feita localmente. Falha ao acessar a nuvem no momento.');
    }
  }

  @override
  Future<List<Fornecedor>> listarFornecedores() async {
    // Sempre tenta sincronizar a fila antes de buscar dados novos
    await _sincronizarPendentes();

    try {
      final resposta = await _supabase
          .from('fornecedores')
          .select()
          .order('nome', ascending: true);

      final fornecedoresNuvem = resposta
          .map((json) => Fornecedor.fromMap(json))
          .toList();

      for (var fornecedor in fornecedoresNuvem) {
        // Salva as novidades garantindo que estão marcadas como sincronizadas
        await _dbLocal.salvarLocal(fornecedor, estaSincronizado: true);
      }
    } catch (e) {
      print('Modo Offline ativado na leitura.');
    }

    // A fonte de verdade para a interface visual é sempre o banco local
    return await _dbLocal.listarLocal();
  }

  @override
  Future<void> adicionarFornecedor(Fornecedor fornecedor) async {
    // 1. Gera o ID no próprio celular para garantir que ele existe offline
    final String novoId = fornecedor.id ?? _uuid.v4();

    // Recria o objeto com o ID garantido
    final fornecedorComId = Fornecedor(
      id: novoId,
      nome: fornecedor.nome,
      cnpj: fornecedor.cnpj,
      fone: fornecedor.fone,
      email: fornecedor.email,
      endereco: fornecedor.endereco,
      ativo: fornecedor.ativo,
      dataCriacao: fornecedor.dataCriacao ?? DateTime.now(),
    );

    // 2. Salva localmente IMEDIATAMENTE (status pendente = false)
    await _dbLocal.salvarLocal(fornecedorComId, estaSincronizado: false);

    // 3. Tenta enviar para a nuvem em seguida
    try {
      await _supabase.from('fornecedores').insert(fornecedorComId.toMap());
      // Se sucesso, atualiza o status local para sincronizado
      await _dbLocal.marcarComoSincronizado(novoId);
    } catch (e) {
      print('Modo Offline: Fornecedor salvo localmente. Será enviado depois.');
    }
  }

  @override
  Future<void> atualizarFornecedor(Fornecedor fornecedor) async {
    if (fornecedor.id == null)
      throw Exception('ID necessário para atualização.');

    // 1. Salva a edição localmente IMEDIATAMENTE como pendente
    await _dbLocal.salvarLocal(fornecedor, estaSincronizado: false);

    // 2. Tenta atualizar a nuvem
    try {
      await _supabase
          .from('fornecedores')
          .update(fornecedor.toMap())
          .eq('id', fornecedor.id!);

      // Se sucesso, remove a pendência
      await _dbLocal.marcarComoSincronizado(fornecedor.id!);
    } catch (e) {
      print('Modo Offline: Edição salva localmente. Será atualizada depois.');
    }
  }
}
