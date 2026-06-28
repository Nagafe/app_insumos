class Movimentacao {
  String? id;
  String insumoId;
  String funcionarioId;
  String? fornecedorId;
  String loteId;
  String tipo; // 'Entrada' ou 'Saída'
  int quantidade;
  double custoUnitario;
  String? motivo;
  DateTime? dataMovimentacao;

  Movimentacao({
    this.id,
    required this.insumoId,
    required this.funcionarioId,
    this.fornecedorId,
    required this.loteId,
    required this.tipo,
    required this.quantidade,
    this.custoUnitario = 0.00,
    this.motivo,
    this.dataMovimentacao,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'insumo_id': insumoId,
      'funcionario_id': funcionarioId,
      'fornecedor_id': fornecedorId, // Fica nulo se for Saída
      'lote_id': loteId,
      'tipo': tipo,
      'quantidade': quantidade,
      'custo_unitario': custoUnitario,
      'motivo': motivo, // Opcional ou preenchido na Saída
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Movimentacao.fromMap(Map<String, dynamic> map) {
    return Movimentacao(
      id: map['id']?.toString(),
      insumoId: map['insumo_id'] ?? '',
      funcionarioId: map['funcionario_id'] ?? '',
      fornecedorId: map['fornecedor_id']?.toString(),
      loteId: map['lote_id'] ?? '',
      tipo: map['tipo'] ?? 'Entrada',
      quantidade: map['quantidade'] is int
          ? map['quantidade']
          : int.tryParse(map['quantidade']?.toString() ?? '0') ?? 0,
      custoUnitario: map['custo_unitario'] is num
          ? (map['custo_unitario'] as num).toDouble()
          : double.tryParse(map['custo_unitario']?.toString() ?? '0.0') ?? 0.0,
      motivo: map['motivo'],
      dataMovimentacao: map['data_movimentacao'] != null
          ? DateTime.parse(map['data_movimentacao'].toString())
          : null,
    );
  }
}