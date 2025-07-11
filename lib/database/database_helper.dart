import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/atendimento.dart';
import '../models/cliente.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'agendaluz_v3.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT NOT NULL,
        observacoes TEXT,
        historico TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE atendimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER,
        nome_livre TEXT,
        data_hora TEXT NOT NULL,
        valor REAL NOT NULL,
        pago INTEGER NOT NULL,
        observacoes TEXT
      )
    ''');
  }

  // ===================== CRUD Atendimentos =====================

  Future<int> inserirAtendimento(Atendimento a) async {
    final dbClient = await db;
    return await dbClient.insert('atendimentos', a.toMap());
  }

  Future<List<Atendimento>> listarAtendimentos() async {
    final dbClient = await db;
    final maps = await dbClient.query('atendimentos', orderBy: 'data_hora ASC');
    return maps.map((map) => Atendimento.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> listarAtendimentosComNomeCliente() async {
    final dbClient = await db;
    return await dbClient.rawQuery('''
      SELECT 
        a.*, 
        COALESCE(c.nome, a.nome_livre) AS nome_cliente
      FROM atendimentos a
      LEFT JOIN clientes c ON a.cliente_id = c.id
      ORDER BY a.data_hora ASC
    ''');
  }

  Future<int> atualizarAtendimento(Atendimento a) async {
    final dbClient = await db;
    return await dbClient.update('atendimentos', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<int> deletarAtendimento(int id) async {
    final dbClient = await db;
    return await dbClient.delete('atendimentos', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== CRUD Clientes =====================

  Future<int> inserirCliente(Cliente c) async {
    final dbClient = await db;
    return await dbClient.insert('clientes', c.toMap());
  }

  Future<List<Cliente>> listarClientes() async {
    final dbClient = await db;
    final maps = await dbClient.query('clientes', orderBy: 'nome ASC');
    return maps.map((map) => Cliente.fromMap(map)).toList();
  }

  Future<int> atualizarCliente(Cliente c) async {
    final dbClient = await db;
    return await dbClient.update('clientes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deletarCliente(int id) async {
    final dbClient = await db;
    return await dbClient.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }
}
