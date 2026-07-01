import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../insumos/services/insumos_db_helper.dart';
import '../../insumos/models/insumo.dart';
import '../models/lote.dart';
import '../models/movimentacao.dart';
import 'movimentacoes_service.dart';

class MovimentacoesServiceHibrido implements MovimentacoesService {
  final _supabase = Supabase.instance.client;
  final _dbHelper = InsumosDbHelper.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Lote>> listarLotesPorInsumo(String insumoId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> mapas = await db.query(
      'lotes',
      where: 'insumo_id = ? AND quantidade_lote > 0',
      whereArgs: [insumoId],
      orderBy: 'data_validade ASC',
    );
    return mapas.map((json) => Lote.fromMap(json)).toList();
  }

  @override
  Future<void> registrarMovimentacao({
    required Movimentacao movimentacao,
    required Lote lote,
    required Insumo insumo,
    required bool isNovaEntrada,
  }) async {
    final db = await _dbHelper.database;
    final String movId = movimentacao.id ?? _uuid.v4();
    final String loteId = lote.id ?? _uuid.v4();

    movimentacao.id = movId;
    lote.id = loteId;

    debugPrint('--- DEBUG MOVIMENTAÇÃO ---');
    debugPrint('Insumo Atual: ${insumo.nome} | Saldo: ${insumo.saldoGeral} | Custo Médio: ${insumo.custoMedio}');
    debugPrint('Movimentação: ${movimentacao.tipo} | Qtd: ${movimentacao.quantidade} | Custo Unit: ${movimentacao.custoUnitario}');
    // ----- MATEMÁTICA FINANCEIRA DO ESTOQUE -----
    double novoCustoMedio = insumo.custoMedio;
    int novoSaldoGeral = insumo.saldoGeral;

    if (movimentacao.tipo == 'ENTRADA') {
      novoSaldoGeral += movimentacao.quantidade;
      // Fórmula do Custo Médio:
      // ((Saldo Antigo * Custo Médio Antigo) + (Quantidade Nova * Custo Unitario Novo)) / Novo Saldo Total
      double valorEstoqueAntigo = insumo.saldoGeral * insumo.custoMedio;
      double valorCompraAtual = movimentacao.quantidade * movimentacao.custoUnitario;

      if (novoSaldoGeral > 0) {
        novoCustoMedio = (valorEstoqueAntigo + valorCompraAtual) / novoSaldoGeral;
      }
    } else {
      // Saída não altera o custo médio, apenas o saldo
      novoSaldoGeral -= movimentacao.quantidade;
    }
    debugPrint('Calculado -> Novo Saldo: $novoSaldoGeral | Novo Custo: $novoCustoMedio');
    // 1. TRANSAÇÃO LOCAL (SQLite)
    await db.transaction((txn) async {
      if (isNovaEntrada) {
        await txn.insert('lotes', lote.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await txn.update('lotes', {'quantidade_lote': lote.quantidadeLote}, where: 'id = ?', whereArgs: [lote.id]);
      }

      final mapMov = movimentacao.toMap();
      mapMov['sincronizado'] = 0;
      await txn.insert('movimentacoes', mapMov);

      // Atualiza o Saldo Geral E o Custo Médio do Insumo
      await txn.update(
        'insumos',
        {
          'saldo_geral': novoSaldoGeral,
          'custo_medio': novoCustoMedio
        },
        where: 'id = ?',
        whereArgs: [insumo.id],
      );
    });

    // 2. TENTATIVA DE SINCRONIZAÇÃO IMEDIATA (Supabase)
    try {
      if (isNovaEntrada) {
        await _supabase.from('lotes').upsert(lote.toMap());
      } else {
        await _supabase.from('lotes').update({'quantidade_lote': lote.quantidadeLote}).eq('id', lote.id!);
      }

      await _supabase.from('movimentacoes').insert(movimentacao.toMap());

      // Sincroniza os novos cálculos do Insumo na nuvem (mantendo Supabase e SQLite idênticos)
      await _supabase.from('insumos').update({
        'saldo_geral': novoSaldoGeral,
        'custo_medio': novoCustoMedio
      }).eq('id', insumo.id!);

      await db.update('movimentacoes', {'sincronizado': 1}, where: 'id = ?', whereArgs: [movId]);
    } catch (e) {
      print('Modo Offline: Movimentação de ${movimentacao.tipo} salva localmente.');
    }
  }
}