import 'dart:typed_data';
import '../models/insumo.dart';

abstract class InsumosService {
  Future<List<Insumo>> listarInsumos();
  Future<void> adicionarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName});
  Future<void> atualizarInsumo(Insumo insumo, {Uint8List? imageBytes, String? imageName});
  Future<void> deletarInsumo(String id);
}