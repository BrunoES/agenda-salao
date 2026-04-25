import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/business_setup_business.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/token_storage_service.dart';
// import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Obrigatório para plugins nativos
  // await NotificationService.initialize(); // Chamada do seu método

  // 2. Inicializa o Supabase
  await Supabase.initialize(
    url: 'https://jrwmbugohokkvmlzkzny.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impyd21idWdvaG9ra3ZtbHprem55Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMjYyMjMsImV4cCI6MjA5MjcwMjIyM30.tqZv1W8Ucf7uMt3JbMMPTorjB_6OsXHFCrQgYR4Oz5k',
    // Opcional: Configuração de persistência de sessão (padrão é true)
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

// Configuração inicial do Google Sign-In para Web
// O clientId é obtido no Google Cloud Console
GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: '30402395063-5nob2p2r72dcpha158abp3c0mrug64k9.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);


/*
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salão Agenda',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const HomeScreen(),
    );
  }
}
*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 253, 252, 237),
        useMaterial3: true,
      ),
      // Aqui acontece a mágica
      home: FutureBuilder<String?>(
        future: TokenStorageService().getToken(), // Chama o método assíncrono
        builder: (context, snapshot) {
          
          // 1. Enquanto está buscando o dado (loading)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color.fromARGB(255, 253, 252, 237), // Branco creme
              child: Center(
                child: Icon(Icons.calendar_month, size: 80, color: Color.fromRGBO(233, 113, 207, 0.85)),
              ),
            );
          }

          // 2. Se encontrou um token (usuário já logado/configurado)
          if (snapshot.hasData && snapshot.data != null) {
            // Se o token existe, mandamos para o Dashboard (ou tela interna)
            return const HomeScreen(); 
          }

          // 3. Se não encontrou nada ou deu erro, vai para a Landing Page
          return const LandingPage();
        },
      ),
    );
    
    /*
    final storage = TokenStorageService();
    final isAuthenticated = storage.getToken().then(
      (token) => {
        print('Token recuperado: $token'),
        if(token != null) {
          true
        } else {
          false
        }
      }
    );
    */
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // Cor principal definida (RGB 233, 113, 207 com 85% opacidade)
  Color get primaryPink => Color.fromRGBO(233, 113, 207, 0.85);
  Color get creamWhite => const Color.fromARGB(255, 248, 248, 238);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Agendamento Pro',
          style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              onPressed: () => _showLoginModal(context),
              child: Text('Login', style: TextStyle(color: primaryPink)),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  // Layout para Desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: _buildHeroText(context, true),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: primaryPink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.calendar_month, size: 200, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Layout para Mobile
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            color: primaryPink,
            child: const Icon(Icons.calendar_month, size: 100, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: _buildHeroText(context, false),
          ),
        ],
      ),
    );
  }

  // Conteúdo de texto e chamadas
  Widget _buildHeroText(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Gestão Completa para sua Clínica',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 48 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Agendamentos online, gestão de profissionais e notificações automáticas via WhatsApp para seus clientes.',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => _showLoginModal(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPink,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Começar Agora', style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ],
    );
  }

  // Modal de Login Social
  void _showLoginModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: creamWhite,
        title: const Text('Entrar no Sistema', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _socialButton(
              label: 'Continuar com Google',
              icon: Icons.g_mobiledata,
              color: Colors.redAccent,
              onPressed: () => _handleGoogleSignIn(context), // Chamada da função
            ),
            /*
            const SizedBox(height: 12),
            _socialButton(
              label: 'Continuar com Facebook',
              icon: Icons.facebook,
              color: Colors.blueAccent,
              onPressed: () {
                // Navegação para suas telas de Flutter
              },
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _socialButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: color),
        label: Text(label, style: const TextStyle(color: Colors.black87)),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // Método que gerencia o login
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // Inicia o processo de autenticação
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user != null) {
        // Login bem-sucedido! 
        // Aqui você pode capturar dados como: user.displayName, user.email, user.photoUrl
        
        if (!context.mounted) return;

        // Exemplo dentro do seu método de login:
        final userEmail = user.email; // Valor dinâmico obtido do login
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessSetupPage(businessEmail: userEmail),
          ),
        );
      }
    } catch (error) {
      print('Erro no login Google: $error');
      // Adicione um alerta para o usuário se necessário
    }
  }
}
