import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/insumo.dart';
import 'insumos_service.dart';
import 'insumos_db_helper.dart';

class InsumosServiceHibrido implements InsumosService {
  final _supabase = Supabase.instance.client;
  final _dbLocal = InsumosDbHelper.instance;
  final _uuid = const Uuid();

  // Método de sincronização robusto integrado à lógica original de mapas
  Future<void> _sincronizarPendentes() async {
    try {
      final pendentes = await _dbLocal.listarPendentes();
      for (var json in pendentes) {
        final mapaAjustado = Map<String, dynamic>.from(json);
        String? urlAtual = mapaAjustado['imagem_url'];

        // Se o registro offline armazena um arquivo local do celular e agora temos rede,
        // realiza o upload tardio da foto física para o Supabase Storage
        if (urlAtual != null && !urlAtual.startsWith('http') && urlAtual.isNotEmpty) {
          try {
            final arquivoLocal = File(urlAtual);
            if (await arquivoLocal.exists()) {
              final nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
              final pathNoBucket = 'public/$nomeArquivo';
              final bytes = await arquivoLocal.readAsBytes();

              // Faz o upload do binário para o Storage
              await _supabase.storage.from('insumos').uploadBinary(pathNoBucket, bytes);

              // Gera a URL pública real da internet
              final urlPublica = _supabase.storage.from('insumos').getPublicUrl(pathNoBucket);

              mapaAjustado['imagem_url'] = urlPublica;

              // Atualiza o banco SQLite local com a nova URL estável da nuvem
              await _dbLocal.salvarLocal(Insumo.fromMap(mapaAjustado), estaSincronizado: true);
            }
          } catch (err) {
            print('Erro ao enviar imagem pendente para o Storage: $err');
          }
        }

        // Remove a flag de controle interno do SQLite antes de enviar à nuvem
        mapaAjustado.remove('sincronizado');

        // Executa o Upsert na tabela do Supabase utilizando a estrutura de mapa
        await _supabase.from('insumos').upsert(mapaAjustado);

        // Marca o registro como sincronizado com sucesso no celular
        await _dbLocal.marcarComoSincronizado(json['id'] as String);
      }
    } catch (e) {
      print('Sincronização em background aguardando conexão estável: $e');
    }
  }

  @override
  Future<List<Insumo>> listarInsumos() async {
    // Roda a sincronização de dados e mídias pendentes antes de listar
    await _sincronizarPendentes();

    try {
      final resposta = await _supabase.from('insumos').select();
      final insumosNuvem = (resposta as List).map((json) => Insumo.fromMap(json)).toList();

      for (var insumo in insumosNuvem) {
        await _dbLocal.salvarLocal(insumo, estaSincronizado: true);
      }
    } catch (e) {
      print('Modo Offline: Usando apenas dados locais do SQLite.');
    }

    return await _dbLocal.listarLocal();
  }

  @override
  Future<void> adicionarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName}) async {
    final String novoId = insumo.id ?? _uuid.v4();
    String? urlDefinitiva = insumo.imagemUrl;

    if (imageBytes != null && imageName != null) {
      try {
        final pathNoBucket = 'public/$imageName';
        await _supabase.storage.from('insumos').uploadBinary(pathNoBucket, imageBytes);
        urlDefinitiva = _supabase.storage.from('insumos').getPublicUrl(pathNoBucket);
      } catch (e) {
        print('Offline ao adicionar: Mantendo o path local para processamento posterior.');
      }
    }

    final insumoComId = Insumo(
      id: novoId,
      nome: insumo.nome,
      descricao: insumo.descricao,
      estoqueMinimo: insumo.estoqueMinimo,
      categoria: insumo.categoria,
      unidadeMedida: insumo.unidadeMedida,
      imagemUrl: urlDefinitiva,
    );

    await _dbLocal.salvarLocal(insumoComId, estaSincronizado: false);

    try {
      await _supabase.from('insumos').insert(insumoComId.toMap());
      await _dbLocal.marcarComoSincronizado(novoId);
    } catch (e) {
      print('Registro guardado localmente no SQLite.');
    }
  }

  @override
  Future<void> atualizarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName}) async {
    String? urlDefinitiva = insumo.imagemUrl;

    if (imageBytes != null && imageName != null) {
      try {
        final pathNoBucket = 'public/$imageName';
        await _supabase.storage.from('insumos').uploadBinary(pathNoBucket, imageBytes);
        urlDefinitiva = _supabase.storage.from('insumos').getPublicUrl(pathNoBucket);
      } catch (e) {
        print('Offline ao atualizar: Mantendo a referência local.');
      }
    }

    final insumoAtualizado = Insumo(
      id: insumo.id,
      nome: insumo.nome,
      descricao: insumo.descricao,
      estoqueMinimo: insumo.estoqueMinimo,
      categoria: insumo.categoria,
      unidadeMedida: insumo.unidadeMedida,
      imagemUrl: urlDefinitiva,
    );

    await _dbLocal.salvarLocal(insumoAtualizado, estaSincronizado: false);

    try {
      await _supabase.from('insumos').update(insumoAtualizado.toMap()).eq('id', insumo.id!);
      await _dbLocal.marcarComoSincronizado(insumo.id!);
    } catch (e) {
      print('Edição guardada localmente no SQLite.');
    }
  }

  @override
  Future<void> deletarInsumo(String id) async {
    await _dbLocal.deletarLocal(id);
    try {
      await _supabase.from('insumos').delete().eq('id', id);
    } catch (e) {
      print('Exclusão pendente na nuvem.');
    }
  }
}