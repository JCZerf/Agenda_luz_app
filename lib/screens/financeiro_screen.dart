import 'package:AgendaLuz/database/database_helper.dart';
import 'package:AgendaLuz/screens/movimentacoes_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimentacao_financeira.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  List<MovimentacaoFinanceira> _movimentacoes = [];
  String _periodoSelecionado = 'mensal';

  @override
  void initState() {
    super.initState();
    _carregarMovimentacoes();
  }

  Future<void> _carregarMovimentacoes() async {
    final dados = await DatabaseHelper().listarMovimentacoes();
    setState(() {
      _movimentacoes = dados;
    });
  }

  List<MovimentacaoFinanceira> _filtrarPorPeriodo(List<MovimentacaoFinanceira> lista) {
    final agora = DateTime.now();
    Duration limite;

    switch (_periodoSelecionado) {
      case 'semanal':
        limite = const Duration(days: 7);
        break;
      case 'trimestral':
        limite = const Duration(days: 90);
        break;
      case 'mensal':
      default:
        limite = const Duration(days: 30);
        break;
    }

    return lista.where((m) => agora.difference(m.data).inDays <= limite.inDays).toList();
  }

  @override
  Widget build(BuildContext context) {
    const rosa = Color(0xFFD9A7B0);
    const rosaClaro = Color(0xFFFFF1F3);
    const rosaTexto = Color(0xFF8A4B57);

    final listaFiltrada = _filtrarPorPeriodo(_movimentacoes);

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: Container(
        color: rosaClaro,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _ResumoFinanceiroCard(movimentacoes: listaFiltrada),
            const SizedBox(height: 24),
            _PeriodoFiltro(
              valorAtual: _periodoSelecionado,
              onChange: (valor) {
                setState(() {
                  _periodoSelecionado = valor;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: listaFiltrada.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma movimentação encontrada.',
                        style: TextStyle(color: rosaTexto, fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      itemCount: listaFiltrada.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final m = listaFiltrada[index];
                        final cor = m.isReceita ? Colors.green[700]! : Colors.red[700]!;
                        final data = DateFormat('dd/MM/yyyy').format(m.data);
                        final origem = '${m.origem[0].toUpperCase()}${m.origem.substring(1)}';

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Icon(
                              m.isReceita ? Icons.arrow_upward : Icons.arrow_downward,
                              color: cor,
                            ),
                            title: Text(
                              m.descricao,
                              style: const TextStyle(
                                color: rosaTexto,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '$data • $origem',
                              style: const TextStyle(color: rosaTexto),
                            ),
                            trailing: Text(
                              'R\$ ${m.valor.toStringAsFixed(2)}',
                              style: TextStyle(color: cor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MovimentacoesScreen()),
          );
          if (resultado == true) {
            _carregarMovimentacoes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ResumoFinanceiroCard extends StatelessWidget {
  final List<MovimentacaoFinanceira> movimentacoes;

  const _ResumoFinanceiroCard({required this.movimentacoes});

  @override
  Widget build(BuildContext context) {
    final receitaTotal = movimentacoes
        .where((m) => m.isReceita)
        .fold(0.0, (soma, m) => soma + m.valor);
    final despesaTotal = movimentacoes
        .where((m) => !m.isReceita)
        .fold(0.0, (soma, m) => soma + m.valor);
    final saldo = receitaTotal - despesaTotal;

    const rosaTexto = Color(0xFF8A4B57);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            _ResumoItem(label: 'Receita', valor: receitaTotal, cor: Colors.green[700]!),
            _ResumoItem(label: 'Despesas', valor: despesaTotal, cor: Colors.red[700]!),
            const Divider(),
            _ResumoItem(label: 'Saldo Líquido', valor: saldo, cor: rosaTexto, destaque: true),
          ],
        ),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final double valor;
  final Color cor;
  final bool destaque;

  const _ResumoItem({
    required this.label,
    required this.valor,
    required this.cor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destaque ? 18 : 16,
      fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
      color: cor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('R\$ ${valor.toStringAsFixed(2)}', style: estilo),
        ],
      ),
    );
  }
}

class _PeriodoFiltro extends StatelessWidget {
  final String valorAtual;
  final Function(String) onChange;

  const _PeriodoFiltro({required this.valorAtual, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const rosaPrincipal = Color(0xFFD9A7B0);

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Período',
        filled: true,
        fillColor: const Color(0xFFFFF1F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: valorAtual,
      dropdownColor: Colors.white,
      iconEnabledColor: rosaPrincipal,
      items: const [
        DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
        DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
        DropdownMenuItem(value: 'trimestral', child: Text('Trimestral')),
      ],
      onChanged: (value) {
        if (value != null) onChange(value);
      },
    );
  }
}
