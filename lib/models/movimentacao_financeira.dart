class MovimentacaoFinanceira {
  final int? id;
  final String tipo; // 'receita' ou 'despesa'
  final double valor;
  final String descricao;
  final DateTime data;
  final String origem; // 'manual' ou 'automatica'
  final int? atendimentoId; // nullable se origem for manual

  MovimentacaoFinanceira({
    this.id,
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.data,
    required this.origem,
    this.atendimentoId,
  });

  /// Getter de conveniência para saber se é receita
  bool get isReceita => tipo.toLowerCase() == 'receita';

  /// Conversão para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'valor': valor,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'origem': origem,
      'atendimento_id': atendimentoId,
    };
  }

  /// Conversão de Map para objeto Dart
  factory MovimentacaoFinanceira.fromMap(Map<String, dynamic> map) {
    return MovimentacaoFinanceira(
      id: map['id'] as int?,
      tipo: map['tipo'] as String,
      valor: map['valor'] is int ? (map['valor'] as int).toDouble() : map['valor'] as double,
      descricao: map['descricao'] as String,
      data: DateTime.parse(map['data'] as String),
      origem: map['origem'] as String,
      atendimentoId: map['atendimento_id'] as int?,
    );
  }
}
