import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/atendimento.dart';
import '../models/cliente.dart';
import '../models/movimentacao_financeira.dart';
import '../models/servico.dart';
import '../services/notification_service.dart';

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
    final path = join(await getDatabasesPath(), 'agendaluz_v5.db');

    return await openDatabase(path, version: 5, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> marcarAtendimentosConcluidosAutomaticamente() async {
    final dbClient = await db;
    // Marca como concluído apenas atendimentos que passaram 2 horas do horário marcado
    // E que não foram reagendados para o futuro
    final duasHorasAtras = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
    final agora = DateTime.now().toIso8601String();

    await dbClient.update(
      'atendimentos',
      {'concluido': 1},
      where: 'data_hora < ? AND data_hora < ? AND concluido = 0',
      whereArgs: [duasHorasAtras, agora],
    );
  }

  // Verifica se um atendimento deve ser marcado como concluído automaticamente
  bool deveSerConcluido(DateTime dataHoraAtendimento) {
    final agora = DateTime.now();
    final duasHorasDepois = dataHoraAtendimento.add(const Duration(hours: 2));
    return agora.isAfter(duasHorasDepois);
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
        concluido INTEGER DEFAULT 0,
        servico_id INTEGER,
        tempo_estimado_minutos INTEGER,
        FOREIGN KEY (servico_id) REFERENCES servicos (id)
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

    await db.execute('''
      CREATE TABLE servicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        custo REAL,
        tempo_medio_minutos INTEGER NOT NULL,
        data_criacao TEXT NOT NULL
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

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE servicos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          valor REAL NOT NULL,
          custo REAL,
          tempo_medio_minutos INTEGER NOT NULL,
          data_criacao TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute("ALTER TABLE atendimentos ADD COLUMN servico_id INTEGER");
      await db.execute("ALTER TABLE atendimentos ADD COLUMN tempo_estimado_minutos INTEGER");
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

    // Agenda notificações para o atendimento
    final atendimentoComId = a.copyWith(id: id);
    await NotificationService.agendarNotificacoesAtendimento(atendimentoComId);

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
        a.id,
        a.cliente_id,
        a.nome_livre,
        a.data_hora,
        a.valor,
        a.pago,
        a.observacoes,
        a.concluido,
        a.servico_id,
        a.tempo_estimado_minutos,
        c.nome as nome_cliente,
        s.nome as nome_servico
      FROM atendimentos a
      LEFT JOIN clientes c ON a.cliente_id = c.id
      LEFT JOIN servicos s ON a.servico_id = s.id
      ORDER BY a.data_hora ASC
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

    // Se o atendimento estava marcado como pago e agora não está mais, remova a movimentação financeira
    if (eraPago && !a.pago) {
      await dbClient.delete(
        'movimentacoes_financeiras',
        where: 'atendimento_id = ?',
        whereArgs: [a.id],
      );
    }

    // Se o pagamento foi marcado, cria uma movimentação financeira (caso ainda não exista)
    if (!eraPago && a.pago == true) {
      final jaExiste = await movimentacaoExisteParaAtendimento(a.id!);
      if (!jaExiste) {
        await inserirMovimentacaoAutomatica(a);
      }
    }

    // Reagenda notificações para o atendimento
    await NotificationService.agendarNotificacoesAtendimento(atendimentoCorrigido);

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

    return a.nomeLivre.trim().isEmpty ? 'Cliente' : a.nomeLivre;
  }

  Future<int> deletarAtendimento(int id) async {
    final dbClient = await db;

    // Cancela notificações relacionadas ao atendimento
    await NotificationService.cancelarNotificacoesAtendimento(id);

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

  // ===================== Previsão de Receita =====================

  Future<List<Atendimento>> listarAtendimentosNaoPagos() async {
    final dbClient = await db;
    final maps = await dbClient.query('atendimentos', where: 'pago = 0', orderBy: 'data_hora ASC');
    return maps.map((map) => Atendimento.fromMap(map)).toList();
  }

  Future<double> calcularPrevisaoReceita({DateTime? mes}) async {
    final atendimentos = await listarAtendimentosNaoPagos();

    if (mes != null) {
      final filtrados = atendimentos
          .where((a) => a.dataHora.year == mes.year && a.dataHora.month == mes.month)
          .toList();
      return filtrados.fold<double>(0.0, (total, atendimento) => total + atendimento.valor);
    }

    return atendimentos.fold<double>(0.0, (total, atendimento) => total + atendimento.valor);
  }

  // ===================== CRUD Serviços =====================

  Future<int> inserirServico(Servico servico) async {
    final dbClient = await db;
    return await dbClient.insert('servicos', servico.toMap());
  }

  Future<List<Servico>> listarServicos() async {
    final dbClient = await db;
    final maps = await dbClient.query('servicos', orderBy: 'nome ASC');
    return maps.map((map) => Servico.fromMap(map)).toList();
  }

  Future<Servico?> buscarServicoPorId(int id) async {
    final dbClient = await db;
    final maps = await dbClient.query('servicos', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Servico.fromMap(maps.first);
    }
    return null;
  }

  Future<int> atualizarServico(Servico servico) async {
    final dbClient = await db;
    return await dbClient.update(
      'servicos',
      servico.toMap(),
      where: 'id = ?',
      whereArgs: [servico.id],
    );
  }

  Future<int> deletarServico(int id) async {
    final dbClient = await db;
    return await dbClient.delete('servicos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> contarServicosRealizados(int servicoId) async {
    final dbClient = await db;
    final result = await dbClient.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM atendimentos 
      WHERE servico_id = ? AND concluido = 1
    ''',
      [servicoId],
    );
    return result.first['count'] as int;
  }

  // ===================== Relatórios de Serviços =====================

  Future<Map<String, dynamic>> relatorioMensalServicos({required DateTime mes}) async {
    final dbClient = await db;

    final inicioMes = DateTime(mes.year, mes.month, 1);
    final fimMes = DateTime(mes.year, mes.month + 1, 1).subtract(const Duration(days: 1));

    final inicioMesStr = inicioMes.toIso8601String();
    final fimMesStr = fimMes.toIso8601String();

    // Buscar atendimentos concluídos do mês com informações do serviço
    final atendimentos = await dbClient.rawQuery(
      '''
      SELECT a.*, s.nome as nome_servico
      FROM atendimentos a
      LEFT JOIN servicos s ON a.servico_id = s.id
      WHERE a.data_hora >= ? AND a.data_hora <= ? AND a.concluido = 1
      ORDER BY a.data_hora ASC
    ''',
      [inicioMesStr, fimMesStr],
    );

    // Contar serviços por tipo
    final Map<String, int> servicosPorTipo = {};
    int totalServicos = 0;
    double valorTotal = 0.0;

    for (final atendimento in atendimentos) {
      final nomeServico = (atendimento['nome_servico'] as String?) ?? 'Atendimento padrão';
      servicosPorTipo[nomeServico] = (servicosPorTipo[nomeServico] ?? 0) + 1;
      totalServicos++;
      valorTotal += (atendimento['valor'] as double?) ?? 0.0;
    }

    return {
      'servicosPorTipo': servicosPorTipo,
      'totalServicos': totalServicos,
      'valorTotal': valorTotal,
      'mes': mes,
    };
  }
}
