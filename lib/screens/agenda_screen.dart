import 'package:agendaluz/database/database_helper.dart';
import 'package:agendaluz/models/atendimento.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _abaSelecionada = 0;
  final List<String> opcoes = ['Diário', 'Semanal', 'Mensal'];
  List<Map<String, dynamic>> _todos = [];

  @override
  void initState() {
    super.initState();
    carregarAgendamentos();
  }

  void carregarAgendamentos() async {
    final atendimentos = await DatabaseHelper().listarAtendimentosComNomeCliente();
    setState(() {
      _todos = atendimentos;
    });
  }

  List<Map<String, dynamic>> _filtrar() {
    final agora = DateTime.now();
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

  void _mostrarDetalhes(BuildContext context, Map<String, dynamic> a) {
    final data = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(a['data_hora']));
    final valor = (a['valor'] as num).toDouble();
    final nome = a['nome_cliente'] ?? 'Cliente não cadastrada';
    final pago = a['pago'] == 1;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalhes do Agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: $nome'),
            Text('Data/Hora: $data'),
            Text('Valor: R\$ ${valor.toStringAsFixed(2)}'),
            Text('Pago: ${pago ? 'Sim' : 'Não'}'),
            if (a['observacoes'] != null && a['observacoes'].toString().isNotEmpty)
              Text('Obs: ${a['observacoes']}'),
          ],
        ),
        actions: [TextButton(child: const Text('Fechar'), onPressed: () => Navigator.pop(context))],
      ),
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
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/agendamento',
                arguments: {'modo': 'editar', 'dados': agendamento},
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
        title: const Text(
          'AMANDA LUZ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
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
          Expanded(
            child: Container(
              color: rosaClaro,
              child: _filtrar().isEmpty
                  ? const Center(child: Text('Nenhum agendamento'))
                  : ListView(
                      children: _filtrar().map((a) {
                        final data = DateTime.parse(a['data_hora']);
                        final formatada = DateFormat('dd/MM/yyyy HH:mm').format(data);
                        final nome = a['nome_cliente'] ?? 'Sem cadastro';
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
                              onTap: () async {
                                final sucesso = await Navigator.pushNamed(
                                  context,
                                  '/agendamento',
                                  arguments: {
                                    'modo': a['cliente_id'] == null ? 'semCliente' : 'comCliente',
                                    'atendimento': Atendimento.fromMap(a),
                                  },
                                );
                                if (sucesso == true) {
                                  carregarAgendamentos();
                                }
                              },
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
