import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/funcionario.dart';

class PerfilDialog extends StatefulWidget {
  const PerfilDialog({super.key});

  @override
  State<PerfilDialog> createState() => _PerfilDialogState();
}

class _PerfilDialogState extends State<PerfilDialog> {
  bool _carregando = true;
  bool _salvando = false;
  Funcionario? _funcionario;

  final _formKey = GlobalKey<FormState>();

  // Controladores apenas para o que pode ser editado
  final _cargoController = TextEditingController();
  final _foneController = TextEditingController();

  // Variáveis para Dropdown
  String _tipoUsuarioSelecionado = 'Assistente';
  final List<String> _tiposUsuario = [
    'Gerente',
    'Dentista',
    'Assistente',
    'Almoxarife',
  ];

  @override
  void initState() {
    super.initState();
    _buscarDadosDoUsuario();
  }

  Future<void> _buscarDadosDoUsuario() async {
    try {
      // Pega o ID do cofre de autenticação
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Busca a linha completa na tabela funcionarios
      final dados = await Supabase.instance.client
          .from('funcionarios')
          .select()
          .eq('id', userId)
          .single();

      _funcionario = Funcionario.fromMap(dados);

      // Preenche os controladores com os dados que vieram do banco
      _cargoController.text = _funcionario!.cargo ?? '';
      _foneController.text = _funcionario!.fone ?? '';

      // Prevenção de erro caso o banco tenha um cargo que não está na lista
      if (_tiposUsuario.contains(_funcionario!.tipoUsuario)) {
        _tipoUsuarioSelecionado = _funcionario!.tipoUsuario;
      }

      setState(() {
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar perfil: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Atualiza apenas os campos permitidos no banco
      await Supabase.instance.client
          .from('funcionarios')
          .update({
            'cargo': _cargoController.text,
            'fone': _foneController.text,
            'tipo_usuario': _tipoUsuarioSelecionado,
          })
          .eq('id', userId);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Meus Dados'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- CAMPOS BLOQUEADOS (Somente Leitura) ---
              TextFormField(
                initialValue: _funcionario!.nome,
                enabled: false, // Bloqueia a edição
                decoration: const InputDecoration(
                  labelText: 'Nome Completo (Não editável)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _funcionario!.cpf ?? 'Não informado',
                enabled: false, // Bloqueia a edição
                decoration: const InputDecoration(
                  labelText: 'CPF (Não editável)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _funcionario!.email,
                enabled: false, // Bloqueia a edição do E-mail
                decoration: const InputDecoration(
                  labelText: 'E-mail (Não editável)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // --- CAMPOS EDITÁVEIS ---
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
                onChanged: (novoValor) {
                  setState(() {
                    _tipoUsuarioSelecionado = novoValor!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _foneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // STATUS
              Row(
                children: [
                  Icon(
                    _funcionario!.ativo ? Icons.check_circle : Icons.cancel,
                    color: _funcionario!.ativo ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _funcionario!.ativo ? 'Cadastro Ativo' : 'Cadastro Inativo',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvarAlteracoes,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: _salvando
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Salvar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cargoController.dispose();
    _foneController.dispose();
    super.dispose();
  }
}
