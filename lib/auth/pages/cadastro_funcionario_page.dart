import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mvvm/auth_view_model.dart';
import '../../funcionarios/models/funcionario.dart'; // O seu Model renomeado!

class CadastroFuncionarioPage extends StatefulWidget {
  const CadastroFuncionarioPage({super.key});

  @override
  State<CadastroFuncionarioPage> createState() =>
      _CadastroFuncionarioPageState();
}

class _CadastroFuncionarioPageState extends State<CadastroFuncionarioPage> {
  // Chave global para identificar e validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  final TextEditingController _foneController = TextEditingController();

  // Variável para guardar o tipo de usuário selecionado no Dropdown (lista suspensa)
  String _tipoUsuarioSelecionado = 'Assistente';
  final List<String> _tiposUsuario = [
    'Gerente',
    'Dentista',
    'Assistente',
    'Almoxarife',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cpfController.dispose();
    _cargoController.dispose();
    _foneController.dispose();
    super.dispose();
  }

  // Adicionámos o 'async' aqui
  void _tentarSalvar() async {
    if (_formKey.currentState!.validate()) {
      final novoFuncionario = Funcionario(
        nome: _nomeController.text,
        email: _emailController.text,
        cpf: _cpfController.text,
        cargo: _cargoController.text,
        tipoUsuario: _tipoUsuarioSelecionado,
        fone: _foneController.text,
      );

      final senha = _senhaController.text;
      final authViewModel = context.read<AuthViewModel>();

      // Oculta o teclado do telemóvel para a animação ficar mais fluida
      FocusScope.of(context).unfocus();

      // Aguarda (await) que o ViewModel vá à internet e volte com a resposta
      final sucesso = await authViewModel.cadastrarFuncionario(
        novoFuncionario,
        senha,
      );

      // Regra de segurança do Flutter: verificar se o ecrã ainda existe antes de navegar
      if (!mounted) return;

      if (sucesso) {
        // Mostra a mensagem de sucesso verde
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Remove o ecrã de registo e volta para o ecrã de Login
        Navigator.pop(context);
      } else {
        // Mostra a mensagem de erro vermelha
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao registar. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o estado para saber se está carregando (mostra a bolinha no botão se precisar)
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Novo Cadastro'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Preencha seus dados',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 16),

              // Campo E-mail
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Informe um e-mail válido'
                    : null,
              ),
              const SizedBox(height: 16),

              // Campo Senha
              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Crie uma Senha',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'A senha deve ter no mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),

              // Dropdown Tipo de Usuário
              DropdownButtonFormField<String>(
                value: _tipoUsuarioSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Acesso',
                  border: OutlineInputBorder(),
                ),
                items: _tiposUsuario.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? novoValor) {
                  setState(() {
                    _tipoUsuarioSelecionado = novoValor!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Campo Cargo
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(
                  labelText: 'Cargo (Ex: Auxiliar)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo CPF
              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CPF (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Telefone
              TextFormField(
                controller: _foneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Botão Salvar
              ElevatedButton(
                onPressed: authViewModel.estaCarregando ? null : _tentarSalvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                ),
                child: authViewModel.estaCarregando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Finalizar Cadastro',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
