import 'dart:convert'; // <-- Necessário para o base64Encode
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

  // A sincronização agora é trivial, pois a imagem Base64 já está no JSON!
  Future<void> _sincronizarPendentes() async {
    try {
      final pendentes = await _dbLocal.listarPendentes();
      for (var json in pendentes) {
        final mapaAjustado = Map<String, dynamic>.from(json);
        mapaAjustado.remove('sincronizado');

        // Envia o JSON (incluindo o texto Base64 gigante) direto para a tabela
        await _supabase.from('insumos').upsert(mapaAjustado);
        await _dbLocal.marcarComoSincronizado(json['id'] as String);
      }
    } catch (e) {
      print('Sincronização em background falhou: $e');
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
      print('Modo Offline: Usando apenas dados locais do SQLite.');
    }

    return await _dbLocal.listarLocal();
  }

  @override
  Future<void> adicionarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName}) async {
    final String novoId = insumo.id ?? _uuid.v4();
    String? urlBase64 = insumo.imagemUrl;

    // CONVERSÃO MÁGICA: Transforma a foto num texto
    if (imageBytes != null) {
      urlBase64 = base64Encode(imageBytes);
    }

    final insumoComId = Insumo(
      id: novoId,
      nome: insumo.nome,
      estoqueMinimo: insumo.estoqueMinimo,
      categoria: insumo.categoria,
      unidadeMedida: insumo.unidadeMedida,
      imagemUrl: urlBase64, // Agora guarda a string Base64
    );

    await _dbLocal.salvarLocal(insumoComId, estaSincronizado: false);

    try {
      await _supabase.from('insumos').insert(insumoComId.toMap());
      await _dbLocal.marcarComoSincronizado(novoId);
    } catch (e) {
      print('Registro guardado localmente no SQLite. Erro nuvem: $e');
    }
  }

  @override
  Future<void> atualizarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName}) async {
    String? urlBase64 = insumo.imagemUrl;

    // CONVERSÃO MÁGICA: Atualiza a foto para o novo texto Base64
    if (imageBytes != null) {
      urlBase64 = base64Encode(imageBytes);
    }

    final insumoAtualizado = Insumo(
      id: insumo.id,
      nome: insumo.nome,
      estoqueMinimo: insumo.estoqueMinimo,
      categoria: insumo.categoria,
      unidadeMedida: insumo.unidadeMedida,
      imagemUrl: urlBase64,
    );

    await _dbLocal.salvarLocal(insumoAtualizado, estaSincronizado: false);

    try {
      await _supabase.from('insumos').update(insumoAtualizado.toMap()).eq('id', insumo.id!);
      await _dbLocal.marcarComoSincronizado(insumo.id!);
    } catch (e) {
      print('Edição guardada localmente no SQLite. Erro nuvem: $e');
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