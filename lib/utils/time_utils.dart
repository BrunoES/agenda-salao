import '../models/appointment.dart';

bool hasConflict(Appointment novo, List<Appointment> lista) {
  for (var existente in lista) {
    final inicioA = existente.inicio;
    final fimA = existente.fim;

    final inicioB = novo.inicio;
    final fimB = novo.fim;

    final conflito = inicioB.isBefore(fimA) && fimB.isAfter(inicioA);

    if (conflito) return true;
  }
  return false;
}