import 'package:flutter/material.dart';
import '../models/fornecedor.dart';
import '../services/fornecedor_service.dart';

class FornecedorViewModel extends ChangeNotifier {
  final FornecedorService _service;

  // O construtor recebe a interface do serviço (Inversão de Dependência)
  FornecedorViewModel(this._service);

  // Estado da nossa tela
  List<Fornecedor> _fornecedores = [];
  String _termoBusca = '';
  List<Fornecedor> get fornecedores {
    if (_termoBusca.isEmpty) {
      return _fornecedores;
    }
    return _fornecedores.where((fornecedor) {
      // Deixa tudo em minúsculo para a busca ignorar letras maiúsculas/minúsculas
      return fornecedor.nome.toLowerCase().contains(_termoBusca.toLowerCase());
    }).toList();
  }

  void pesquisar(String termo) {
    _termoBusca = termo;
    notifyListeners(); // Avisa a tela para se redesenhar com a lista filtrada
  }

  bool _estaCarregando = false;
  bool get estaCarregando => _estaCarregando;

  String? _erro;
  String? get erro => _erro;

  // Busca os dados e avisa a tela para se desenhar novamente
  Future<void> carregarFornecedores() async {
    _estaCarregando = true;
    _erro = null;
    notifyListeners();

    try {
      _fornecedores = await _service.listarFornecedores();
    } catch (e) {
      _erro = 'Erro ao buscar fornecedores: $e';
    } finally {
      _estaCarregando = false;
      notifyListeners();
    }
  }

  // Serve tanto para adicionar quanto para editar
  Future<bool> salvarFornecedor(Fornecedor fornecedor) async {
    _estaCarregando = true;
    notifyListeners();

    try {
      if (fornecedor.id == null) {
        await _service.adicionarFornecedor(fornecedor);
      } else {
        await _service.atualizarFornecedor(fornecedor);
      }

      // Após salvar, recarrega a lista automaticamente para a tela atualizar
      await carregarFornecedores();
      return true;
    } catch (e) {
      _erro = 'Erro ao salvar o fornecedor: $e';
      _estaCarregando = false;
      notifyListeners();
      return false;
    }
  }
  // Adicione junto com os outros métodos da classe
  Future<bool> deletarFornecedor(String id) async {
    try {
      // Chama o serviço para deletar do SQLite e do Supabase
      await _service.deletarFornecedor(id);

      // Atualiza a tela para o card sumir imediatamente
      await carregarFornecedores();
      return true;
    } catch (e) {
      _erro = 'Erro ao excluir: $e';
      notifyListeners();
      return false;
    }
  }

}
