import '../utils/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.rosaFundoGeral,
      appBar: AppBar(
        backgroundColor: AppColors.textoEscuro,
        title: const Text(
          'Financeiro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard_financeiro');
            },
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.textoEscuro),
                        onPressed: () => _mudarMes(-1),
                      ),
                      Text(
                        toBeginningOfSentenceCase(
                          DateFormat('MMMM \'de\' y', 'pt_BR').format(_mesAtual),
                        )!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textoEscuro,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.textoEscuro),
                        onPressed: () => _mudarMes(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _ResumoFinanceiroCard(movimentacoes: listaFiltrada, previsaoReceita: _previsaoReceita),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Movimentações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                ),
                Text(
                  '${listaFiltrada.length} ${listaFiltrada.length == 1 ? 'item' : 'itens'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: listaFiltrada.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma movimentação encontrada',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione receitas ou despesas',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: listaFiltrada.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final m = listaFiltrada[index];
                      final cor = m.isReceita ? Colors.green[700]! : Colors.red[700]!;
                      final corFundo = m.isReceita ? Colors.green[50]! : Colors.red[50]!;
                      final icone = m.isReceita ? Icons.add_circle : Icons.remove_circle;
                      final data = DateFormat('dd/MM/yyyy').format(m.data);

                      final card = Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        child: InkWell(
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
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: corFundo,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icone, color: cor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.descricao,
                                        style: const TextStyle(
                                          color: AppColors.textoEscuro,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            data,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: m.origem == 'manual'
                                                  ? Colors.blue[50]
                                                  : Colors.purple[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              m.origem,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: m.origem == 'manual'
                                                    ? Colors.blue[700]
                                                    : Colors.purple[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${m.isReceita ? '+' : '-'}R\$ ${m.valor.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: cor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
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
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete, color: Colors.white, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Excluir',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.pushNamed(context, '/nova_movimentacao');
          if (resultado == true) {
            await _carregarMovimentacoes();
            await _carregarPrevisaoReceita();
          }
        },
        backgroundColor: AppColors.textoEscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Movimentação', style: TextStyle(color: Colors.white)),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.rosaPrincipal, AppColors.rosaMedio],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.rosaPrincipal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo do Mês',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'R\$ ${saldo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(color: Colors.white38, height: 1),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResumoItemCompact(
                  'Receitas',
                  receitaTotal,
                  Icons.arrow_upward,
                  Colors.green[300]!,
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white38,
                ),
                _buildResumoItemCompact(
                  'Despesas',
                  despesaTotal,
                  Icons.arrow_downward,
                  Colors.red[300]!,
                ),
                if (previsaoReceita > 0) ...[
                  Container(
                    width: 1,
                    height: 35,
                    color: Colors.white38,
                  ),
                  _buildResumoItemCompact(
                    'Previsão',
                    previsaoReceita,
                    Icons.schedule,
                    Colors.amber[300]!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItemCompact(String label, double valor, IconData icone, Color cor) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'R\$ ${valor.toStringAsFixed(0)}',
          style: TextStyle(
            color: cor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
