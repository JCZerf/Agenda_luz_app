import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/movimentacao_financeira.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  List<MovimentacaoFinanceira> _movimentacoes = [];
  DateTime _mesAtual = DateTime(DateTime.now().year, DateTime.now().month);
  double _previsaoReceita = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarMovimentacoes();
    _carregarPrevisaoReceita();
  }

  Future<void> _carregarMovimentacoes() async {
    final dados = await DatabaseHelper().listarMovimentacoes();
    setState(() {
      _movimentacoes = dados;
    });
  }

  Future<void> _carregarPrevisaoReceita() async {
    final previsao = await DatabaseHelper().calcularPrevisaoReceita(mes: _mesAtual);
    setState(() {
      _previsaoReceita = previsao;
    });
  }

  List<MovimentacaoFinanceira> _filtrarPorMes(List<MovimentacaoFinanceira> lista) {
    return lista
        .where((m) => m.data.year == _mesAtual.year && m.data.month == _mesAtual.month)
        .toList();
  }

  Future<bool?> _confirmarExclusao(MovimentacaoFinanceira m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir movimentação'),
        content: const Text('Deseja realmente excluir esta movimentação?'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            child: const Text('Excluir'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper().deletarMovimentacao(m.id!);
      await _carregarMovimentacoes();
      await _carregarPrevisaoReceita();
      return true;
    }

    return false;
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + delta);
    });
    _carregarPrevisaoReceita();
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = _filtrarPorMes(_movimentacoes);
    const rosaTexto = Color(0xFF8A4B57);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaTexto,
        title: const Text(
          'Financeiro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: rosaTexto),
                  onPressed: () => _mudarMes(-1),
                ),
                Text(
                  toBeginningOfSentenceCase(
                    DateFormat('MMMM \'de\' y', 'pt_BR').format(_mesAtual),
                  )!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: rosaTexto,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: rosaTexto),
                  onPressed: () => _mudarMes(1),
                ),
              ],
            ),
          ),
          _ResumoFinanceiroCard(movimentacoes: listaFiltrada, previsaoReceita: _previsaoReceita),
          const SizedBox(height: 16),
          Expanded(
            child: listaFiltrada.isEmpty
                ? const Center(child: Text('Nenhuma movimentação encontrada.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: listaFiltrada.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final m = listaFiltrada[index];
                      final cor = m.isReceita ? Colors.green[700]! : Colors.red[700]!;
                      final data = DateFormat('dd/MM/yyyy').format(m.data);

                      final card = Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: ListTile(
                          onTap: m.origem == 'manual'
                              ? () async {
                                  final resultado = await Navigator.pushNamed(
                                    context,
                                    '/nova_movimentacao',
                                    arguments: {'modo': 'editar', 'movimentacao': m},
                                  );
                                  if (resultado == true) {
                                    await _carregarMovimentacoes();
                                    await _carregarPrevisaoReceita();
                                  }
                                }
                              : null,
                          title: Text(
                            m.descricao,
                            style: const TextStyle(
                              color: rosaTexto,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '$data • ${m.origem}',
                            style: const TextStyle(color: rosaTexto),
                          ),
                          trailing: Text(
                            '${m.isReceita ? '+' : '-'}R\$ ${m.valor.toStringAsFixed(2)}',
                            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );

                      if (m.origem == 'manual') {
                        return Dismissible(
                          key: ValueKey(m.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            padding: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) => _confirmarExclusao(m),
                          child: card,
                        );
                      } else {
                        return card;
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.pushNamed(context, '/nova_movimentacao');
          if (resultado == true) {
            await _carregarMovimentacoes();
            await _carregarPrevisaoReceita();
          }
        },
        backgroundColor: rosaTexto,
        child: const Icon(Icons.attach_money, color: Colors.white),
      ),
    );
  }
}

class _ResumoFinanceiroCard extends StatelessWidget {
  final List<MovimentacaoFinanceira> movimentacoes;
  final double previsaoReceita;

  const _ResumoFinanceiroCard({required this.movimentacoes, required this.previsaoReceita});

  @override
  Widget build(BuildContext context) {
    final receitaTotal = movimentacoes.where((m) => m.isReceita).fold(0.0, (s, m) => s + m.valor);
    final despesaTotal = movimentacoes.where((m) => !m.isReceita).fold(0.0, (s, m) => s + m.valor);
    final saldo = receitaTotal - despesaTotal;

    const rosaTexto = Color(0xFF8A4B57);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            _ResumoItem(label: 'Receita', valor: receitaTotal, cor: Colors.green[700]!),
            _ResumoItem(label: 'Despesas', valor: despesaTotal, cor: Colors.red[700]!),
            const Divider(),
            _ResumoItem(label: 'Saldo Líquido', valor: saldo, cor: rosaTexto, destaque: true),
            if (previsaoReceita > 0) ...[
              const SizedBox(height: 8),
              _ResumoItem(
                label: 'Previsão de Receita',
                valor: previsaoReceita,
                cor: Colors.blue[700]!,
                destaque: false,
                icone: Icons.trending_up,
              ),
            ],
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
  final IconData? icone;

  const _ResumoItem({
    required this.label,
    required this.valor,
    required this.cor,
    this.destaque = false,
    this.icone,
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
          Row(
            children: [
              if (icone != null) ...[Icon(icone, color: cor, size: 20), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text('R\$ ${valor.toStringAsFixed(2)}', style: estilo),
        ],
      ),
    );
  }
}
