class Insumo {
  String? id;
  String nome;
  int? estoqueMinimo;
  String? categoria;
  String? unidadeMedida;
  String? imagemUrl; // URL da imagem armazenada no Supabase Storage
  int saldoGeral;
  double custoMedio;
  bool ativo;
  DateTime? dataCriacao;

  Insumo({
    this.id,
    required this.nome,
    this.estoqueMinimo,
    this.categoria,
    this.unidadeMedida,
    this.imagemUrl,
    this.saldoGeral = 0,
    this.custoMedio = 0.0,
    this.ativo = true,
    this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'estoque_minimo': estoqueMinimo,
      'categoria': categoria,
      'unidade_medida': unidadeMedida,
      'imagem_url': imagemUrl,
      'saldo_geral': saldoGeral,
      'custo_medio': custoMedio,
      'ativo': ativo,
    };

    if (id != null) {
      map['id'] = id;
    }

    if (dataCriacao != null) {
      map['data_criacao'] = dataCriacao!.toIso8601String();
    }

    return map;
  }

  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
      estoqueMinimo: map['estoque_minimo'] is int
          ? map['estoque_minimo']
          : int.tryParse(map['estoque_minimo']?.toString() ?? '0'),
      categoria: map['categoria'],
      unidadeMedida: map['unidade_medida'],
      imagemUrl: map['imagem_url'],
      saldoGeral: map['saldo_geral'] is int
          ? map['saldo_geral']
          : int.tryParse(map['saldo_geral']?.toString() ?? '0') ?? 0,
      custoMedio: map['custo_medio'] is num
          ? (map['custo_medio'] as num).toDouble()
          : double.tryParse(map['custo_medio']?.toString() ?? '0.0') ?? 0.0,
      ativo: map['ativo'] == 1 || map['ativo'] == true,
      dataCriacao: map['data_criacao'] != null
          ? DateTime.tryParse(map['data_criacao'].toString())
          : null,
    );
  }

  // --- A CORREÇÃO NECESSÁRIA ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Insumo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}