import 'package:AgendaLuz/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimentacao_financeira.dart';

class MovimentacoesScreen extends StatefulWidget {
  const MovimentacoesScreen({super.key});

  @override
  State<MovimentacoesScreen> createState() => _MovimentacoesScreenState();
}

class _MovimentacoesScreenState extends State<MovimentacoesScreen> {
  List<MovimentacaoFinanceira> _movimentacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarMovimentacoes();
  }

  Future<void> _carregarMovimentacoes() async {
    final data = await DatabaseHelper().listarMovimentacoes();
    setState(() {
      _movimentacoes = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimentações')),
      body: _movimentacoes.isEmpty
          ? const Center(child: Text('Nenhuma movimentação registrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _movimentacoes.length,
              itemBuilder: (context, index) {
                final m = _movimentacoes[index];
                final cor = m.isReceita ? Colors.green : Colors.red;
                final dataFormatada = DateFormat('dd/MM/yyyy').format(m.data);

                return Card(
                  child: ListTile(
                    title: Text(m.descricao),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data: $dataFormatada'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Origem: '),
                            Chip(
                              label: Text(m.origem),
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${m.isReceita ? '+' : '-'}R\$ ${m.valor.toStringAsFixed(2)}',
                      style: TextStyle(color: cor, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/nova_movimentacao').then((_) => _carregarMovimentacoes());
        },
        child: const Icon(Icons.attach_money),
      ),
    );
  }
}
