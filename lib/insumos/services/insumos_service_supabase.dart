import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insumo.dart';
import 'insumos_service.dart';

class InsumosServiceSupabase implements InsumosService {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Insumo>> listarInsumos() async {
    final resposta = await _supabase
        .from('insumos')
        .select()
        .order('nome', ascending: true);

    return (resposta as List).map((json) => Insumo.fromMap(json)).toList();
  }

  @override
  Future<void> adicionarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName}) async {
    String? urlDefinitiva = insumo.imagemUrl;

    // Se houver imagem, realiza o upload direto para o bucket do Storage
    if (imageBytes != null && imageName != null) {
      try {
        final pathNoBucket = 'public/$imageName';
        await _supabase.storage.from('insumos').uploadBinary(pathNoBucket, imageBytes);
        urlDefinitiva = _supabase.storage.from('insumos').getPublicUrl(pathNoBucket);
      } catch (e) {
        print('Falha ao enviar imagem para o Supabase Storage: $e');
      }
    }

    final insumoComUrl = Insumo(
      id: insumo.id,
      nome: insumo.nome,
      estoqueMinimo: insumo.estoqueMinimo,
      categoria: insumo.categoria,
      unidadeMedida: insumo.unidadeMedida,
      imagemUrl: urlDefinitiva, // URL pública da nuvem
    );

    await _supabase.from('insumos').insert(insumoComUrl.toMap());
  }

  @override
  Future<void> atualizarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName}) async {
    if (insumo.id == null) throw Exception('ID necessário para atualizar.');

    String? urlDefinitiva = insumo.imagemUrl;

    // Se uma nova imagem foi selecionada na edição, faz o upload e atualiza a URL
    if (imageBytes != null && imageName != null) {
      try {
        final pathNoBucket = 'public/$imageName';
        await _supabase.storage.from('insumos').uploadBinary(pathNoBucket, imageBytes);
        urlDefinitiva = _supabase.storage.from('insumos').getPublicUrl(pathNoBucket);
      } catch (e) {
        print('Falha ao atualizar imagem no Supabase Storage: $e');
      }
    }

    final insumoAtualizado = Insumo(
      id: insumo.id,
      nome: insumo.nome,
      estoqueMinimo: insumo.estoqueMinimo,
      categoria: insumo.categoria,
      unidadeMedida: insumo.unidadeMedida,
      imagemUrl: urlDefinitiva,
    );

    await _supabase
        .from('insumos')
        .update(insumoAtualizado.toMap())
        .eq('id', insumo.id!);
  }

  @override
  Future<void> deletarInsumo(String id) async {
    await _supabase.from('insumos').delete().eq('id', id);
  }
}