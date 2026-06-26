import '../models/fornecedor.dart';

abstract class FornecedorService {
  Future<List<Fornecedor>> listarFornecedores();
  Future<void> adicionarFornecedor(Fornecedor fornecedor);
  Future<void> atualizarFornecedor(Fornecedor fornecedor);
  Future<void> deletarFornecedor(String id);
}
