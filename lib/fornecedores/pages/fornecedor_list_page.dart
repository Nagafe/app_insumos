import 'package:app_insumos/fornecedores/pages/fornecedor_add_page.dart';
import 'package:app_insumos/fornecedores/pages/fornecedor_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mvvm/fornecedor_view_model.dart';

class FornecedoresListPage extends StatefulWidget {
  const FornecedoresListPage({super.key});

  @override
  State<FornecedoresListPage> createState() => _FornecedoresListPageState();
}

class _FornecedoresListPageState extends State<FornecedoresListPage> {
  @override
  void initState() {
    super.initState();
    // Pede ao ViewModel para buscar os dados assim que a tela for construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FornecedorViewModel>().carregarFornecedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FornecedorViewModel>();

    return Scaffold(
      // Usamos Column para colocar a barra de busca em cima e a lista embaixo
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (valor) {
                // Chama o método que criamos no ViewModel
                context.read<FornecedorViewModel>().pesquisar(valor);
              },
              decoration: InputDecoration(
                hintText: 'Buscar fornecedor pelo nome...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Lista de Fornecedores
          Expanded(
            child: _construirConteudo(viewModel),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FornecedorAddPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //método auxiliar apenas para o código do build principal não ficar gigantesco
  Widget _construirConteudo(FornecedorViewModel viewModel) {
    if (viewModel.estaCarregando && viewModel.fornecedores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.erro != null) {
      return Center(
        child: Text(viewModel.erro!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (viewModel.fornecedores.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum fornecedor encontrado.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.fornecedores.length,
      itemBuilder: (context, index) {
        final fornecedor = viewModel.fornecedores[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: const Icon(
                Icons.business,
                color: Colors.blueAccent,
              ),
            ),
            title: Text(
              fornecedor.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(fornecedor.cnpj ?? 'CNPJ não informado'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fornecedor.ativo ? Icons.check_circle : Icons.cancel,
                  color: fornecedor.ativo ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit,
                  color: Colors.grey,
                  size: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                  onPressed: () {
                    // Impede o clique se não tiver ID válido
                    if (fornecedor.id == null) return;
                    _mostrarDialogoExclusao(context, viewModel, fornecedor);
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FornecedorEditPage(fornecedor: fornecedor),
                ),
              );
            },
          ),
        );
      },
    );
  }
  void _mostrarDialogoExclusao(BuildContext context, FornecedorViewModel viewModel, fornecedor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Fornecedor'),
        content: Text('Tem certeza que deseja excluir ${fornecedor.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Fecha o diálogo
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context); // Fecha o diálogo primeiro

              // Chama a exclusão
              final sucesso = await viewModel.deletarFornecedor(fornecedor.id!);

              // Avisa o usuário na parte de baixo da tela
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fornecedor excluído com sucesso.'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}