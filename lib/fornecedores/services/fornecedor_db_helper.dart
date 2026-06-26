import 'dart:io'show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/fornecedor.dart';

class FornecedorDbHelper {
  static final FornecedorDbHelper instance = FornecedorDbHelper._init();
  static Database? _database;

  FornecedorDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fornecedores.db');
    return _database!;
  }
  Future<void> deletarLocal(String id) async {
    final db = await instance.database;
    await db.delete(
      'fornecedores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Database> _initDB(String filePath) async {
    // 1. ESCUDO CONTRA A WEB
    if (kIsWeb) {
      throw Exception("Modo Offline (SQFlite) não é suportado em navegadores Web. Por favor, rode no Windows ou Emulador Android.");
    }

    // 2. CONFIGURAÇÃO PARA WINDOWS/DESKTOP
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dbPath = await databaseFactory.getDatabasesPath();
    } else {
      dbPath = await getDatabasesPath();
    }

    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fornecedores (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        cnpj TEXT,
        fone TEXT,
        email TEXT,
        endereco TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        sincronizado INTEGER NOT NULL DEFAULT 1 
      )
    ''');
  }

  // O parâmetro sincronizado define se o dado já foi para a nuvem (1) ou está pendente (0)
  Future<void> salvarLocal(
    Fornecedor fornecedor, {
    bool estaSincronizado = true,
  }) async {
    final db = await instance.database;

    final dados = fornecedor.toMap();
    dados['id'] = fornecedor.id;
    dados['ativo'] = fornecedor.ativo ? 1 : 0;
    dados['sincronizado'] = estaSincronizado
        ? 1
        : 0; // Nova regra de negócio local

    await db.insert(
      'fornecedores',
      dados,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Fornecedor>> listarLocal() async {
    final db = await instance.database;
    final resultado = await db.query('fornecedores', orderBy: 'nome ASC');

    return resultado.map((json) {
      final mapaAjustado = Map<String, dynamic>.from(json);
      mapaAjustado['ativo'] = json['ativo'] == 1;
      return Fornecedor.fromMap(mapaAjustado);
    }).toList();
  }

  // Busca apenas o que foi criado ou editado enquanto estava sem internet
  Future<List<Map<String, dynamic>>> listarPendentes() async {
    final db = await instance.database;
    return await db.query(
      'fornecedores',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
  }

  Future<void> marcarComoSincronizado(String id) async {
    final db = await instance.database;
    await db.update(
      'fornecedores',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
