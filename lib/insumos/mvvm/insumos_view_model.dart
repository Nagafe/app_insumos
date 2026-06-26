import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/insumo.dart';
import '../services/insumos_service.dart';

class InsumosViewModel extends ChangeNotifier {
  final InsumosService _service;

  InsumosViewModel(this._service);

  List<Insumo> _insumos = [];
  List<Insumo> get insumos => _insumos;

  bool _estaCarregando = false;
  bool get estaCarregando => _estaCarregando;

  String? _erro;
  String? get erro => _erro;

  String _termoBusca = '';

  List<Insumo> get insumosFiltrados {
    if (_termoBusca.isEmpty) return _insumos;
    return _insumos
        .where((insumo) => insumo.nome.toLowerCase().contains(_termoBusca.toLowerCase()))
        .toList();
  }

  Future<void> carregarInsumos() async {
    _estaCarregando = true;
    _erro = null;
    notifyListeners();

    try {
      _insumos = await _service.listarInsumos();
    } catch (e) {
      _erro = 'Erro ao carregar insumos: $e';
    } finally {
      _estaCarregando = false;
      notifyListeners();
    }
  }

  Future<bool> salvarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName}) async {
    _estaCarregando = true;
    _erro = null;
    notifyListeners();

    try {
      if (insumo.id == null) {
        await _service.adicionarInsumo(insumo, imageBytes: imageBytes, imageName: imageName);
      } else {
        await _service.atualizarInsumo(insumo, imageBytes: imageBytes, imageName: imageName);
      }
      await carregarInsumos();
      return true;
    } catch (e) {
      _erro = 'Erro ao salvar insumo: $e';
      _estaCarregando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletarInsumo(String id) async {
    try {
      await _service.deletarInsumo(id);
      await carregarInsumos();
      return true;
    } catch (e) {
      _erro = 'Erro ao deletar insumo: $e';
      notifyListeners();
      return false;
    }
  }

  void pesquisar(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }
}