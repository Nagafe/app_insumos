import 'package:app_insumos/fornecedores/pages/insumos_add_page.dart';
import 'package:app_insumos/fornecedores/pages/insumos_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mvvm/insumos_view_model.dart';

class InsumosListPage extends StatefulWidget {
  const InsumosListPage({super.key});

  @override
  State<InsumosListPage> createState() => _InsumosListPageState();
}

class _InsumosListPageState extends State<InsumosListPage> {
  @override
  void initState() {
    super.initState();
    // Carrega os insumos assim que a página é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumosViewModel>().carregarInsumos();
    });
  }

  Future<void> _confirmarExclusao(BuildContext context, Insumo insumo) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Insumo'),
        content: Text('Deseja realmente excluir "${insumo.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou == true && insumo.id != null) {
      await context.read<InsumosViewModel>().deletarInsumo(insumo.id!);
    }
  }

  void _abrirFormulario(BuildContext context, {Insumo? insumo}) async {
    final viewModel = context.read<InsumosViewModel>();

    final resultado = await Navigator.push<Insumo>(
      context,
      MaterialPageRoute(
        builder: (_) => InsumoFormPage(insumo: insumo),
      ),
    );

    if (resultado != null) {
      await viewModel.salvarInsumo(resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insumos'),
      ),
      body: Consumer<InsumosViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.estaCarregando && viewModel.insumos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar insumo...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: viewModel.pesquisar,
                ),
              ),
              if (viewModel.erro != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    viewModel.erro!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: viewModel.carregarInsumos,
                  child: viewModel.insumosFiltrados.isEmpty
                      ? const Center(child: Text('Nenhum insumo encontrado.'))
                      : ListView.builder(
                    itemCount: viewModel.insumosFiltrados.length,
                    itemBuilder: (context, index) {
                      final insumo = viewModel.insumosFiltrados[index];

                      return Dismissible(
                        key: ValueKey(insumo.id ?? insumo.nome),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          await _confirmarExclusao(context, insumo);
                          return false; // a exclusão real é feita pelo ViewModel
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: insumo.imagemUrl != null && insumo.imagemUrl!.isNotEmpty
                                ? NetworkImage(insumo.imagemUrl!)
                                : null,
                            child: insumo.imagemUrl == null || insumo.imagemUrl!.isEmpty
                                ? const Icon(Icons.inventory_2_outlined)
                                : null,
                          ),
                          title: Text(insumo.nome),
                          subtitle: Text(
                            [
                              if (insumo.categoria != null) insumo.categoria!,
                              if (insumo.unidadeMedida != null) insumo.unidadeMedida!,
                              if (insumo.estoqueMinimo != null) 'Mín: ${insumo.estoqueMinimo}',
                            ].join(' • '),
                          ),
                          onTap: () => _abrirFormulario(context, insumo: insumo),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}