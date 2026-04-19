import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';

class StorageService {
  static const key = 'appointments';

  static Future<List<Appointment>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);

    if (data == null) return [];

    final list = jsonDecode(data) as List;

    return list
        .map(
          (a) => Appointment(
            id: a['id'],
            cliente: a['cliente'],
            servico: a['servico'],
            inicio: DateTime.parse(a['inicio']),
            duracao: a['duracao'],
          ),
        )
        .toList();
  }

  static Future<void> save(List<Appointment> list) async {
    final prefs = await SharedPreferences.getInstance();

    final data = list
        .map(
          (a) => {
            'id': a.id,
            'cliente': a.cliente,
            'servico': a.servico,
            'inicio': a.inicio.toIso8601String(),
            'duracao': a.duracao,
          },
        )
        .toList();

    await prefs.setString(key, jsonEncode(data));
  }

  // 🔥 NOVO: salvar 1 item diretamente (IMPORTANTE)
  static Future<void> add(Appointment appointment) async {
    final list = await load();

    list.removeWhere((a) => a.id == appointment.id);
    list.add(appointment);

    await save(list);
  }

  static Future<void> delete(String id) async {
    final list = await load();
    list.removeWhere((a) => a.id == id);
    await save(list);
  }

  static bool hasConflict(List<Appointment> list, Appointment newAppt) {
    final newStart = newAppt.inicio;
    final newEnd = newAppt.inicio.add(Duration(minutes: newAppt.duracao));

    for (final a in list) {
      // ignora o próprio registro (edição)
      if (a.id == newAppt.id) continue;

      final existingStart = a.inicio;
      final existingEnd = a.inicio.add(Duration(minutes: a.duracao));

      // 🔥 compara apenas mesmo dia
      final sameDay =
          existingStart.year == newStart.year &&
          existingStart.month == newStart.month &&
          existingStart.day == newStart.day;

      if (!sameDay) continue;

      // 🔥 REGRA DE INTERSECÇÃO (robusta)
      final intersects =
          newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);

      if (intersects) return true;
    }

    return false;
  }
}
