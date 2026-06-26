class Insumo {
  final String? id;
  final String nome;
  final String? descricao;
  final int? estoqueMinimo;
  final String? categoria;
  final String? unidadeMedida;
  final String? imagemUrl; // URL da imagem no Supabase Storage

  Insumo({
    this.id,
    required this.nome,
    this.descricao,
    this.estoqueMinimo,
    this.categoria,
    this.unidadeMedida,
    this.imagemUrl,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'descricao': descricao,
      'estoque_minimo': estoqueMinimo,
      'categoria': categoria,
      'unidade_medida': unidadeMedida,
      'imagem_url': imagemUrl,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      estoqueMinimo: map['estoque_minimo'] is int ? map['estoque_minimo'] : int.tryParse(map['estoque_minimo']?.toString() ?? '0'),
      categoria: map['categoria'],
      unidadeMedida: map['unidade_medida'],
      imagemUrl: map['imagem_url'],
    );
  }
}