class Funcionario {
  final String? id; // Pode ser nulo antes de ser inserido na base de dados
  final String nome;
  final String? cpf;
  final String email;
  final String? cargo;
  final String tipoUsuario; // Ex: 'Gerente', 'Dentista', 'Assistente'
  final String? fone;
  final bool ativo;
  final DateTime? dataCriacao;

  // Construtor
  Funcionario({
    this.id,
    required this.nome,
    this.cpf,
    required this.email,
    this.cargo,
    required this.tipoUsuario,
    this.fone,
    this.ativo = false, // Por padrão, o funcionário é criado como inativo
    this.dataCriacao,
  });

  // Transforma o objeto Dart num formato (Map) que o Supabase e SQLite entendem
  Map<String, dynamic> toMap() {
    return {
      // Não enviamos o 'id' e 'data_criacao' no toMap para criação,
      // pois a base de dados (Supabase) gera o UUID e o Timestamp automaticamente.
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'cargo': cargo,
      'tipo_usuario': tipoUsuario,
      'fone': fone,
      'ativo': ativo,
    };
  }

  // Cria um objeto Funcionario a partir dos dados vindos da base de dados
  factory Funcionario.fromMap(Map<String, dynamic> map) {
    return Funcionario(
      id: map['id'] as String?,
      nome: map['nome'] ?? '',
      cpf: map['cpf'],
      email: map['email'] ?? '',
      cargo: map['cargo'],
      tipoUsuario: map['tipo_usuario'] ?? 'Funcionário',
      fone: map['fone'],
      ativo: map['ativo'] ?? true,
      dataCriacao: map['data_criacao'] != null
          ? DateTime.parse(map['data_criacao'])
          : null,
    );
  }
}
