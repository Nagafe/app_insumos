class Fornecedor {
  final String? id;
  final String nome; // Atualizado para bater com o SQL
  final String? cnpj;
  final String? fone; // Atualizado para bater com o SQL
  final String? email;
  final String? endereco; // Novo campo adicionado!
  final bool ativo;
  final DateTime? dataCriacao; // Novo campo adicionado!

  Fornecedor({
    this.id,
    required this.nome,
    this.cnpj,
    this.fone,
    this.email,
    this.endereco,
    this.ativo = true,
    this.dataCriacao,
  });

  // Transforma o objeto Dart num formato (Map) para enviar ao Supabase
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'cnpj': cnpj,
      'fone': fone,
      'email': email,
      'endereco': endereco,
      'ativo': ativo,
    };

    // Só envia o ID se ele não for nulo (vital para a sincronização offline funcionar)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Cria o objeto Funcionario a partir dos dados vindos do Supabase
  factory Fornecedor.fromMap(Map<String, dynamic> map) {
    return Fornecedor(
      id: map['id'] as String?,
      nome: map['nome'] ?? 'Sem nome',
      cnpj: map['cnpj'],
      fone: map['fone'],
      email: map['email'],
      endereco: map['endereco'],
      ativo: map['ativo'] ?? true,
      dataCriacao: map['data_criacao'] != null
          ? DateTime.parse(map['data_criacao'])
          : null,
    );
  }
}
