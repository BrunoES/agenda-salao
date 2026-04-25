import 'dart:convert';
import 'package:agenda_salao/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSetupPage extends StatefulWidget {
  // Novo parâmetro recebido do login ou da tela anterior
  final String businessEmail;

 BusinessSetupPage({
    super.key,
    required this.businessEmail,
  });

  @override
  State<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends State<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  
  // Controller para o e-mail (iniciado com o valor recebido)
  late final TextEditingController _emailController;
  
  bool _isLoading = false; // Controle de estado para o botão

  // Mantendo o padrão de cores da Landing Page
  final Color primaryPink = const Color.fromRGBO(233, 113, 207, 0.85);
  final Color creamWhite = const Color.fromARGB(255, 253, 253, 247);

  @override
  void initState() {
    super.initState();
    // Inicializamos o controller com o e-mail passado por parâmetro
    _emailController = TextEditingController(text: widget.businessEmail);
  }

  Future<void> _handleContinue() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      /*
      // Chamada direta ao Supabase
      await Supabase.instance.client.from('estabelecimentos').insert({
        'nome': _businessNameController.text,
        'usuario_id': Supabase.instance.client.auth.currentUser?.id,
      });

      if (!mounted) return;
      
      // Redireciona para o Dashboard após o insert bem-sucedido
      Navigator.pushReplacementNamed(context, '/dashboard');
      */

      DatabaseService.cadastrarEstabelecimento(
        _businessNameController.text,
        _emailController.text, // Gerando um email fictício
      ).then((_) {
        if (!mounted) return;
        // Navigator.pushReplacementNamed(context, '/dashboard');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      });
      
    } on PostgrestException catch (error) {
      // Captura erros específicos do banco de dados (ex: nome duplicado)
      _showErrorSnackBar(error.message);
    } catch (error) {
      _showErrorSnackBar('Ocorreu um erro inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Ajusta a largura do card dependendo do dispositivo
              double cardWidth = constraints.maxWidth > 600 ? 500 : double.infinity;

              return Container(
                width: cardWidth,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícone de identificação
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryPink.withOpacity(0.1),
                        child: Icon(Icons.storefront_rounded, size: 40, color: primaryPink),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Falta pouco!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryPink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Como devemos chamar o seu estabelecimento?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                      
                      // Campo de Nome do Negócio
                      TextFormField(
                        controller: _businessNameController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Nome do Negócio',
                          hintText: 'Ex: Clínica Florescer, Barber Shop...',
                          labelStyle: TextStyle(color: primaryPink),
                          filled: true,
                          fillColor: creamWhite.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryPink),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryPink, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o nome do seu negócio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botão Continuar
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleContinue, // Desabilita se estiver carregando
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPink,
                            // ... estilos anteriores
                          ),
                          child: _isLoading 
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Finalizar Configuração'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}