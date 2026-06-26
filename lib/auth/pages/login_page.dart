import 'package:app_insumos/auth/pages/cadastro_funcionario_page.dart';
import 'package:app_insumos/mainpage/main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Import do Provider

import '../mvvm/auth_view_model.dart'; // 2. Import do seu ViewModel

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _tentarLogin() async {
    // Esconde o teclado virtual do ecrã para uma transição mais limpa
    FocusScope.of(context).unfocus();

    final authViewModel = context.read<AuthViewModel>();

    // Chama o ViewModel e aguarda a resposta (nula = sucesso, texto = erro)
    final erro = await authViewModel.fazerLogin(
      _emailController.text.trim(),
      _senhaController.text,
    );

    if (!mounted) return;

    if (erro == null) {
      // SUCESSO E ATIVO! Vai para a página principal (que criaremos em seguida)
      // Usamos pushReplacement para que ele não possa "voltar" para a tela de login usando o botão de voltar do Android
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      // ERRO OU INATIVO! Mostra a barrinha vermelha com o aviso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. O 'watch' faz a tela ficar de olho no ViewModel. Se algo mudar, ela se redesenha.
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sistema de Gestão de Insumos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Acesso do Funcionário',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 4. O Botão agora é inteligente
              ElevatedButton(
                onPressed: authViewModel.estaCarregando
                    ? null // Desabilita o botão se já estiver carregando
                    : _tentarLogin, // Chama a função de login quando clicado
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // 5. Troca o texto pela bolinha de carregamento se necessário
                child: authViewModel.estaCarregando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CadastroFuncionarioPage(),
                    ),
                  );
                },
                child: const Text(
                  'Cadastrar novo funcionário',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
