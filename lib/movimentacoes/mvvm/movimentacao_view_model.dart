import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/movimentacao.dart';
import '../services/movimentacoes_service.dart';
import '../../insumos/models/insumo.dart';

class MovimentacaoViewModel extends ChangeNotifier {
  final MovimentacoesService _service;

  MovimentacaoViewModel(this._service);

  bool _isEntrada = true;
  bool get isEntrada => _isEntrada;

  bool _estaCarregando = false;
  bool get estaCarregando => _estaCarregando;

  String? _erro;
  String? get erro => _erro;

  List<Lote> _lotesDisponiveis = [];
  List<Lote> get lotesDisponiveis => _lotesDisponiveis;

  void alternarTipoMovimentacao(bool ehEntrada) {
    _isEntrada = ehEntrada;
    _lotesDisponiveis = [];
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
    String? fornecedorId,
    Lote? loteExistente,
    String? novoNumeroLote,
    DateTime? novaDataValidade,
    double valorTotalCompra = 0.0,
    String? motivo,
    required String funcionarioId,
  }) async {
    _estaCarregando = true;
    _erro = null;
    notifyListeners();

    try {
      Lote loteAlvo;
      double custoUnitarioCalculado = 0.0;

      if (_isEntrada) {
        if (novoNumeroLote == null || novaDataValidade == null) {
          throw Exception("Dados do lote são obrigatórios para entrada.");
        }
        if (quantidade <= 0) throw Exception("Quantidade deve ser maior que zero.");

        // Na Entrada: Calcula o valor da unidade pela nota fiscal
        custoUnitarioCalculado = valorTotalCompra / quantidade;

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
        loteAlvo.quantidadeLote -= quantidade;

        // MICRO-CORREÇÃO: Na Saída, registra o custo financeiro do insumo no momento exato do consumo
        custoUnitarioCalculado = insumoSelecionado.custoMedio;
      }

      final mov = Movimentacao(
        funcionarioId: funcionarioId,
        fornecedorId: _isEntrada ? fornecedorId : null,
        loteId: loteAlvo.id ?? '',
        tipo: _isEntrada ? 'ENTRADA' : 'SAIDA',
        quantidade: quantidade,
        // Agora o custo unitário está sempre preenchido, seja compra ou consumo
        custoUnitario: custoUnitarioCalculado,
        motivo: !_isEntrada ? motivo : null,
        dataMovimentacao: DateTime.now(),
      );

      await _service.registrarMovimentacao(
        movimentacao: mov,
        lote: loteAlvo,
        insumo: insumoSelecionado,
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