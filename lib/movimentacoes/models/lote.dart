class Lote {
  String? id;
  String insumoId;
  String numeroLote;
  DateTime dataValidade;
  int quantidadeLote;
  DateTime? dataCadastro; // Mapeia o auto_now_add=True do backend

  Lote({
    this.id,
    required this.insumoId,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidadeLote,
    this.dataCadastro,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'insumo_id': insumoId,
      'numero_lote': numeroLote,
      'data_validade': dataValidade.toIso8601String().split('T')[0], // Salva estritamente YYYY-MM-DD
      'quantidade_lote': quantidadeLote,
    };

    if (id != null) {
      map['id'] = id;
    }

    if (dataCadastro != null) {
      map['data_cadastro'] = dataCadastro!.toIso8601String();
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
      dataCadastro: map['data_cadastro'] != null
          ? DateTime.tryParse(map['data_cadastro'].toString())
          : null,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

}