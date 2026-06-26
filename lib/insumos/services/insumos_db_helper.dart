import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/insumo.dart';

class InsumosDbHelper {
  static final InsumosDbHelper instance = InsumosDbHelper._init();
  static Database? _database;

  InsumosDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('insumos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Garante compatibilidade caso rode o emulador via Desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabela espelhando perfeitamente a base do Supabase
    await db.execute('''
      CREATE TABLE insumos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT,
        estoque_minimo INTEGER,
        categoria TEXT,
        unidade_medida TEXT,
        imagem_url TEXT,
        sincronizado INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> salvarLocal(Insumo insumo, {bool estaSincronizado = true}) async {
    final db = await instance.database;
    final dados = insumo.toMap();

    // A flag de controle offline
    dados['sincronizado'] = estaSincronizado ? 1 : 0;

    await db.insert(
      'insumos',
      dados,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Insumo>> listarLocal() async {
    final db = await instance.database;
    final resultado = await db.query('insumos', orderBy: 'nome ASC');
    return resultado.map((json) => Insumo.fromMap(json)).toList();
  }

  // Retorna os dados crus (Map) para facilitar o UPSERT no Supabase depois
  Future<List<Map<String, dynamic>>> listarPendentes() async {
    final db = await instance.database;
    return await db.query('insumos', where: 'sincronizado = ?', whereArgs: [0]);
  }

  Future<void> marcarComoSincronizado(String id) async {
    final db = await instance.database;
    await db.update(
      'insumos',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletarLocal(String id) async {
    final db = await instance.database;
    await db.delete('insumos', where: 'id = ?', whereArgs: [id]);
  }
}