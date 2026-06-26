import '../models/insumo.dart';

abstract class InsumosService {
  Future<List<Insumo>> listarInsumos();
  Future<void> adicionarInsumo(Insumo insumo);
  Future<void> atualizarInsumo(Insumo insumo);
  Future<void> deletarInsumo(String id);
}