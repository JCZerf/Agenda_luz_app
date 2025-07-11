class Agendamento {
  final int? id;
  final int? clienteId; // null se sem cadastro
  final String nomeCliente; // se for sem cadastro
  final DateTime dataHora;
  final double valor;
  final bool pago;
  final String? observacoes;

  Agendamento({
    this.id,
    this.clienteId,
    required this.nomeCliente,
    required this.dataHora,
    required this.valor,
    required this.pago,
    this.observacoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'nome_cliente': nomeCliente,
      'data_hora': dataHora.toIso8601String(),
      'valor': valor,
      'pago': pago ? 1 : 0,
      'observacoes': observacoes,
    };
  }

  factory Agendamento.fromMap(Map<String, dynamic> map) {
    return Agendamento(
      id: map['id'],
      clienteId: map['cliente_id'],
      nomeCliente: map['nome_cliente'],
      dataHora: DateTime.parse(map['data_hora']),
      valor: map['valor'],
      pago: map['pago'] == 1,
      observacoes: map['observacoes'],
    );
  }
}
