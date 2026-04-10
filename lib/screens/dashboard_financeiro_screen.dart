import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/app_colors.dart';

class DashboardFinanceiroScreen extends StatefulWidget {
  const DashboardFinanceiroScreen({super.key});

  @override
  State<DashboardFinanceiroScreen> createState() => _DashboardFinanceiroScreenState();
}

class _DashboardFinanceiroScreenState extends State<DashboardFinanceiroScreen> {
  DateTime _mesAtual = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> _estatisticas = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    
    final stats = await DatabaseHelper().obterEstatisticasFinanceiras(_mesAtual);
    
    setState(() {
      _estatisticas = stats;
      _carregando = false;
    });
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + delta);
    });
    _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rosaFundoGeral,
      appBar: AppBar(
        backgroundColor: AppColors.textoEscuro,
        title: const Text(
          'Dashboard Financeiro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seletor de Mês
                    _buildSeletorMes(),
                    
                    const SizedBox(height: 16),
                    
                    // Cards Principais
                    _buildCardsPrincipais(),
                    
                    const SizedBox(height: 20),
                    
                    // Comparativo com mês anterior
                    _buildComparativoMesAnterior(),
                    
                    const SizedBox(height: 20),
                    
                    // Análise de Atendimentos
                    _buildAnaliseAtendimentos(),
                    
                    const SizedBox(height: 20),
                    
                    // Top Serviços
                    _buildTopServicos(),
                    
                    const SizedBox(height: 20),
                    
                    // Métricas de Desempenho
                    _buildMetricasDesempenho(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeletorMes() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _mudarMes(-1),
            color: AppColors.textoEscuro,
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
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _mudarMes(1),
            color: AppColors.textoEscuro,
          ),
        ],
      ),
    );
  }

  Widget _buildCardsPrincipais() {
    final receita = _estatisticas['receita'] ?? 0.0;
    final despesa = _estatisticas['despesa'] ?? 0.0;
    final saldo = receita - despesa;
    final previsao = _estatisticas['previsao_receita'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCardMetrica(
                  'Receita',
                  'R\$ ${receita.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardMetrica(
                  'Despesas',
                  'R\$ ${despesa.toStringAsFixed(2)}',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCardMetrica(
                  'Saldo',
                  'R\$ ${saldo.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  saldo >= 0 ? Colors.blue : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardMetrica(
                  'Previsão',
                  'R\$ ${previsao.toStringAsFixed(2)}',
                  Icons.schedule,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardMetrica(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativoMesAnterior() {
    final receitaAtual = _estatisticas['receita'] ?? 0.0;
    final receitaAnterior = _estatisticas['receita_mes_anterior'] ?? 0.0;
    final atendimentosAtual = _estatisticas['total_atendimentos'] ?? 0;
    final atendimentosAnterior = _estatisticas['atendimentos_mes_anterior'] ?? 0;

    final variacaoReceita = receitaAnterior > 0
        ? ((receitaAtual - receitaAnterior) / receitaAnterior) * 100
        : 0.0;
    
    final variacaoAtendimentos = atendimentosAnterior > 0
        ? ((atendimentosAtual - atendimentosAnterior) / atendimentosAnterior) * 100
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: AppColors.rosaPrincipal),
                const SizedBox(width: 8),
                const Text(
                  'Comparativo com mês anterior',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildItemComparativo(
              'Receita',
              receitaAtual,
              receitaAnterior,
              variacaoReceita,
            ),
            const Divider(height: 24),
            _buildItemComparativo(
              'Atendimentos',
              atendimentosAtual.toDouble(),
              atendimentosAnterior.toDouble(),
              variacaoAtendimentos,
              isValor: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemComparativo(
    String label,
    double valorAtual,
    double valorAnterior,
    double variacao, {
    bool isValor = true,
  }) {
    final isPositivo = variacao >= 0;
    final cor = isPositivo ? Colors.green : Colors.red;
    final icone = isPositivo ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isValor
                  ? 'R\$ ${valorAtual.toStringAsFixed(2)}'
                  : valorAtual.toInt().toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textoEscuro,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 4),
              Text(
                '${variacao.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnaliseAtendimentos() {
    final totalAtendimentos = _estatisticas['total_atendimentos'] ?? 0;
    final atendimentosConcluidos = _estatisticas['atendimentos_concluidos'] ?? 0;
    final atendimentosPendentes = _estatisticas['atendimentos_pendentes'] ?? 0;
    final clientesAtendidos = _estatisticas['clientes_atendidos'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.rosaPrincipal),
                const SizedBox(width: 8),
                const Text(
                  'Análise de Atendimentos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    'Total',
                    totalAtendimentos.toString(),
                    Icons.calendar_month,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    'Concluídos',
                    atendimentosConcluidos.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    'Pendentes',
                    atendimentosPendentes.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    'Clientes',
                    clientesAtendidos.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServicos() {
    final topServicos = _estatisticas['top_servicos'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: AppColors.rosaPrincipal),
                const SizedBox(width: 8),
                const Text(
                  'Top Serviços do Mês',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topServicos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhum serviço realizado neste mês',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...topServicos.asMap().entries.map((entry) {
                final index = entry.key;
                final servico = entry.value;
                return _buildItemServico(
                  index + 1,
                  servico['nome'] ?? 'Sem nome',
                  servico['quantidade'] ?? 0,
                  servico['receita'] ?? 0.0,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemServico(int posicao, String nome, int quantidade, double receita) {
    final cores = [
      Colors.amber,
      Colors.grey[400]!,
      Colors.brown[300]!,
      Colors.blue[300]!,
    ];
    final cor = posicao <= 3 ? cores[posicao - 1] : Colors.grey[300]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rosaClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$posicao°',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textoEscuro,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantidade atendimento${quantidade != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${receita.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasDesempenho() {
    final ticketMedio = _estatisticas['ticket_medio'] ?? 0.0;
    final taxaConclusao = _estatisticas['taxa_conclusao'] ?? 0.0;
    final mediaDiariaReceita = _estatisticas['media_diaria_receita'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.rosaPrincipal, AppColors.rosaMedio],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.rosaPrincipal.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Métricas de Desempenho',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricaItem(
              'Ticket Médio',
              'R\$ ${ticketMedio.toStringAsFixed(2)}',
              Icons.receipt_long,
            ),
            const Divider(color: Colors.white38, height: 24),
            _buildMetricaItem(
              'Taxa de Conclusão',
              '${taxaConclusao.toStringAsFixed(1)}%',
              Icons.check_circle_outline,
            ),
            const Divider(color: Colors.white38, height: 24),
            _buildMetricaItem(
              'Média Diária',
              'R\$ ${mediaDiariaReceita.toStringAsFixed(2)}',
              Icons.today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaItem(String label, String valor, IconData icone) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
