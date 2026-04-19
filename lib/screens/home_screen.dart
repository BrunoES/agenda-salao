import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/storage_service.dart';
import '../services/service_type_storage.dart';
import '../screens/schedule_grid.dart';
import 'new_appointment_screen.dart';
import 'service_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Appointment> allAppointments = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    load();
    _checkFirstTime();
  }

  void _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('firstTime') ?? true;

    if (isFirstTime) {
    //if (true) {
      // 🔥 FORÇAR SEMPRE PARA TESTAR O TUTORIAL
      // Aguarda um pouco para garantir que o contexto esteja pronto
      Future.delayed(const Duration(milliseconds: 500), () {
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
                Text('Para começar, toque no ícone "Tipos de atendimento" no topo da tela.'),
                SizedBox(height: 12),
                Text('Adicione tipos de atendimento como: Corte, Pintura, Manicure, depois é só criar agendamentos!'),
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
    allAppointments = await StorageService.load();
    setState(() {
      selectedDate = selectedDate;
      allAppointments = allAppointments;
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
    // Verifica se há tipos de atendimento cadastrados
    final services = await ServiceTypeStorage.load();
    if (services.isEmpty) {
      _showTutorialDialog();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewAppointmentScreen(
          existing: allAppointments,
          dataHora: edit?.inicio ?? selectedDate,
          edit: edit,
        ),
      ),
    );
    load();
  }

  void deleteAppointment(Appointment appointment) async {
    await StorageService.delete(appointment.id);
    load();
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');

    return Scaffold(
      resizeToAvoidBottomInset: true, // 🔥 evita quebra com teclado

      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add, size: 36, color: Color.fromARGB(255, 233, 113, 207)),
            label: const Text(
              'Tipos de atendimento',
              style: TextStyle(color: Color.fromARGB(255, 233, 113, 207), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ServiceScreen()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => goToNew(),
        child: const Icon(Icons.add),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
