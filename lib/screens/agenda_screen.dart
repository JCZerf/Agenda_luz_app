import 'package:AgendaLuz/database/database_helper.dart';
import 'package:AgendaLuz/models/atendimento.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _abaSelecionada = 0;
  DateTime _dataSelecionada = DateTime.now();

  final List<String> opcoes = ['Diário', 'Semanal', 'Mensal'];
  List<Map<String, dynamic>> _todos = [];

  @override
  void initState() {
    super.initState();
    DatabaseHelper().marcarAtendimentosConcluidosAutomaticamente();
    carregarAgendamentos();
  }

  void _determinarAbaInicial() {
    // Verifica se há atendimentos para hoje (diário)
    final hoje = DateTime.now();
    final atendimentosHoje = _todos.where((a) {
      final data = DateTime.parse(a['data_hora']);
      return data.year == hoje.year && data.month == hoje.month && data.day == hoje.day;
    }).toList();

    if (atendimentosHoje.isNotEmpty) {
      setState(() => _abaSelecionada = 0); // Diário
      return;
    }

    // Verifica se há atendimentos para esta semana (semanal)
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
    final fimSemana = inicioSemana.add(const Duration(days: 6));
    final atendimentosSemana = _todos.where((a) {
      final data = DateTime.parse(a['data_hora']);
      return data.isAfter(inicioSemana.subtract(const Duration(seconds: 1))) &&
          data.isBefore(fimSemana.add(const Duration(days: 1)));
    }).toList();

    if (atendimentosSemana.isNotEmpty) {
      setState(() => _abaSelecionada = 1); // Semanal
      return;
    }

    // Verifica se há atendimentos para este mês (mensal)
    final atendimentosMes = _todos.where((a) {
      final data = DateTime.parse(a['data_hora']);
      return data.year == hoje.year && data.month == hoje.month;
    }).toList();

    if (atendimentosMes.isNotEmpty) {
      setState(() => _abaSelecionada = 2); // Mensal
      return;
    }

    // Se não há atendimentos em nenhuma aba, mantém diário (padrão)
    setState(() => _abaSelecionada = 0);
  }

  void carregarAgendamentos() async {
    final atendimentos = await DatabaseHelper().listarAtendimentosComNomeCliente();
    setState(() {
      _todos = atendimentos;
    });

    // Determina a aba inicial baseada na disponibilidade de atendimentos
    _determinarAbaInicial();
  }

  List<Map<String, dynamic>> _filtrar() {
    final agora = _dataSelecionada;
    if (_abaSelecionada == 0) {
      return _todos.where((a) {
        final data = DateTime.parse(a['data_hora']);
        return data.year == agora.year && data.month == agora.month && data.day == agora.day;
      }).toList();
    } else if (_abaSelecionada == 1) {
      final inicioSemana = agora.subtract(Duration(days: agora.weekday - 1));
      final fimSemana = inicioSemana.add(const Duration(days: 6));
      return _todos.where((a) {
        final data = DateTime.parse(a['data_hora']);
        return data.isAfter(inicioSemana.subtract(const Duration(seconds: 1))) &&
            data.isBefore(fimSemana.add(const Duration(days: 1)));
      }).toList();
    } else {
      return _todos.where((a) {
        final data = DateTime.parse(a['data_hora']);
        return data.year == agora.year && data.month == agora.month;
      }).toList();
    }
  }

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _mostrarDetalhes(BuildContext context, Map<String, dynamic> a) {
    final dataHora = DateTime.parse(a['data_hora']);
    final data = DateFormat('dd/MM/yyyy HH:mm').format(dataHora);
    final valor = (a['valor'] as num).toDouble();
    final nome = a['nome_livre'] ?? 'Cliente';
    final pago = a['pago'] == 1;
    final concluido = a['concluido'] == 1;
    final observacoes = a['observacoes'] ?? '';
    final tempoEstimado = a['tempo_estimado_minutos'] as int?;
    final nomeServico = a['nome_servico'] as String?;

    // Verifica se deveria ser concluído automaticamente
    final agora = DateTime.now();
    final duasHorasDepois = dataHora.add(const Duration(hours: 2));
    final deveSerConcluido = agora.isAfter(duasHorasDepois) && dataHora.isBefore(agora);

    String statusTexto;
    Color statusCor;
    IconData statusIcon;

    if (concluido) {
      statusTexto = 'Concluído';
      statusCor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (deveSerConcluido) {
      statusTexto = 'Auto-concluído (2h+)';
      statusCor = Colors.orange;
      statusIcon = Icons.schedule;
    } else {
      statusTexto = 'Pendente';
      statusCor = Colors.orange;
      statusIcon = Icons.pending;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Detalhes do Atendimento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[900],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.pink),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Cliente: $nome')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.pink),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Data/Hora: $data')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.pink),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Valor: R\$ ${valor.toStringAsFixed(2)}')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    pago ? Icons.check_circle : Icons.cancel,
                    color: pago ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Pago: ${pago ? 'Sim' : 'Não'}')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(statusIcon, color: statusCor),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Status: $statusTexto')),
                ],
              ),
              if (nomeServico != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.spa, color: Colors.pink),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Serviço: $nomeServico')),
                  ],
                ),
              ],
              if (tempoEstimado != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.pink),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Tempo estimado: ${tempoEstimado}min')),
                  ],
                ),
              ],
              if (observacoes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, color: Colors.pink),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Obs: $observacoes')),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/agendamento',
                          arguments: {
                            'modo': a['cliente_id'] == null ? 'semCliente' : 'comCliente',
                            'atendimento': Atendimento.fromMap(a),
                          },
                        ).then((_) => carregarAgendamentos());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!concluido && !deveSerConcluido)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Concluir'),
                        onPressed: () async {
                          final atendimento = Atendimento.fromMap(a)..concluido = true;
                          await DatabaseHelper().atualizarAtendimento(atendimento);
                          Navigator.pop(context);
                          carregarAgendamentos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Atendimento marcado como concluído')),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  child: const Text('Fechar'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarOpcoes(BuildContext context, Map<String, dynamic> agendamento) {
    final dataHora = DateTime.parse(agendamento['data_hora']);
    final agora = DateTime.now();
    final duasHorasDepois = dataHora.add(const Duration(hours: 2));
    final deveSerConcluido = agora.isAfter(duasHorasDepois) && dataHora.isBefore(agora);
    final concluido = agendamento['concluido'] == 1;

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Visualizar'),
            onTap: () {
              Navigator.pop(context);
              _mostrarDetalhes(context, agendamento);
            },
          ),
          if (!concluido && !deveSerConcluido)
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Marcar como concluído'),
              onTap: () async {
                Navigator.pop(context);
                final atendimento = Atendimento.fromMap(agendamento);
                atendimento.concluido = true;

                await DatabaseHelper().atualizarAtendimento(atendimento);
                carregarAgendamentos();

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Atendimento marcado como concluído')));
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/agendamento',
                arguments: {
                  'modo': agendamento['cliente_id'] == null ? 'semCliente' : 'comCliente',
                  'atendimento': Atendimento.fromMap(agendamento),
                },
              ).then((_) => carregarAgendamentos());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirmado = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Excluir Agendamento'),
                  content: const Text('Deseja realmente excluir este agendamento?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      child: const Text('Excluir'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirmado == true) {
                await DatabaseHelper().deletarAtendimento(agendamento['id']);
                carregarAgendamentos();
              }
            },
          ),
        ],
      ),
    );
  }

  void _mostrarCriarAgendamento() async {
    const rosaTexto = Color(0xFF8A4B57);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Como deseja agendar?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Com cliente cadastrada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosaTexto,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/agendamento',
                    arguments: {'modo': 'comCliente'},
                  ).then((_) => carregarAgendamentos());
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_off),
                label: const Text('Sem cadastro de cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosaTexto,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/agendamento',
                    arguments: {'modo': 'semCliente'},
                  ).then((_) => carregarAgendamentos());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const rosaClaro = Color(0xFFFFF1F3);
    const rosaPrincipal = Color(0xFFD9A7B0);
    const rosaTexto = Color(0xFF8A4B57);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: rosaTexto,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Agenda',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            tooltip: 'Notificações',
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.date_range, color: Colors.white),
              onPressed: () async {
                final selecionada = await showDatePicker(
                  context: context,
                  initialDate: _dataSelecionada,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (selecionada != null) {
                  setState(() {
                    _dataSelecionada = selecionada;
                  });
                }
              },
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Column(
            children: [
              Container(
                color: rosaClaro,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(opcoes.length, (index) {
                    final selecionado = _abaSelecionada == index;
                    return GestureDetector(
                      onTap: () => setState(() => _abaSelecionada = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: selecionado ? rosaTexto : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: rosaTexto, width: 2),
                          boxShadow: selecionado
                              ? [
                                  BoxShadow(
                                    color: rosaTexto.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              index == 0
                                  ? Icons.today
                                  : index == 1
                                  ? Icons.view_week
                                  : Icons.calendar_month,
                              color: selecionado ? Colors.white : rosaTexto,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              opcoes[index],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selecionado ? Colors.white : rosaTexto,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (!_mesmoDia(_dataSelecionada, DateTime.now()))
                Container(
                  color: rosaClaro,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rosaTexto.withOpacity(0.3)),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _dataSelecionada = DateTime.now();
                            _abaSelecionada = 0;
                          });
                        },
                        icon: const Icon(Icons.today, color: rosaTexto, size: 18),
                        label: const Text(
                          'Voltar para Hoje',
                          style: TextStyle(
                            color: rosaTexto,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Container(
              color: rosaClaro,
              child: _filtrar().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum agendamento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _abaSelecionada == 0
                                ? 'para hoje'
                                : _abaSelecionada == 1
                                ? 'para esta semana'
                                : 'para este mês',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: _filtrar().map((a) {
                        final data = DateTime.parse(a['data_hora']);
                        final formatada = DateFormat('dd/MM/yyyy HH:mm').format(data);
                        final nome = a['nome_cliente'] ?? a['nome_livre'] ?? 'Sem cadastro';
                        final valor = (a['valor'] as num).toDouble();
                        final concluido = a['concluido'] == 1;
                        final pago = a['pago'] == 1;

                        // Verifica se deveria ser concluído automaticamente (2h após o horário)
                        // MAS apenas se a data não for no futuro
                        final agora = DateTime.now();
                        final duasHorasDepois = data.add(const Duration(hours: 2));
                        final deveSerConcluido =
                            agora.isAfter(duasHorasDepois) && data.isBefore(agora);

                        // Status para exibição: se já foi concluído ou se deveria ser
                        final statusConcluido = concluido || deveSerConcluido;

                        return Dismissible(
                          key: ValueKey(a['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            padding: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Confirmar exclusão'),
                                content: const Text('Deseja excluir este agendamento?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            await DatabaseHelper().deletarAtendimento(a['id']);
                            carregarAgendamentos();
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Agendamento excluído')));
                          },
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _mostrarOpcoes(context, a),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Ícone de status
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: statusConcluido
                                            ? Colors.green[50]
                                            : rosaPrincipal.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: statusConcluido ? Colors.green : rosaPrincipal,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        statusConcluido ? Icons.check_circle : Icons.favorite,
                                        color: statusConcluido ? Colors.green : rosaPrincipal,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Informações principais
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: rosaTexto,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                formatada,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'R\$ ${valor.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status e ações
                                    Column(
                                      children: [
                                        if (pago)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.green, width: 1),
                                            ),
                                            child: Text(
                                              'PAGO',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (concluido)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue, width: 1),
                                            ),
                                            child: Text(
                                              'CONCLUÍDO',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (!concluido && deveSerConcluido)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.orange, width: 1),
                                            ),
                                            child: Text(
                                              'AUTO-CONCLUÍDO',
                                              style: TextStyle(
                                                color: Colors.orange[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        const Icon(Icons.more_vert, color: rosaTexto, size: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: rosaTexto.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _mostrarCriarAgendamento,
          backgroundColor: rosaTexto,
          shape: const CircleBorder(),
          tooltip: 'Novo Agendamento',
          elevation: 0,
          child: const Icon(Icons.favorite, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
