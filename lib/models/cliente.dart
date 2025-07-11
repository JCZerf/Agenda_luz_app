class Cliente {
  int? id;
  String nome;
  String telefone;
  String observacoes;
  String historico;

  Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    required this.observacoes,
    required this.historico,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'observacoes': observacoes,
      'historico': historico,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nome: map['nome'],
      telefone: map['telefone'],
      observacoes: map['observacoes'],
      historico: map['historico'],
    );
  }
}
