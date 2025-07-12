import 'package:AgendaLuz/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/atendimento.dart';

class AtendimentosScreen extends StatefulWidget {
  const AtendimentosScreen({super.key});

  @override
  State<AtendimentosScreen> createState() => _AtendimentosScreenState();
}

class _AtendimentosScreenState extends State<AtendimentosScreen> {
  List<Map<String, dynamic>> _concluidos = [];

  @override
  void initState() {
    super.initState();
    _carregarAtendimentosConcluidos();
  }

  Future<void> _carregarAtendimentosConcluidos() async {
    final todos = await DatabaseHelper().listarAtendimentosComNomeCliente();
    final apenasConcluidos = todos.where((a) => a['concluido'] == 1).toList();
    setState(() {
      _concluidos = apenasConcluidos;
    });
  }

  void _mostrarOpcoes(Map<String, dynamic> agendamento) {
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
              _mostrarDetalhes(agendamento);
            },
          ),
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Desmarcar como concluído'),
            onTap: () async {
              Navigator.pop(context);
              final atendimento = Atendimento.fromMap(agendamento);
              atendimento.concluido = false;
              await DatabaseHelper().atualizarAtendimento(atendimento);
              _carregarAtendimentosConcluidos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atendimento desmarcado como concluído')),
              );
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
              ).then((_) => _carregarAtendimentosConcluidos());
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
                  title: const Text('Excluir Atendimento'),
                  content: const Text('Deseja realmente excluir este atendimento?'),
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
                _carregarAtendimentosConcluidos();
              }
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhes(Map<String, dynamic> a) {
    final data = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(a['data_hora']));
    final valor = (a['valor'] as num).toDouble();
    final nome = a['nome_livre'] ?? 'Cliente';
    final pago = a['pago'] == 1;
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

  @override
  Widget build(BuildContext context) {
    const rosa = Color(0xFFD9A7B0);
    const rosaClaro = Color(0xFFFFF1F3);
    const rosaTexto = Color(0xFF8A4B57);

    return Scaffold(
      appBar: AppBar(title: const Text('Atendimentos')),
      body: Container(
        color: rosaClaro,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de atendimentos concluídos: ${_concluidos.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: rosaTexto),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _concluidos.isEmpty
                  ? const Center(child: Text('Nenhum atendimento concluído ainda.'))
                  : ListView.builder(
                      itemCount: _concluidos.length,
                      itemBuilder: (context, index) {
                        final a = _concluidos[index];
                        final data = DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(DateTime.parse(a['data_hora']));
                        final nome = a['nome_cliente'] ?? a['nome_livre'] ?? 'Sem cadastro';

                        return GestureDetector(
                          onTap: () => _mostrarOpcoes(a),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const Icon(Icons.check_circle, color: rosa),
                              title: Text(
                                nome,
                                style: const TextStyle(
                                  color: rosaTexto,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Data: $data',
                                style: const TextStyle(color: rosaTexto),
                              ),
                              trailing: const Icon(Icons.more_vert, color: rosaTexto),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
