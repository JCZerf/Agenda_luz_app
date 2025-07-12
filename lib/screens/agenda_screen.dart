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

  void carregarAgendamentos() async {
    final atendimentos = await DatabaseHelper().listarAtendimentosComNomeCliente();
    setState(() {
      _todos = atendimentos;
    });
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
    final data = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(a['data_hora']));
    final valor = (a['valor'] as num).toDouble();
    final nome = a['nome_livre'] ?? 'Cliente';
    final pago = a['pago'] == 1;
    final concluido = a['concluido'] == 1;
    final observacoes = a['observacoes'] ?? '';

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
                  Icon(
                    concluido ? Icons.done : Icons.pending,
                    color: concluido ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Status: ${concluido ? 'Concluído' : 'Pendente'}')),
                ],
              ),
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
                  if (!concluido)
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
          if (agendamento['concluido'] == 0)
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
        title: Text(
          'Agenda - ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
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
        ],
      ),

      body: Column(
        children: [
          Column(
            children: [
              Container(
                color: rosaClaro,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(opcoes.length, (index) {
                    final selecionado = _abaSelecionada == index;
                    return GestureDetector(
                      onTap: () => setState(() => _abaSelecionada = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selecionado ? rosaPrincipal : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: rosaPrincipal),
                        ),
                        child: Text(
                          opcoes[index],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selecionado ? Colors.white : rosaTexto,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (!_mesmoDia(_dataSelecionada, DateTime.now()))
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _dataSelecionada = DateTime.now();
                        _abaSelecionada = 0;
                      });
                    },
                    icon: const Icon(Icons.today, color: rosaTexto),
                    label: const Text(
                      'Voltar para Hoje',
                      style: TextStyle(color: rosaTexto, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Container(
              color: rosaClaro,
              child: _filtrar().isEmpty
                  ? const Center(child: Text('Nenhum agendamento'))
                  : ListView(
                      children: _filtrar().map((a) {
                        final data = DateTime.parse(a['data_hora']);
                        final formatada = DateFormat('dd/MM/yyyy HH:mm').format(data);
                        final nome = a['nome_cliente'] ?? a['nome_livre'] ?? 'Sem cadastro';
                        final valor = (a['valor'] as num).toDouble();

                        return Dismissible(
                          key: ValueKey(a['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            padding: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
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
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const Icon(Icons.favorite, color: rosaPrincipal),
                              title: Text(
                                nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: rosaTexto,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Data: $formatada',
                                    style: const TextStyle(color: rosaTexto),
                                  ),
                                  Text(
                                    'Valor: R\$ ${valor.toStringAsFixed(2)}',
                                    style: const TextStyle(color: rosaTexto),
                                  ),
                                ],
                              ),
                              trailing: a['pago'] == 1
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                              onTap: () => _mostrarOpcoes(context, a),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarCriarAgendamento,
        backgroundColor: rosaPrincipal,
        shape: const CircleBorder(),
        tooltip: 'Novo Agendamento',
        child: const Icon(Icons.favorite, color: Colors.white),
      ),
    );
  }
}
