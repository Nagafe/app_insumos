import '../../insumos/models/insumo.dart';

class Movimentacao {
  String? id;
  String loteId;
  String funcionarioId;
  String? fornecedorId;
  String tipo; // Sempre 'ENTRADA' ou 'SAIDA'
  int quantidade;
  double custoUnitario;
  String? motivo;
  DateTime? dataMovimentacao;

  Movimentacao({
    this.id,
    required this.loteId,
    required this.funcionarioId,
    this.fornecedorId,
    required this.tipo,
    required this.quantidade,
    this.custoUnitario = 0.00,
    this.motivo,
    this.dataMovimentacao,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'lote_id': loteId,
      'funcionario_id': funcionarioId,
      'fornecedor_id': fornecedorId, // Fica nulo se for Saída
      'tipo': tipo.toUpperCase(),   // Garante a caixa alta exigida pelo banco
      'quantidade': quantidade,
      'custo_unitario': custoUnitario,
      'motivo': motivo,
    };

    if (id != null) {
      map['id'] = id;
    }

    if (dataMovimentacao != null) {
      map['data_movimentacao'] = dataMovimentacao!.toIso8601String();
    }

    return map;
  }

  factory Movimentacao.fromMap(Map<String, dynamic> map) {
    return Movimentacao(
      id: map['id']?.toString(),
      loteId: map['lote_id'] ?? '',
      funcionarioId: map['funcionario_id'] ?? '',
      fornecedorId: map['fornecedor_id']?.toString(),
      tipo: (map['tipo']?.toString() ?? 'ENTRADA').toUpperCase(),
      quantidade: map['quantidade'] is int
          ? map['quantidade']
          : int.tryParse(map['quantidade']?.toString() ?? '0') ?? 0,
      custoUnitario: map['custo_unitario'] is num
          ? (map['custo_unitario'] as num).toDouble()
          : double.tryParse(map['custo_unitario']?.toString() ?? '0.0') ?? 0.0,
      motivo: map['motivo'],
      dataMovimentacao: map['data_movimentacao'] != null
          ? DateTime.tryParse(map['data_movimentacao'].toString())
          : null,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Insumo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}