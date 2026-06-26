class Insumo {
  String? id;
  String nome;
  String? descricao;
  int? estoqueMinimo;
  String? categoria;
  String? unidadeMedida;
  String? imagemUrl; // URL da imagem armazenada no Supabase Storage

  Insumo({
    this.id,
    required this.nome,
    this.descricao,
    this.estoqueMinimo,
    this.categoria,
    this.unidadeMedida,
    this.imagemUrl,
  });

  // Transforma o objeto em um Map para inserir no SQLite e Supabase
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'descricao': descricao,
      'estoque_minimo': estoqueMinimo,
      'categoria': categoria,
      'unidade_medida': unidadeMedida,
      'imagem_url': imagemUrl,
    };

    // Adiciona o ID apenas se ele já existir (evita problemas na criação)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Constrói o objeto Insumo a partir de um Map vindo do banco (Local ou Nuvem)
  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      // Tratamento seguro: garante que não vai quebrar se o banco devolver String em vez de Int
      estoqueMinimo: map['estoque_minimo'] is int
          ? map['estoque_minimo']
          : int.tryParse(map['estoque_minimo']?.toString() ?? '0'),
      categoria: map['categoria'],
      unidadeMedida: map['unidade_medida'],
      imagemUrl: map['imagem_url'],
    );
  }
}