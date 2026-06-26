import 'package:flutter/material.dart';
import '../models/insumo.dart';
import '../services/insumos_service.dart';

class InsumosViewModel extends ChangeNotifier {
  final InsumosService _service;

  InsumosViewModel(this._service);

  List<Insumo> _insumos = [];
  List<Insumo> get insumos => _insumos;

  // Variável para a busca que implementaremos depois
  String _termoBusca = '';

  bool _estaCarregando = false;
  bool get estaCarregando => _estaCarregando;

  String? _erro;
  String? get erro => _erro;

  // Getter da lista filtrada (padrão que adotamos para a busca)
  List<Insumo> get insumosFiltrados {
    if (_termoBusca.isEmpty) return _insumos;
    return _insumos.where((i) => i.nome.toLowerCase().contains(_termoBusca.toLowerCase())).toList();
  }

  Future<void> carregarInsumos() async {
    _estaCarregando = true;
    _erro = null;
    notifyListeners();

    try {
      _insumos = await _service.listarInsumos();
    } catch (e) {
      _erro = 'Erro ao buscar insumos: $e';
    } finally {
      _estaCarregando = false;
      notifyListeners();
    }
  }

  Future<bool> salvarInsumo(Insumo insumo) async {
    _estaCarregando = true;
    notifyListeners();

    try {
      if (insumo.id == null) {
        await _service.adicionarInsumo(insumo);
      } else {
        await _service.atualizarInsumo(insumo);
      }
      await carregarInsumos();
      return true;
    } catch (e) {
      _erro = 'Erro ao salvar: $e';
      _estaCarregando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deletarInsumo(String id) async {
    try {
      await _service.deletarInsumo(id);
      await carregarInsumos();
    } catch (e) {
      _erro = 'Erro ao excluir: $e';
      notifyListeners();
    }
  }

  void pesquisar(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }
}