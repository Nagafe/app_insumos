import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../mvvm/dashboard_view_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().carregarDados();
    });
  }

  // Placeholder de navegação — troque pelo Navigator.pushNamed real
  // quando as rotas das outras telas estiverem prontas.
  void _navegarPlaceholder(String destino) {
    // TODO: Navigator.pushNamed(context, '/$destino');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tela "$destino" ainda não conectada'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Painel Principal'),
        elevation: 0,
      ),
      body: viewModel.estaCarregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => viewModel.carregarDados(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (viewModel.erro != null) _buildErro(viewModel.erro!),

            _buildCardFinanceiro(viewModel.valorTotalInventario),
            const SizedBox(height: 20),

            _buildSectionTitle(
                Icons.notifications_active, 'Alertas Gerenciais'),
            const SizedBox(height: 12),
            _buildCardAlertaResumo(viewModel.itensCriticos),
            const SizedBox(height: 16),

            _buildTabelaReposicao(viewModel.insumosCriticos),
            const SizedBox(height: 16),

            _buildTabelaVencimentos(viewModel.lotesVencendo),
            const SizedBox(height: 24),

            _buildSectionTitle(Icons.bar_chart, 'Consumo Mensal'),
            const SizedBox(height: 12),
            _buildGraficoConsumo(viewModel.consumoMensal),
            const SizedBox(height: 20),

            const Text(
              'Puxe para baixo para atualizar os indicadores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- BLOCOS DE UI ----------

  Widget _buildErro(String mensagem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensagem, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String titulo) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildCardFinanceiro(double valor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blue,
              child: Icon(Icons.attach_money, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patrimônio em Estoque',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCardAlertaResumo(int qtd) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: qtd > 0 ? Colors.red.shade50 : Colors.green.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          qtd > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          size: 36,
          color: qtd > 0 ? Colors.red : Colors.green,
        ),
        title: const Text('Itens para Reposição'),
        subtitle: Text(
          qtd > 0 ? '$qtd itens abaixo do mínimo' : 'Estoque saudável',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: qtd > 0 ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildTabelaReposicao(List<InsumoCritico> itens) {
    return _buildCardTabela(
      titulo: 'Reposição Urgente (Mínimo)',
      corHeader: Colors.orange,
      icone: Icons.warning_amber_rounded,
      vazio: 'Estoque saudável.',
      linhas: itens.take(5).map((item) {
        return _LinhaTabela(
          principal: item.nome,
          secundaria: 'Mín: ${item.estoqueMinimo}',
          valor: '${item.saldoGeral}',
          corValor: Colors.red,
        );
      }).toList(),
      rodape: itens.length > 5 ? '+ ${itens.length - 5} itens' : null,
    );
  }

  Widget _buildTabelaVencimentos(List<LoteVencendo> lotes) {
    return _buildCardTabela(
      titulo: 'Vencem em 30 Dias',
      corHeader: Colors.red,
      icone: Icons.calendar_today,
      vazio: 'Nenhum lote vencendo.',
      linhas: lotes.take(5).map((lote) {
        final dia = lote.dataValidade.day.toString().padLeft(2, '0');
        final mes = lote.dataValidade.month.toString().padLeft(2, '0');
        final ano = lote.dataValidade.year;
        return _LinhaTabela(
          principal: lote.nomeInsumo,
          secundaria: 'Lote: ${lote.numeroLote}',
          valor: '$dia/$mes/$ano',
          extra: 'Qtd: ${lote.quantidade}',
          corValor: lote.jaVencido ? Colors.red.shade900 : Colors.red,
        );
      }).toList(),
      rodape: lotes.length > 5 ? '+ ${lotes.length - 5} lotes' : null,
    );
  }

  Widget _buildCardTabela({
    required String titulo,
    required Color corHeader,
    required IconData icone,
    required String vazio,
    required List<_LinhaTabela> linhas,
    String? rodape,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: corHeader,
            child: Row(
              children: [
                Icon(icone, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (linhas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 28),
                    const SizedBox(height: 6),
                    Text(vazio,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            ...linhas.asMap().entries.map((entry) {
              final i = entry.key;
              final linha = entry.value;
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.grey.shade50 : Colors.white,
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(linha.principal,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(linha.secundaria,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          linha.valor,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: linha.corValor,
                            fontSize: 13,
                          ),
                        ),
                        if (linha.extra != null)
                          Text(linha.extra!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          if (rodape != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  rodape,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGraficoConsumo(List<ConsumoMensal> dados) {
    if (dados.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Sem movimentações de saída registradas ainda.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    final maiorValor = dados
        .map((d) => d.totalQuantidade)
        .reduce((a, b) => a > b ? a : b);
    final tetoEixoY = maiorValor <= 0 ? 10.0 : maiorValor * 1.2;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: tetoEixoY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: tetoEixoY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= dados.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dados[i].mesLabel,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: dados.asMap().entries.map((entry) {
                final i = entry.key;
                final ponto = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: ponto.totalQuantidade,
                      color: Colors.blue,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AcaoRapida {
  final String label;
  final IconData icone;
  final Color cor;
  _AcaoRapida(this.label, this.icone, this.cor);
}

class _LinhaTabela {
  final String principal;
  final String secundaria;
  final String valor;
  final String? extra;
  final Color corValor;
  _LinhaTabela({
    required this.principal,
    required this.secundaria,
    required this.valor,
    this.extra,
    required this.corValor,
  });
}
