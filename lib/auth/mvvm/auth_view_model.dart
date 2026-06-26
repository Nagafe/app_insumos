import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../funcionarios/models/funcionario.dart';

class AuthViewModel extends ChangeNotifier {
  bool _estaCarregando = false;

  bool get estaCarregando => _estaCarregando;

  // Realizar login do funcionário, verificando se ele está ativo no sistema
  Future<String?> fazerLogin(String email, String senha) async {
    if (email.isEmpty || senha.isEmpty) {
      return 'Preencha o e-mail e a senha.';
    }

    _estaCarregando = true;
    notifyListeners();

    try {
      // ETAPA 1: Tenta autenticar no cofre do Supabase
      final respostaAuth = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: senha);

      final utilizador = respostaAuth.user;

      if (utilizador != null) {
        // ETAPA 2: Verifica na tabela pública se o funcionário está ativo
        final dadosFuncionario = await Supabase.instance.client
            .from('funcionarios')
            .select('ativo')
            .eq('id', utilizador.id)
            .single(); // Pega apenas a linha deste utilizador

        final bool estaAtivo = dadosFuncionario['ativo'] ?? false;

        if (!estaAtivo) {
          // Segurança: Se não estiver ativo, removemos a sessão dele imediatamente
          await Supabase.instance.client.auth.signOut();
          _estaCarregando = false;
          notifyListeners();

          // Retorna o aviso exato que pediu
          return 'Aguarde o administrador ativar o seu cadastro.';
        }

        // Se chegou aqui, está com a senha certa e está ativo!
        _estaCarregando = false;
        notifyListeners();
        return null; // O 'null' avisa a tela que não houve nenhum erro
      }

      return 'Erro desconhecido ao tentar entrar.';
    } on AuthException catch (_) {
      // Erro específico do Supabase para credenciais inválidas
      _estaCarregando = false;
      notifyListeners();
      return 'E-mail ou senha incorretos.';
    } catch (e) {
      // Falha de internet ou banco de dados
      _estaCarregando = false;
      notifyListeners();
      return 'Erro de conexão. Tente novamente mais tarde.';
    }
  }

  //Método para registar um novo funcionário

  Future<bool> cadastrarFuncionario(
    Funcionario funcionario,
    String senha,
  ) async {
    _estaCarregando = true;
    notifyListeners();

    try {
      final respostaAuth = await Supabase.instance.client.auth.signUp(
        email: funcionario.email,
        password: senha,
      );

      final utilizador = respostaAuth.user;

      if (utilizador != null) {
        final dadosParaGravar = funcionario.toMap();
        dadosParaGravar['id'] = utilizador.id;

        await Supabase.instance.client
            .from('funcionarios')
            .insert(dadosParaGravar);

        print('✅ Registo concluído com sucesso na nuvem!');

        _estaCarregando = false;
        notifyListeners();
        return true; // <-- AVISAR A VIEW QUE DEU CERTO
      }

      _estaCarregando = false;
      notifyListeners();
      return false; // <-- AVISAR A VIEW QUE FALHOU
    } catch (e) {
      print('❌ Erro inesperado: $e');
      _estaCarregando = false;
      notifyListeners();
      return false; // <-- AVISAR A VIEW QUE FALHOU
    }
  }
}
