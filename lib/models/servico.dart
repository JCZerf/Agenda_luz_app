class Servico {
  final int? id;
  final String nome;
  final double valor;
  final double? custo;
  final int tempoMedioMinutos;
  final String? dataCriacao;

  Servico({
    this.id,
    required this.nome,
    required this.valor,
    this.custo,
    required this.tempoMedioMinutos,
    this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valor': valor,
      'custo': custo,
      'tempo_medio_minutos': tempoMedioMinutos,
      'data_criacao': dataCriacao ?? DateTime.now().toIso8601String(),
    };
  }

  factory Servico.fromMap(Map<String, dynamic> map) {
    return Servico(
      id: map['id'],
      nome: map['nome'],
      valor: map['valor'],
      custo: map['custo'],
      tempoMedioMinutos: map['tempo_medio_minutos'],
      dataCriacao: map['data_criacao'],
    );
  }

  Servico copyWith({
    int? id,
    String? nome,
    double? valor,
    double? custo,
    int? tempoMedioMinutos,
    String? dataCriacao,
  }) {
    return Servico(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      custo: custo ?? this.custo,
      tempoMedioMinutos: tempoMedioMinutos ?? this.tempoMedioMinutos,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
