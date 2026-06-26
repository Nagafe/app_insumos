import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fornecedor.dart';
import 'fornecedor_service.dart';

class FornecedorServiceSupabase implements FornecedorService {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Fornecedor>> listarFornecedores() async {
    // Busca todos os fornecedores, ordenando pelo nome em ordem alfabética
    final resposta = await _supabase
        .from('fornecedores')
        .select()
        .order('nome', ascending: true);

    // Converte a lista de Maps (JSON) que veio do banco para uma lista de objetos Fornecedor
    return resposta.map((json) => Fornecedor.fromMap(json)).toList();
  }

  @override
  Future<void> adicionarFornecedor(Fornecedor fornecedor) async {
    await _supabase.from('fornecedores').insert(fornecedor.toMap());
  }

  @override
  Future<void> atualizarFornecedor(Fornecedor fornecedor) async {
    if (fornecedor.id == null) {
      throw Exception('ID não pode ser nulo para atualização.');
    }

    await _supabase
        .from('fornecedores')
        .update(fornecedor.toMap())
        .eq('id', fornecedor.id!);
  }

  @override
  Future<void> deletarFornecedor(String id) async {
    await _supabase
        .from('fornecedores')
        .delete()
        .eq('id', id);
  }

}
