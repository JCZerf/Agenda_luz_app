class Atendimento {
  int? id;
  int? clienteId;
  String? nomeLivre; // ← novo campo
  DateTime dataHora;
  double valor;
  bool pago;
  String? observacoes;

  Atendimento({
    this.id,
    this.clienteId,
    this.nomeLivre, // ← novo
    required this.dataHora,
    required this.valor,
    this.pago = false,
    this.observacoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'nome_livre': nomeLivre, // ← novo
      'data_hora': dataHora.toIso8601String(),
      'valor': valor,
      'pago': pago ? 1 : 0,
      'observacoes': observacoes,
    };
  }

  factory Atendimento.fromMap(Map<String, dynamic> map) {
    return Atendimento(
      id: map['id'],
      clienteId: map['cliente_id'],
      nomeLivre: map['nome_livre'], // ← novo
      dataHora: DateTime.parse(map['data_hora']),
      valor: (map['valor'] as num).toDouble(),
      pago: map['pago'] == 1,
      observacoes: map['observacoes'],
    );
  }
}
