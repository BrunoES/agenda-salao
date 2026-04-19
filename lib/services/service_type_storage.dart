import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_type.dart';

class ServiceTypeStorage {
  static const key = 'service_types';

  static Future<void> save(List<ServiceType> list) async {
    final prefs = await SharedPreferences.getInstance();

    final data = list
        .map((e) => {
              'id': e.id,
              'nome': e.nome,
              'duracaoPadrao': e.duracaoPadrao,
            })
        .toList();

    await prefs.setString(key, jsonEncode(data));
  }

  static Future<List<ServiceType>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(key);
    if (data == null) return [];

    final list = jsonDecode(data) as List;

    return list
        .map((e) => ServiceType(
              id: e['id'],
              nome: e['nome'],
              duracaoPadrao: e['duracaoPadrao'],
            ))
        .toList();
  }
}