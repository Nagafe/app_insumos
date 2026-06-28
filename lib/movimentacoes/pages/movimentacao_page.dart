import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  // Controladores de texto para os inputs
  final TextEditingController quantidadeCtrl = TextEditingController();
  final TextEditingController custoCtrl = TextEditingController();
  final TextEditingController motivoCtrl = TextEditingController();
  final TextEditingController numeroLoteCtrl = TextEditingController();

  // Estado das seleções do utilizador
  Insumo? insumoSelecionado;
  Fornecedor? fornecedorSelecionado;
  Lote? loteSelecionado;
  DateTime? dataValidadeSelecionada;

  @override
  void initState() {
    super.initState();
    // Garante que as listas de Insumos e Fornecedores estejam carregadas ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumosViewModel>().carregarInsumos();
      context.read<FornecedorViewModel>().carregarFornecedores();
    });
  }

  @override
  void dispose() {
    quantidadeCtrl.dispose();
    custoCtrl.dispose();
    motivoCtrl.dispose();
    numeroLoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o ViewModel de Movimentação para reagir às mudanças (Entrada/Saída)
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
            // 1. Controle de Alternância (Toggle Entrada/Saída)
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
                _limparCampos(); // Limpa o formulário ao trocar o tipo
              },
              style: SegmentedButton.styleFrom(
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: movViewModel.isEntrada ? Colors.green : Colors.orange,
              ),
            ),

            const SizedBox(height: 30),

            // 2. Seleção de Insumo (Comum a ambos)
            DropdownButtonFormField<Insumo>(
              decoration: _buildInputDecoration('Insumo'),
              value: insumoSelecionado,
              items: insumosViewModel.insumos.map((insumo) {
                return DropdownMenuItem(value: insumo, child: Text(insumo.nome));
              }).toList(),
              onChanged: (Insumo? novoInsumo) {
                setState(() {
                  insumoSelecionado = novoInsumo;
                  loteSelecionado = null; // Reseta o lote se trocar o insumo
                });
                if (!movViewModel.isEntrada && novoInsumo != null) {
                  // Se for saída, busca os lotes do insumo selecionado
                  movViewModel.buscarLotesDoInsumo(novoInsumo.id!);
                }
              },
            ),
            const SizedBox(height: 20),

            // 3. Renderização Dinâmica: Campos Específicos
            if (movViewModel.isEntrada) ...[
              // ------ CAMPOS DE ENTRADA ------
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
                controller: custoCtrl,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Custo Unitário (R\$)'),
              ),
            ] else ...[
              // ------ CAMPOS DE SAÍDA ------
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

            // 4. Quantidade (Comum a ambos)
            TextFormField(
              controller: quantidadeCtrl,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('Quantidade'),
            ),

            const SizedBox(height: 40),

            // 5. Botão de Salvar
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

  // --- MÉTODOS AUXILIARES ---

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
      custoCtrl.clear();
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
    // Validações Base
    if (insumoSelecionado == null) {
      _mostrarErro('Selecione um insumo.');
      return;
    }
    final int qtd = int.tryParse(quantidadeCtrl.text) ?? 0;
    if (qtd <= 0) {
      _mostrarErro('Informe uma quantidade válida e maior que zero.');
      return;
    }

    // ID mockado temporariamente (Na prática, virá do AuthViewModel do utilizador logado)
    const String funcionarioIdMock = '00000000-0000-0000-0000-000000000000';

    bool sucesso = await movViewModel.processarMovimentacao(
      insumoSelecionado: insumoSelecionado!,
      quantidade: qtd,
      funcionarioId: funcionarioIdMock,
      fornecedorId: fornecedorSelecionado?.id,
      loteExistente: loteSelecionado,
      novoNumeroLote: numeroLoteCtrl.text.isNotEmpty ? numeroLoteCtrl.text : null,
      novaDataValidade: dataValidadeSelecionada,
      custoUnitario: double.tryParse(custoCtrl.text) ?? 0.0,
      motivo: motivoCtrl.text,
    );

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimentação registada com sucesso!'), backgroundColor: Colors.green),
      );
      _limparCampos();
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