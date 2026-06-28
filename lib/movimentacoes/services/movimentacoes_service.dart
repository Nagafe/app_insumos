import '../models/lote.dart';
import '../models/movimentacao.dart';

abstract class MovimentacoesService {
  /// Lista os lotes disponíveis para um insumo específico (útil para Saídas)
  Future<List<Lote>> listarLotesPorInsumo(String insumoId);

  /// Regista a movimentação e atualiza os saldos de forma atómica
  Future<void> registrarMovimentacao({
    required Movimentacao movimentacao,
    required Lote lote,
    required bool isNovaEntrada,
  });
}