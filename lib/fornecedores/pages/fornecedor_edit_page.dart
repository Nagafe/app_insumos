import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fornecedor.dart';
import '../mvvm/fornecedor_view_model.dart';

class FornecedorEditPage extends StatefulWidget {
  // A tela precisa receber o fornecedor que foi clicado na lista
  final Fornecedor fornecedor;

  const FornecedorEditPage({super.key, required this.fornecedor});

  @override
  State<FornecedorEditPage> createState() => _FornecedorEditPageState();
}

class _FornecedorEditPageState extends State<FornecedorEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _foneController;
  late final TextEditingController _emailController;
  late final TextEditingController _enderecoController;

  late bool _ativo;

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores já com os dados do fornecedor selecionado
    _nomeController = TextEditingController(text: widget.fornecedor.nome);
    _cnpjController = TextEditingController(text: widget.fornecedor.cnpj ?? '');
    _foneController = TextEditingController(text: widget.fornecedor.fone ?? '');
    _emailController = TextEditingController(
      text: widget.fornecedor.email ?? '',
    );
    _enderecoController = TextEditingController(
      text: widget.fornecedor.endereco ?? '',
    );
    _ativo = widget.fornecedor.ativo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _foneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    // Monta o objeto mantendo o ID original para que o ViewModel saiba que é uma Atualização (Update)
    final fornecedorAtualizado = Fornecedor(
      id: widget.fornecedor.id, // ID obrigatório aqui
      nome: _nomeController.text.trim(),
      cnpj: _cnpjController.text.trim().isEmpty
          ? null
          : _cnpjController.text.trim(),
      fone: _foneController.text.trim().isEmpty
          ? null
          : _foneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      endereco: _enderecoController.text.trim().isEmpty
          ? null
          : _enderecoController.text.trim(),
      ativo: _ativo,
      dataCriacao: widget.fornecedor.dataCriacao, // Mantém a data original
    );

    final viewModel = context.read<FornecedorViewModel>();
    final sucesso = await viewModel.salvarFornecedor(fornecedorAtualizado);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fornecedor atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Volta para a lista
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.erro ?? 'Erro ao atualizar fornecedor.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estaCarregando = context.watch<FornecedorViewModel>().estaCarregando;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Fornecedor'),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Empresa *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O nome é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cnpjController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _foneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _enderecoController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Endereço Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                SwitchListTile(
                  title: const Text(
                    'Fornecedor Ativo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Se desativado, não aparecerá nas opções de entrada de insumos.',
                  ),
                  value: _ativo,
                  activeColor: Colors.green,
                  onChanged: (bool value) {
                    setState(() {
                      _ativo = value;
                    });
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: estaCarregando ? null : _salvarAlteracoes,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: estaCarregando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Salvar Alterações',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
