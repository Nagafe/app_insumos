import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/insumo.dart';
import 'insumos_service.dart';
import 'insumos_db_helper.dart';

class InsumosServiceHibrido implements InsumosService {
  final _supabase = Supabase.instance.client;
  final _dbLocal = InsumosDbHelper.instance;
  final _uuid = const Uuid();

  Future<void> _sincronizarPendentes() async {
    try {
      final pendentes = await _dbLocal.listarPendentes();
      for (var json in pendentes) {
        final mapaAjustado = Map<String, dynamic>.from(json);

        // Se houver campos que são booleanos (como 'ativo' no Fornecedor),
        // ajuste aqui. Para Insumos, se não tiver booleanos, basta remover a flag:
        mapaAjustado.remove('sincronizado');

        // Faz o Upsert no Supabase
        await _supabase.from('insumos').upsert(mapaAjustado);

        // Marca como sincronizado no SQLite local
        await _dbLocal.marcarComoSincronizado(json['id'] as String);
      }
    } catch (e) {
      print('Sincronização de insumos falhou: $e');
    }
  }

  @override
  Future<List<Insumo>> listarInsumos() async {
    await _sincronizarPendentes();
    try {
      final resposta = await _supabase.from('insumos').select();
      final insumosNuvem = (resposta as List).map((json) => Insumo.fromMap(json)).toList();

      for (var insumo in insumosNuvem) {
        await _dbLocal.salvarLocal(insumo, estaSincronizado: true);
      }
    } catch (e) {
      print('Modo Offline: Usando apenas dados locais.');
    }
    return await _dbLocal.listarLocal();
  }

  @override
  Future<void> adicionarInsumo(Insumo insumo) async {
    final String novoId = insumo.id ?? _uuid.v4();
    final insumoComId = Insumo(
      id: novoId,
      nome: insumo.nome,
      descricao: insumo.descricao,
      estoqueMinimo: insumo.estoqueMinimo,
      categoria: insumo.categoria,
      unidadeMedida: insumo.unidadeMedida,
      imagemUrl: insumo.imagemUrl,
    );

    // 1. Salva localmente como pendente
    await _dbLocal.salvarLocal(insumoComId, estaSincronizado: false);

    // 2. Tenta enviar para nuvem
    try {
      await _supabase.from('insumos').insert(insumoComId.toMap());
      await _dbLocal.marcarComoSincronizado(novoId);
    } catch (e) {
      print('Offline: Insumo pendente de sincronização.');
    }
  }

  @override
  Future<void> atualizarInsumo(Insumo insumo) async {
    await _dbLocal.salvarLocal(insumo, estaSincronizado: false);
    try {
      await _supabase.from('insumos').update(insumo.toMap()).eq('id', insumo.id!);
      await _dbLocal.marcarComoSincronizado(insumo.id!);
    } catch (e) {
      print('Offline: Edição pendente de sincronização.');
    }
  }

  @override
  Future<void> deletarInsumo(String id) async {
    await _dbLocal.deletarLocal(id);
    try {
      await _supabase.from('insumos').delete().eq('id', id);
    } catch (e) {
      print('Offline: Exclusão pendente.');
    }
  }
}