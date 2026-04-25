import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/storage_service.dart';
import '../services/service_type_storage.dart';
import '../services/token_storage_service.dart';
import '../screens/schedule_grid.dart';
import 'new_appointment_screen.dart';
import 'service_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  List<Appointment> allAppointments = [];
  DateTime selectedDate = DateTime.now();
  late final AnimationController _serviceIconController;
  late final Animation<double> _serviceIconAnimation;
  bool _highlightServiceButton = false;
  bool _highlightAppointmentButton = false;
  bool _firstAccess = false;

  @override
  void initState() {
    super.initState();
    _serviceIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _serviceIconAnimation = CurvedAnimation(
      parent: _serviceIconController,
      curve: Curves.easeInOut,
    );
    load();
    _checkFirstTime();
    _updateButtonHighlights();
    //_initNotifications();
  }

  /*
  Future<void> _initNotifications() async {
    await NotificationService.initialize();
  }
  */
  
  void _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('firstTime') ?? true;

    if (isFirstTime) {
      _firstAccess = true;
      _setButtonHighlight(service: true, appointment: false);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _showTutorialDialog();
      });
      await prefs.setBool('firstTime', false);
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bem-vindo à Agenda de Salão!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Para começar, toque no ícone "Tipos de atendimento" no topo da tela.',
                ),
                SizedBox(height: 12),
                Text(
                  'Adicione tipos de atendimento como: Corte, Pintura, Manicure, depois é só criar agendamentos!',
                ),
                SizedBox(height: 12),
                Text('É tudo salvo no seu dispositivo :D!'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  void load() async {
    final data = await StorageService.load();
    setState(() {
      allAppointments = data;
    });
    _updateButtonHighlights();
  }

  void _setButtonHighlight({required bool service, required bool appointment}) {
    final shouldHighlight = service || appointment;
    if (_highlightServiceButton == service &&
        _highlightAppointmentButton == appointment) {
      return;
    }

    setState(() {
      _highlightServiceButton = service;
      _highlightAppointmentButton = appointment;
    });

    if (shouldHighlight) {
      _serviceIconController.repeat(reverse: true);
    } else {
      _serviceIconController.stop();
      _serviceIconController.value = 0.0;
    }
  }

  void _updateButtonHighlights() async {
    final services = await ServiceTypeStorage.load();
    final appointments = await StorageService.load();
    if (!mounted) return;

    _setButtonHighlight(
      service: _firstAccess || services.isEmpty,
      appointment: services.isNotEmpty && appointments.isEmpty,
    );

    _firstAccess = false;
  }

  void _scrollToAppointment(Appointment appointment) {
    final hourHeight = ScheduleGrid.hourHeight;
    final minutesSinceSix =
        (appointment.inicio.hour - 6) * 60 + appointment.inicio.minute;
    final offset = (minutesSinceSix / 60) * hourHeight;

    if (_scrollController.hasClients) {
      final target = offset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void _loadAndScrollTo(Appointment appointment) async {
    final data = await StorageService.load();
    setState(() {
      selectedDate = DateTime(
        appointment.inicio.year,
        appointment.inicio.month,
        appointment.inicio.day,
      );
      allAppointments = data;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAppointment(appointment);
    });
  }

  void changeDay(int days) async {
    final newDate = selectedDate.add(Duration(days: days));

    final data = await StorageService.load();

    setState(() {
      selectedDate = newDate;
      allAppointments = data;
    });
  }

  Future pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final data = await StorageService.load();

      setState(() {
        selectedDate = picked;
        allAppointments = data;
      });
    }
  }

  void goToNew([Appointment? edit]) async {
    final currentContext = context;
    // Verifica se há tipos de atendimento cadastrados
    final services = await ServiceTypeStorage.load();
    if (services.isEmpty) {
      _showTutorialDialog();
      return;
    }

    // ignore: use_build_context_synchronously
    final result = await Navigator.push<Appointment?>(
      currentContext,
      MaterialPageRoute(
        builder: (_) => NewAppointmentScreen(
          existing: allAppointments,
          dataHora: edit?.inicio ?? selectedDate,
          edit: edit,
        ),
      ),
    );

    if (!mounted) return;
    _updateButtonHighlights();

    if (result != null) {
      _loadAndScrollTo(result);
    } else {
      load();
    }
  }

  void deleteAppointment(Appointment appointment) async {
    await StorageService.delete(appointment.id);
    load();
  }

  Widget _buildDrawer(BuildContext context) {
  final Color primaryPink = const Color.fromRGBO(233, 113, 207, 0.85);

  return Drawer(
    backgroundColor: const Color.fromARGB(255, 253, 252, 237),
    child: Column(
      children: [
        // Cabeçalho estilizado
        DrawerHeader(
          decoration: BoxDecoration(color: primaryPink),
          child: const Center(
            child: Icon(Icons.business, size: 50, color: Colors.white),
          ),
        ),
        
        // Itens de Navegação
        ListTile(
          leading: Icon(Icons.home, color: primaryPink),
          title: const Text('Início'),
          onTap: () => Navigator.pop(context),
        ),
        
        const Spacer(), // Empurra o logout para o final
        const Divider(),

        // Botão de Logout
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Sair', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          onTap: () async {
            // Limpa o token e volta para a tela de login
            await TokenStorageService().clearToken();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

  @override
  void dispose() {
    _scrollController.dispose();
    _serviceIconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');

    return Scaffold(
      resizeToAvoidBottomInset: true, // 🔥 evita quebra com teclado

      /*
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          TextButton.icon(
            icon: AnimatedBuilder(
              animation: _serviceIconAnimation,
              builder: (context, child) {
                final color = _highlightServiceButton
                    ? Color.lerp(
                        const Color.fromARGB(255, 233, 113, 207),
                        const Color.fromARGB(255, 43, 255, 0),
                        _serviceIconAnimation.value,
                      )
                    : const Color.fromARGB(255, 233, 113, 207);
                return Icon(Icons.add, size: 48, color: color);
              },
            ),
            label: const Text(
              'Tipos de atendimento',
              style: TextStyle(
                color: Color.fromARGB(255, 233, 113, 207),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ServiceScreen()),
              );
              _updateButtonHighlights();
            },
          ),
        ],
      ),
      */

      backgroundColor: const Color.fromARGB(255, 253, 252, 237), // Seu Branco Creme
    
      // Passo 1: Adicione o Drawer aqui
      drawer: _buildDrawer(context), 
      
      // Passo 2: Garanta que haja uma AppBar para o ícone aparecer
      appBar: AppBar(
        title: const Text('Início'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromRGBO(233, 113, 207, 0.85)),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => goToNew(),
        child: AnimatedBuilder(
          animation: _serviceIconAnimation,
          builder: (context, child) {
            final color = _highlightAppointmentButton
                ? Color.lerp(
                    const Color.fromARGB(255, 233, 113, 207),
                    const Color.fromARGB(255, 43, 255, 0),
                    _serviceIconAnimation.value,
                  )
                : const Color.fromARGB(255, 233, 113, 207);
            return Icon(Icons.add, size: 48, color: color);
          },
        ),
      ),

      // 🔥 CORREÇÃO PRINCIPAL: scroll global seguro
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              changeDay(-1);
            } else if (details.primaryVelocity! < 0) {
              changeDay(1);
            }
          },
          child: Column(
            children: [
              // 📅 controle de data fixo no topo
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => changeDay(-1),
                      icon: const Icon(Icons.arrow_back),
                    ),

                    GestureDetector(
                      onTap: pickDate,
                      child: Column(
                        children: [
                          Text(
                            format.format(selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Selecionar data",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () => changeDay(1),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),

              // 🔥 GRID ocupa espaço restante corretamente
              Expanded(
                child: ScheduleGrid(
                  allAppointments,
                  selectedDate: selectedDate,
                  onEdit: (a) => goToNew(a),
                  onDelete: (a) => deleteAppointment(a),
                  scrollController: _scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
