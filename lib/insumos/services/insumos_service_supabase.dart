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
  Future<void> adicionarInsumo(Insumo insumo) async {
    await _supabase.from('insumos').insert(insumo.toMap());
  }

  @override
  Future<void> atualizarInsumo(Insumo insumo) async {
    if (insumo.id == null) throw Exception('ID necessário para atualizar.');

    await _supabase
        .from('insumos')
        .update(insumo.toMap())
        .eq('id', insumo.id!);
  }

  @override
  Future<void> deletarInsumo(String id) async {
    await _supabase.from('insumos').delete().eq('id', id);
  }
}