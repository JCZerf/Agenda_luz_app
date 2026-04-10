class Atendimento {
  int? id;
  int? clienteId;
  String nomeLivre;
  DateTime dataHora;
  double valor;
  bool pago;
  bool concluido;
  String? observacoes;
  int? servicoId;
  int? tempoEstimadoMinutos;

  Atendimento({
    this.id,
    this.clienteId,
    required this.nomeLivre,
    required this.dataHora,
    required this.valor,
    this.pago = false,
    this.concluido = false,
    this.observacoes,
    this.servicoId,
    this.tempoEstimadoMinutos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'nome_livre': nomeLivre,
      'data_hora': dataHora.toIso8601String(),
      'valor': valor,
      'pago': pago ? 1 : 0,
      'concluido': concluido ? 1 : 0,
      'observacoes': observacoes,
      'servico_id': servicoId,
      'tempo_estimado_minutos': tempoEstimadoMinutos,
    };
  }

  factory Atendimento.fromMap(Map<String, dynamic> map) {
    return Atendimento(
      id: map['id'],
      clienteId: map['cliente_id'] != null ? map['cliente_id'] as int : null,
      nomeLivre: map['nome_livre'],
      dataHora: DateTime.parse(map['data_hora']),
      valor: map['valor'] is int ? (map['valor'] as int).toDouble() : map['valor'],
      pago: map['pago'] == 1,
      concluido: map['concluido'] == 1,
      observacoes: map['observacoes'],
      servicoId: map['servico_id'],
      tempoEstimadoMinutos: map['tempo_estimado_minutos'],
    );
  }

  Atendimento copyWith({
    int? id,
    int? clienteId,
    String? nomeLivre,
    DateTime? dataHora,
    double? valor,
    bool? pago,
    bool? concluido,
    String? observacoes,
    int? servicoId,
    int? tempoEstimadoMinutos,
  }) {
    return Atendimento(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      nomeLivre: nomeLivre ?? this.nomeLivre,
      dataHora: dataHora ?? this.dataHora,
      valor: valor ?? this.valor,
      pago: pago ?? this.pago,
      concluido: concluido ?? this.concluido,
      observacoes: observacoes ?? this.observacoes,
      servicoId: servicoId ?? this.servicoId,
      tempoEstimadoMinutos: tempoEstimadoMinutos ?? this.tempoEstimadoMinutos,
    );
  }

  // Verifica se este atendimento deve ser marcado como concluído automaticamente
  bool get deveSerConcluido {
    final agora = DateTime.now();
    final duasHorasDepois = dataHora.add(const Duration(hours: 2));
    return agora.isAfter(duasHorasDepois);
  }
}
