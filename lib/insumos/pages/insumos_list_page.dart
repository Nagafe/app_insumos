import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mvvm/insumos_view_model.dart';
import 'insumos_add_page.dart';
import 'insumos_edit_page.dart';

class InsumosListPage extends StatefulWidget {
  const InsumosListPage({super.key});

  @override
  State<InsumosListPage> createState() => _InsumosListPageState();
}

class _InsumosListPageState extends State<InsumosListPage> {
  @override
  void initState() {
    super.initState();
    // Dispara a busca inicial de dados de forma assíncrona após o build do widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumosViewModel>().carregarInsumos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuta as alterações de estado no ViewModel de forma reativa
    final viewModel = context.watch<InsumosViewModel>();

    return Scaffold(
      body: Column(
        children: [
          // Campo de busca padronizado com escuta em tempo real
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (valor) => viewModel.pesquisar(valor),
              decoration: InputDecoration(
                hintText: 'Buscar insumo...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
          ),

          // Área dinâmica da listagem que responde ao estado do ViewModel
          Expanded(
            child: _buildConteudo(viewModel),
          ),
        ],
      ),

      // Botão flutuante perfeitamente posicionado e visível na árvore do Scaffold
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const InsumosAddPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Construtor de sub-árvores para isolamento de estados visuais (Alta Coesão)
  Widget _buildConteudo(InsumosViewModel viewModel) {
    if (viewModel.estaCarregando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (viewModel.erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            viewModel.erro!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center, // Correção feita aqui
          ),
        ),
      );
    }

    if (viewModel.insumosFiltrados.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum insumo registado ou encontrado.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    // Renderização eficiente da lista utilizando reciclagem de memória
    return ListView.builder(
      itemCount: viewModel.insumosFiltrados.length,
      itemBuilder: (context, index) {
        final insumo = viewModel.insumosFiltrados[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

            // Renderização condicional e segura da imagem armazenada na nuvem
            leading: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: insumo.imagemUrl != null && insumo.imagemUrl!.isNotEmpty
                  ? (insumo.imagemUrl!.startsWith('http')
                  ? Image.network(
                insumo.imagemUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
              )
                  : Image.file(
                File(insumo.imagemUrl!),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
              ))
                  : Container(
                width: 50,
                height: 50,
                color: Colors.black12,
                child: const Icon(Icons.inventory_2, size: 30, color: Colors.blueAccent),
              ),
            ),

            title: Text(
              insumo.nome,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Mínimo: ${insumo.estoqueMinimo ?? 0} ${insumo.unidadeMedida ?? ''}',
                style: const TextStyle(color: Colors.black54),
              ),
            ),

            // Grupo de ações isoladas com alinhamento compacto
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InsumosEditPage(insumo: insumo),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmarExclusao(context, viewModel, insumo.id!, insumo.nome),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Caixa de diálogo para confirmação de eliminação (Boa prática de UX)
  void _confirmarExclusao(BuildContext context, InsumosViewModel viewModel, String id, String nome) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente eliminar o insumo "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final sucesso = await viewModel.deletarInsumo(id);
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insumo eliminado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}