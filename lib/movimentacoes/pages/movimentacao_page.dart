import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../insumos/models/insumo.dart';
import '../../insumos/mvvm/insumos_view_model.dart';
import '../../fornecedores/models/fornecedor.dart';
import '../../fornecedores/mvvm/fornecedor_view_model.dart';
import '../models/lote.dart';
import '../mvvm/movimentacao_view_model.dart';

class MovimentacaoPage extends StatefulWidget {
  const MovimentacaoPage({super.key});

  @override
  State<MovimentacaoPage> createState() => _MovimentacaoPageState();
}

class _MovimentacaoPageState extends State<MovimentacaoPage> {
  final TextEditingController quantidadeCtrl = TextEditingController();
  final TextEditingController valorTotalCtrl = TextEditingController(); // <-- Alterado
  final TextEditingController motivoCtrl = TextEditingController();
  final TextEditingController numeroLoteCtrl = TextEditingController();

  Insumo? insumoSelecionado;
  Fornecedor? fornecedorSelecionado;
  Lote? loteSelecionado;
  DateTime? dataValidadeSelecionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumosViewModel>().carregarInsumos();
      context.read<FornecedorViewModel>().carregarFornecedores();
    });
  }

  @override
  void dispose() {
    quantidadeCtrl.dispose();
    valorTotalCtrl.dispose(); // <-- Alterado
    motivoCtrl.dispose();
    numeroLoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movViewModel = context.watch<MovimentacaoViewModel>();
    final insumosViewModel = context.watch<InsumosViewModel>();
    final fornecedorViewModel = context.watch<FornecedorViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Movimentação'),
        backgroundColor: movViewModel.isEntrada ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Entrada', style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Saída', style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {movViewModel.isEntrada},
              onSelectionChanged: (Set<bool> newSelection) {
                movViewModel.alternarTipoMovimentacao(newSelection.first);
                _limparCampos();
              },
              style: SegmentedButton.styleFrom(
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: movViewModel.isEntrada ? Colors.green : Colors.orange,
              ),
            ),

            const SizedBox(height: 30),

            DropdownButtonFormField<Insumo>(
              decoration: _buildInputDecoration('Insumo'),
              value: insumoSelecionado,
              items: insumosViewModel.insumos.map((insumo) {
                return DropdownMenuItem(value: insumo, child: Text(insumo.nome));
              }).toList(),
              onChanged: (Insumo? novoInsumo) {
                setState(() {
                  insumoSelecionado = novoInsumo;
                  loteSelecionado = null;
                });
                if (!movViewModel.isEntrada && novoInsumo != null) {
                  movViewModel.buscarLotesDoInsumo(novoInsumo.id!);
                }
              },
            ),
            const SizedBox(height: 20),

            if (movViewModel.isEntrada) ...[
              DropdownButtonFormField<Fornecedor>(
                decoration: _buildInputDecoration('Fornecedor (Origem)'),
                value: fornecedorSelecionado,
                items: fornecedorViewModel.fornecedores.map((forn) {
                  return DropdownMenuItem(value: forn, child: Text(forn.nome));
                }).toList(),
                onChanged: (val) => setState(() => fornecedorSelecionado = val),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: numeroLoteCtrl,
                      decoration: _buildInputDecoration('Novo Lote'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selecionarDataValidade(context),
                      child: InputDecorator(
                        decoration: _buildInputDecoration('Validade'),
                        child: Text(
                          dataValidadeSelecionada != null
                              ? "${dataValidadeSelecionada!.day}/${dataValidadeSelecionada!.month}/${dataValidadeSelecionada!.year}"
                              : 'Selecione...',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: valorTotalCtrl, // <-- Alterado
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Valor Total da Compra (R\$)').copyWith(
                  helperText: 'O sistema calculará o custo médio automaticamente.',
                ),
              ),
            ] else ...[
              DropdownButtonFormField<Lote>(
                decoration: _buildInputDecoration('Lote de Origem'),
                value: loteSelecionado,
                hint: movViewModel.estaCarregando
                    ? const Text('Buscando lotes...')
                    : const Text('Selecione o lote'),
                items: movViewModel.lotesDisponiveis.map((lote) {
                  return DropdownMenuItem(
                      value: lote,
                      child: Text('Lote: ${lote.numeroLote} (Qtd: ${lote.quantidadeLote})')
                  );
                }).toList(),
                onChanged: (val) => setState(() => loteSelecionado = val),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: motivoCtrl,
                decoration: _buildInputDecoration('Motivo / Destino'),
              ),
            ],

            const SizedBox(height: 20),

            TextFormField(
              controller: quantidadeCtrl,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('Quantidade'),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: movViewModel.isEntrada ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: movViewModel.estaCarregando ? null : () => _processarSalvar(movViewModel),
              child: movViewModel.estaCarregando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CONFIRMAR MOVIMENTAÇÃO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  void _limparCampos() {
    setState(() {
      insumoSelecionado = null;
      fornecedorSelecionado = null;
      loteSelecionado = null;
      dataValidadeSelecionada = null;
      quantidadeCtrl.clear();
      valorTotalCtrl.clear(); // <-- Alterado
      motivoCtrl.clear();
      numeroLoteCtrl.clear();
    });
  }

  Future<void> _selecionarDataValidade(BuildContext context) async {
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (selecionada != null) {
      setState(() {
        dataValidadeSelecionada = selecionada;
      });
    }
  }

  Future<void> _processarSalvar(MovimentacaoViewModel movViewModel) async {
    if (insumoSelecionado == null) {
      _mostrarErro('Selecione um insumo.');
      return;
    }
    final listaAtualizada = context.read<InsumosViewModel>().insumos;
    final insumoMaisRecente = listaAtualizada.firstWhere(
          (i) => i.id == insumoSelecionado!.id,
      orElse: () => insumoSelecionado!,
    );

    final int qtd = int.tryParse(quantidadeCtrl.text) ?? 0;
    if (qtd <= 0) {
      _mostrarErro('Informe uma quantidade válida e maior que zero.');
      return;
    }

    double valorDaCompra = 0.0;
    if (movViewModel.isEntrada) {
      valorDaCompra = double.tryParse(valorTotalCtrl.text.replaceAll(',', '.')) ?? 0.0;
      if (valorDaCompra <= 0) {
        _mostrarErro('Informe um valor total de compra válido.');
        return;
      }
    }

    final usuarioAtual = Supabase.instance.client.auth.currentUser;
    if (usuarioAtual == null) {
      _mostrarErro('Erro de sessão: Faça login novamente.');
      return;
    }

    bool sucesso = await movViewModel.processarMovimentacao(
      insumoSelecionado: insumoMaisRecente, // <-- Usa o insumo atualizado aqui!
      quantidade: qtd,
      funcionarioId: usuarioAtual.id,
      fornecedorId: fornecedorSelecionado?.id,
      loteExistente: loteSelecionado,
      novoNumeroLote: numeroLoteCtrl.text.isNotEmpty ? numeroLoteCtrl.text : null,
      novaDataValidade: dataValidadeSelecionada,
      valorTotalCompra: valorDaCompra,
      motivo: motivoCtrl.text,
    );

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimentação registada com sucesso!'), backgroundColor: Colors.green),
      );
      _limparCampos();
      //Recarregar os insumos para refletir o novo saldo na UI imediatamente
      context.read<InsumosViewModel>().carregarInsumos();
    } else if (mounted) {
      _mostrarErro(movViewModel.erro ?? 'Erro desconhecido ao processar movimentação.');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}