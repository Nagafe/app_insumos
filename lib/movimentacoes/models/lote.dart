import 'dart:convert';

class Lote {
  String? id;
  String insumoId;
  String numeroLote;
  DateTime dataValidade;
  int quantidadeLote;

  Lote({
    this.id,
    required this.insumoId,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidadeLote,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'insumo_id': insumoId,
      'numero_lote': numeroLote,
      'data_validade': dataValidade.toIso8601String().split('T')[0], // Guarda apenas YYYY-MM-DD
      'quantidade_lote': quantidadeLote,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Lote.fromMap(Map<String, dynamic> map) {
    return Lote(
      id: map['id']?.toString(),
      insumoId: map['insumo_id'] ?? '',
      numeroLote: map['numero_lote'] ?? '',
      dataValidade: map['data_validade'] != null
          ? DateTime.parse(map['data_validade'].toString())
          : DateTime.now(),
      quantidadeLote: map['quantidade_lote'] is int
          ? map['quantidade_lote']
          : int.tryParse(map['quantidade_lote']?.toString() ?? '0') ?? 0,
    );
  }
}