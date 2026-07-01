import '../models/lote.dart';
import '../models/movimentacao.dart';
import '../../insumos/models/insumo.dart'; // <-- Adicionado

abstract class MovimentacoesService {
  Future<List<Lote>> listarLotesPorInsumo(String insumoId);

  Future<void> registrarMovimentacao({
    required Movimentacao movimentacao,
    required Lote lote,
    required Insumo insumo, // <-- Necessário para os cálculos matemáticos locais
    required bool isNovaEntrada,
  });
}