import 'package:supabase_flutter/supabase_flutter.dart';
import 'token_storage_service.dart';

class DatabaseService {
  static final supabase = Supabase.instance.client;

  static Future<void> cadastrarEstabelecimento(String name, String email) async {
    try {
      // O método insert aceita um Map<String, dynamic>
      // As chaves do Map devem ser EXATAMENTE iguais aos nomes das colunas no Postgres
      final data = await supabase.from('empresa').insert({
        'name': name.trim(),
        'email': email.toLowerCase().trim().replaceAll(' ', '-'),
      }).select().single();

      print('Negócio cadastrado com sucesso: ${data['id']}');
      final storage = TokenStorageService();
      storage.saveToken('${data['token']}');
      
    } catch (e) {
      // O Supabase lança exceções detalhadas se houver erro de permissão (RLS) ou conexão
      print('Erro ao inserir: $e');
      rethrow;
    }
  }
}