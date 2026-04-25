import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  // Chave constante para evitar erros de digitação
  static const String _tokenKey = 'user_uuid_token';

  /// Salva o UUID localmente
  Future<void> saveToken(String uuid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, uuid);
  }

  /// Recupera o token guardado. Retorna null se não houver token.
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Remove o token (útil para Logout)
  Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}