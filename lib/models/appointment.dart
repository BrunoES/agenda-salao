class Appointment {
  final String id;
  final String cliente;
  final String servico;
  final DateTime inicio;
  final int duracao;

  Appointment({
    required this.id,
    required this.cliente,
    required this.servico,
    required this.inicio,
    required this.duracao,
  });

  DateTime get fim => inicio.add(Duration(minutes: duracao));

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente': cliente,
        'servico': servico,
        'inicio': inicio.toIso8601String(),
        'duracao': duracao,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      cliente: json['cliente'],
      servico: json['servico'],
      inicio: DateTime.parse(json['inicio']),
      duracao: json['duracao'],
    );
  }
}