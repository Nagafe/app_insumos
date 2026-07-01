import 'package:flutter/material.dart';
import '../../insumos/services/insumos_db_helper.dart';

class InsumoCritico {
  final String nome;
  final int saldoGeral;
  final int estoqueMinimo;
  final String? unidadeMedida;

  InsumoCritico({
    required this.nome,
    required this.saldoGeral,
    required this.estoqueMinimo,
    this.unidadeMedida,
  });
}

class LoteVencendo {
  final String nomeInsumo;
  final String numeroLote;
  final DateTime dataValidade;
  final int quantidade;

  LoteVencendo({
    required this.nomeInsumo,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidade,
  });

  int get diasRestantes => dataValidade.difference(DateTime.now()).inDays;
  bool get jaVencido => diasRestantes < 0;
}

class ConsumoMensal {
  final String mesLabel;
  final double totalQuantidade;
  ConsumoMensal({required this.mesLabel, required this.totalQuantidade});
}

class DashboardViewModel extends ChangeNotifier {
  final InsumosDbHelper _dbHelper = InsumosDbHelper.instance;

  double _valorTotalInventario = 0.0;
  int _itensCriticos = 0;
  bool _estaCarregando = false;
  String? _erro;

  List<InsumoCritico> _insumosCriticos = [];
  List<LoteVencendo> _lotesVencendo = [];
  List<ConsumoMensal> _consumoMensal = [];

  double get valorTotalInventario => _valorTotalInventario;
  int get itensCriticos => _itensCriticos;
  bool get estaCarregando => _estaCarregando;
  String? get erro => _erro;
  List<InsumoCritico> get insumosCriticos => _insumosCriticos;
  List<LoteVencendo> get lotesVencendo => _lotesVencendo;
  List<ConsumoMensal> get consumoMensal => _consumoMensal;

  Future<void> carregarDados() async {
    _estaCarregando = true;
    _erro = null;
    notifyListeners();

    try {
      final db = await _dbHelper.database;

      // 1. Patrimônio em Estoque (Garante que tudo é número)
      final resultadoValor = await db.rawQuery(
          'SELECT SUM(IFNULL(saldo_geral, 0) * IFNULL(custo_medio, 0)) as total FROM insumos WHERE ativo = 1'
      );
      _valorTotalInventario = (resultadoValor.first['total'] as num?)?.toDouble() ?? 0.0;

      // 2. Alertas de Reposição (Insumos Críticos)
      final resultadoCriticos = await db.rawQuery('''
        SELECT nome, saldo_geral, estoque_minimo, unidade_medida
        FROM insumos
        WHERE saldo_geral <= estoque_minimo AND ativo = 1
        ORDER BY (saldo_geral - estoque_minimo) ASC
      ''');

      _itensCriticos = resultadoCriticos.length;
      _insumosCriticos = resultadoCriticos.map((row) => InsumoCritico(
        nome: row['nome']?.toString() ?? '—',
        saldoGeral: (row['saldo_geral'] as num?)?.toInt() ?? 0,
        estoqueMinimo: (row['estoque_minimo'] as num?)?.toInt() ?? 0,
        unidadeMedida: row['unidade_medida']?.toString(),
      )).toList();

      // 3. Lotes Vencendo (Próximos 30 dias)
      final limiteStr = DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0];
      final resultadoLotes = await db.rawQuery('''
        SELECT l.numero_lote, l.data_validade, l.quantidade_lote, i.nome as insumo_nome
        FROM lotes l
        INNER JOIN insumos i ON i.id = l.insumo_id
        WHERE l.quantidade_lote > 0 AND date(l.data_validade) <= date(?)
        ORDER BY l.data_validade ASC
      ''', [limiteStr]);

      _lotesVencendo = resultadoLotes.map((row) => LoteVencendo(
        nomeInsumo: row['insumo_nome']?.toString() ?? '—',
        numeroLote: row['numero_lote']?.toString() ?? '—',
        dataValidade: DateTime.tryParse(row['data_validade'].toString()) ?? DateTime.now(),
        quantidade: (row['quantidade_lote'] as num?)?.toInt() ?? 0,
      )).toList();

      // 4. Gráfico de Consumo (Últimos 6 meses)
      final resultadoConsumo = await db.rawQuery('''
        SELECT strftime('%Y-%m', data_movimentacao) as mes, SUM(quantidade) as total
        FROM movimentacoes
        WHERE tipo = 'SAIDA' AND data_movimentacao IS NOT NULL
        GROUP BY mes
        ORDER BY mes ASC
      ''');

      final ultimosSeis = resultadoConsumo.length > 6
          ? resultadoConsumo.sublist(resultadoConsumo.length - 6)
          : resultadoConsumo;

      _consumoMensal = ultimosSeis.map((row) => ConsumoMensal(
        mesLabel: _formatarMesLabel(row['mes']?.toString() ?? ''),
        totalQuantidade: (row['total'] as num?)?.toDouble() ?? 0.0,
      )).toList();

    } catch (e) {
      _erro = 'Erro ao carregar Dashboard: $e';
    } finally {
      _estaCarregando = false;
      notifyListeners();
    }
  }

  String _formatarMesLabel(String mesIso) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final partes = mesIso.split('-');
    if (partes.length != 2) return mesIso;
    final ano = partes[0].length >= 4 ? partes[0].substring(2) : partes[0];
    final mesIndex = int.tryParse(partes[1]);
    if (mesIndex == null || mesIndex < 1 || mesIndex > 12) return mesIso;
    return '${meses[mesIndex - 1]}/$ano';
  }
}