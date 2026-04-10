class AtendimentoComCliente {
  final int id;
  final String? nomeCliente; // nome da tabela clientes
  final String? nomeLivre; // nome salvo direto no atendimento
  final DateTime dataHora;
  final double valor;
  final bool pago;
  final String? observacoes;

  AtendimentoComCliente({
    required this.id,
    this.nomeCliente,
    this.nomeLivre,
    required this.dataHora,
    required this.valor,
    required this.pago,
    this.observacoes,
  });

  String get nomeFinal => nomeCliente ?? nomeLivre ?? 'Sem nome';
}
