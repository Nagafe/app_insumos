import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fornecedor.dart';
import '../mvvm/fornecedor_view_model.dart';

class FornecedorAddPage extends StatefulWidget {
  const FornecedorAddPage({super.key});

  @override
  State<FornecedorAddPage> createState() => _FornecedorAddPageState();
}

class _FornecedorAddPageState extends State<FornecedorAddPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar o texto digitado
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _foneController = TextEditingController();
  final _emailController = TextEditingController();
  final _enderecoController = TextEditingController();

  // O fornecedor já nasce ativo por padrão
  bool _ativo = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _foneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    // Valida se os campos obrigatórios foram preenchidos
    if (!_formKey.currentState!.validate()) return;

    // Esconde o teclado
    FocusScope.of(context).unfocus();

    // Monta o objeto Fornecedor com os dados da tela
    final novoFornecedor = Fornecedor(
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
    );

    // Pede ao ViewModel para salvar
    final viewModel = context.read<FornecedorViewModel>();
    final sucesso = await viewModel.salvarFornecedor(novoFornecedor);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fornecedor cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Volta para a tela de listagem
      Navigator.pop(context);
    } else {
      // O erro exato já está guardado no viewModel.erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.erro ?? 'Erro ao salvar fornecedor.'),
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
        title: const Text('Novo Fornecedor'),
        backgroundColor: Colors.red,
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
                  onPressed: estaCarregando ? null : _salvar,
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
                          'Salvar Fornecedor',
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
