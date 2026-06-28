import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../insumos/services/insumos_db_helper.dart'; // Reutilizamos a conexão do helper
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
      orderBy: 'data_validade ASC', // Estratégia FEFO (First Expire, First Out)
    );
    return mapas.map((json) => Lote.fromMap(json)).toList();
  }

  @override
  Future<void> registrarMovimentacao({
    required Movimentacao movimentacao,
    required Lote lote,
    required bool isNovaEntrada,
  }) async {
    final db = await _dbHelper.database;
    final String movId = movimentacao.id ?? _uuid.v4();
    final String loteId = lote.id ?? _uuid.v4();

    movimentacao.id = movId;
    lote.id = loteId;

    // 1. TRANSAÇÃO LOCAL (SQLite) - Atomicidade garantida
    await db.transaction((txn) async {
      // Grava ou atualiza o Lote
      if (isNovaEntrada) {
        await txn.insert('lotes', lote.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await txn.update(
          'lotes',
          {'quantidade_lote': lote.quantidadeLote},
          where: 'id = ?',
          whereArgs: [lote.id],
        );
      }

      // Grava a Movimentação (com a flag oculta de sincronizado = 0 para o background)
      final mapMov = movimentacao.toMap();
      mapMov['sincronizado'] = 0;
      await txn.insert('movimentacoes', mapMov);

      // Atualiza o Saldo Geral do Insumo
      final operador = movimentacao.tipo == 'Entrada' ? '+' : '-';
      await txn.rawUpdate(
          'UPDATE insumos SET saldo_geral = saldo_geral $operador ? WHERE id = ?',
          [movimentacao.quantidade, movimentacao.insumoId]
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

      // Chamada RPC para calcular o saldo diretamente no servidor (Opcional, mas recomendado para consistência)
      // await _supabase.rpc('atualizar_saldo_insumo', params: {'p_insumo_id': movimentacao.insumoId});

      // Se passou sem erros de rede, marca como sincronizado localmente
      await db.update('movimentacoes', {'sincronizado': 1}, where: 'id = ?', whereArgs: [movId]);
    } catch (e) {
      print('Modo Offline: Movimentação de ${movimentacao.tipo} salva localmente com sucesso. Pendente envio para nuvem.');
    }
  }
}