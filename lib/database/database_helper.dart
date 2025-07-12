import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/atendimento.dart';
import '../models/cliente.dart';
import '../models/movimentacao_financeira.dart';

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

    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> marcarAtendimentosConcluidosAutomaticamente() async {
    final dbClient = await db;
    final agora = DateTime.now().toIso8601String();

    await dbClient.update(
      'atendimentos',
      {'concluido': 1},
      where: 'data_hora < ? AND concluido = 0',
      whereArgs: [agora],
    );
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
        observacoes TEXT,
        concluido INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE movimentacoes_financeiras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        descricao TEXT NOT NULL,
        data TEXT NOT NULL,
        origem TEXT NOT NULL,
        atendimento_id INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE movimentacoes_financeiras ADD COLUMN tipo TEXT");
      await db.execute("ALTER TABLE movimentacoes_financeiras ADD COLUMN atendimento_id INTEGER");
    }

    if (oldVersion < 3) {
      await db.execute("ALTER TABLE atendimentos ADD COLUMN concluido INTEGER DEFAULT 0");
    }
  }

  // ===================== CRUD Atendimentos =====================

  Future<int> inserirAtendimento(Atendimento a) async {
    final dbClient = await db;
    final id = await dbClient.insert('atendimentos', a.toMap());

    if (a.clienteId != null) {
      final dataFormatada = a.dataHora.toIso8601String();
      await dbClient.update(
        'clientes',
        {'historico': dataFormatada},
        where: 'id = ?',
        whereArgs: [a.clienteId],
      );
    }

    // Verifica se deve criar movimentação automática
    if (a.pago) {
      final atendimentoComId = a.copyWith(id: id);
      final jaExiste = await movimentacaoExisteParaAtendimento(id);
      if (!jaExiste) {
        await inserirMovimentacaoAutomatica(atendimentoComId);
      }
    }

    return id;
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
        id,
        cliente_id,
        nome_livre,
        data_hora,
        valor,
        pago,
        observacoes,
        concluido
      FROM atendimentos
      ORDER BY data_hora ASC
    ''');
  }

  Future<int> atualizarAtendimento(Atendimento a) async {
    final dbClient = await db;

    final anterior = await dbClient.query(
      'atendimentos',
      where: 'id = ?',
      whereArgs: [a.id],
      limit: 1,
    );
    final eraPago = anterior.isNotEmpty ? (anterior.first['pago'] == 1) : false;

    // Verifica se a data é futura => então o atendimento não deve estar concluído
    final agora = DateTime.now();
    final atendimentoCorrigido = a.copyWith(
      concluido: a.dataHora.isAfter(agora) ? false : a.concluido,
    );

    // Atualiza o banco com o atendimento corrigido
    final resultado = await dbClient.update(
      'atendimentos',
      atendimentoCorrigido.toMap(),
      where: 'id = ?',
      whereArgs: [a.id],
    );

    if (!eraPago && a.pago == true) {
      final jaExiste = await movimentacaoExisteParaAtendimento(a.id!);
      if (!jaExiste) {
        await inserirMovimentacaoAutomatica(a);
      }
    }

    return resultado;
  }

  Future<bool> movimentacaoExisteParaAtendimento(int atendimentoId) async {
    final dbClient = await db;
    final resultado = await dbClient.query(
      'movimentacoes_financeiras',
      where: 'atendimento_id = ? AND origem = ?',
      whereArgs: [atendimentoId, 'automatica'],
      limit: 1,
    );
    return resultado.isNotEmpty;
  }

  Future<void> inserirMovimentacaoAutomatica(Atendimento a) async {
    final nomeCliente = await _recuperarNomeCliente(a);
    final movimentacao = MovimentacaoFinanceira(
      tipo: 'receita',
      valor: a.valor,
      descricao: 'Recebido de $nomeCliente',
      data: a.dataHora,
      origem: 'automatica',
      atendimentoId: a.id,
    );
    await inserirMovimentacao(movimentacao);
  }

  Future<String> _recuperarNomeCliente(Atendimento a) async {
    if (a.clienteId != null) {
      final dbClient = await db;
      final cliente = await dbClient.query(
        'clientes',
        where: 'id = ?',
        whereArgs: [a.clienteId],
        limit: 1,
      );
      final nome = cliente.isNotEmpty ? cliente.first['nome'] as String? : null;
      if (nome != null && nome.trim().isNotEmpty) return nome;
    }

    return (a.nomeLivre ?? 'Cliente').trim().isEmpty ? 'Cliente' : a.nomeLivre;
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

  // ===================== CRUD Movimentações =====================

  Future<int> inserirMovimentacao(MovimentacaoFinanceira m) async {
    final dbClient = await db;
    return await dbClient.insert('movimentacoes_financeiras', m.toMap());
  }

  Future<List<MovimentacaoFinanceira>> listarMovimentacoes() async {
    final dbClient = await db;
    final maps = await dbClient.query('movimentacoes_financeiras', orderBy: 'data DESC');
    return maps.map((map) => MovimentacaoFinanceira.fromMap(map)).toList();
  }

  Future<int> atualizarMovimentacao(MovimentacaoFinanceira m) async {
    final dbClient = await db;
    return await dbClient.update(
      'movimentacoes_financeiras',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<int> deletarMovimentacao(int id) async {
    final dbClient = await db;
    return await dbClient.delete('movimentacoes_financeiras', where: 'id = ?', whereArgs: [id]);
  }
}
