import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final supabase = Supabase.instance.client;

  static Future<void> cadastrarEstabelecimento(String name, String email) async {
    try {
      // O método insert aceita um Map<String, dynamic>
      // As chaves do Map devem ser EXATAMENTE iguais aos nomes das colunas no Postgres
      await supabase.from('empresa').insert({
        'name': name.trim(),
        'email': email.toLowerCase().trim().replaceAll(' ', '-'),
      });

      print('Negócio cadastrado com sucesso!');
    } catch (e) {
      // O Supabase lança exceções detalhadas se houver erro de permissão (RLS) ou conexão
      print('Erro ao inserir: $e');
      rethrow;
    }
  }
}