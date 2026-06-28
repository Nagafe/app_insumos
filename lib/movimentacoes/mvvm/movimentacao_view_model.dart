import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/movimentacao.dart';
import '../services/movimentacoes_service.dart';
import '../../insumos/models/insumo.dart';

class MovimentacaoViewModel extends ChangeNotifier {
  final MovimentacoesService _service;

  MovimentacaoViewModel(this._service);

  // Controle de Estado da Interface (Tela Única)
  bool _isEntrada = true;
  bool get isEntrada => _isEntrada;

  bool _estaCarregando = false;
  bool get estaCarregando => _estaCarregando;

  String? _erro;
  String? get erro => _erro;

  // Lotes carregados dinamicamente ao selecionar um insumo (Para Saídas)
  List<Lote> _lotesDisponiveis = [];
  List<Lote> get lotesDisponiveis => _lotesDisponiveis;

  void alternarTipoMovimentacao(bool ehEntrada) {
    _isEntrada = ehEntrada;
    _lotesDisponiveis = []; // Limpa os lotes ao alternar
    notifyListeners();
  }

  Future<void> buscarLotesDoInsumo(String insumoId) async {
    _estaCarregando = true;
    notifyListeners();

    try {
      _lotesDisponiveis = await _service.listarLotesPorInsumo(insumoId);
    } catch (e) {
      _erro = 'Erro ao buscar lotes: $e';
    } finally {
      _estaCarregando = false;
      notifyListeners();
    }
  }

  Future<bool> processarMovimentacao({
    required Insumo insumoSelecionado,
    required int quantidade,
    String? fornecedorId, // Nulo se for saída
    Lote? loteExistente, // Usado na saída
    String? novoNumeroLote, // Usado na entrada
    DateTime? novaDataValidade, // Usado na entrada
    double custoUnitario = 0.0,
    String? motivo,
    required String funcionarioId, // ID do utilizador logado
  }) async {
    _estaCarregando = true;
    _erro = null;
    notifyListeners();

    try {
      Lote loteAlvo;

      if (_isEntrada) {
        if (novoNumeroLote == null || novaDataValidade == null) {
          throw Exception("Dados do lote são obrigatórios para entrada.");
        }
        loteAlvo = Lote(
          insumoId: insumoSelecionado.id!,
          numeroLote: novoNumeroLote,
          dataValidade: novaDataValidade,
          quantidadeLote: quantidade,
        );
      } else {
        if (loteExistente == null) {
          throw Exception("É obrigatório selecionar um lote para realizar a saída.");
        }
        if (loteExistente.quantidadeLote < quantidade) {
          throw Exception("Quantidade em lote insuficiente.");
        }
        loteAlvo = loteExistente;
        loteAlvo.quantidadeLote -= quantidade; // Deduz do lote na memória antes de salvar
      }

      final mov = Movimentacao(
        insumoId: insumoSelecionado.id!,
        funcionarioId: funcionarioId,
        fornecedorId: _isEntrada ? fornecedorId : null,
        loteId: loteAlvo.id ?? '', // Será gerado no service se for entrada
        tipo: _isEntrada ? 'Entrada' : 'Saída',
        quantidade: quantidade,
        custoUnitario: _isEntrada ? custoUnitario : 0.0,
        motivo: !_isEntrada ? motivo : null,
        dataMovimentacao: DateTime.now(),
      );

      await _service.registrarMovimentacao(
        movimentacao: mov,
        lote: loteAlvo,
        isNovaEntrada: _isEntrada,
      );

      return true;
    } catch (e) {
      _erro = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _estaCarregando = false;
      notifyListeners();
    }
  }
}