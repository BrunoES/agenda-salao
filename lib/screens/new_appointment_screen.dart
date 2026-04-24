import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/service_type.dart';
import '../services/service_type_storage.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NewAppointmentScreen extends StatefulWidget {
  final List<Appointment> existing;
  final Appointment? edit;
  final DateTime dataHora;

  const NewAppointmentScreen({
    required this.existing,
    required this.dataHora,
    this.edit,
    super.key,
  });

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController clienteCtrl = TextEditingController();
  final TextEditingController duracaoCtrl = TextEditingController();

  List<ServiceType> servicos = [];
  ServiceType? servicoSelecionado;

  int duracao = 60;
  DateTime? dataHora;
  final List<int> duracoes = [15, 30, 45, 60, 90, 120, 150, 180, 210, 240];

  final List<String> duracoesDescription = [
    '15 minutos',
    '30 minutos',
    '45 minutos',
    '1 hora',
    '1 hora e meia',
    '2 horas',
    '2 horas e meia',
    '3 horas',
    '3 horas e meia',
    '4 horas',
  ];

  @override
  void initState() {
    super.initState();
    loadServices();
    if (widget.edit != null) {
      final e = widget.edit!;

      clienteCtrl.text = e.cliente; // 🔥 CORRETO
      duracaoCtrl.text = e.duracao.toString();
      dataHora = e.inicio;
    } else {
      dataHora = widget.dataHora;
    }
  }

  void loadServices() async {
    servicos = await ServiceTypeStorage.load();

    if (!mounted) return;

    if (widget.edit != null) {
      final e = widget.edit!;
      clienteCtrl.text = e.cliente;
      duracaoCtrl.text = e.duracao.toString();
      dataHora = e.inicio;

      if (servicos.isNotEmpty) {
        servicoSelecionado = servicos.firstWhere(
          (s) => s.nome == e.servico,
          orElse: () => servicos.first,
        );
      }
    } else {
      if (servicos.isNotEmpty) {
        servicoSelecionado = servicos.first;
        duracaoCtrl.text = servicoSelecionado!.duracaoPadrao.toString();
      }
    }

    setState(() {});
  }

  void salvar() async {
    if (!_formKey.currentState!.validate() || dataHora == null) return;

    _formKey.currentState!.save();
    final currentContext = context;

    final novo = Appointment(
      id: widget.edit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cliente: clienteCtrl.text, // 🔥 AQUI,
      servico: servicoSelecionado?.nome ?? '',
      inicio: dataHora!,
      duracao: duracaoCtrl.text.isNotEmpty
          ? int.parse(duracaoCtrl.text)
          : duracao,
    );

    final lista = await StorageService.load();

    if (dataHora!.hour < 6 ||
        dataHora!.hour > 23 ||
        (dataHora!.hour == 23 && dataHora!.minute > 0)) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text(
            'Aviso: esse horário pode ficar fora do campo visível na grade.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // 🔥 VALIDAÇÃO DE CONFLITO
    final conflito = StorageService.hasConflict(lista, novo);

    if (conflito) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Já existe um agendamento neste horário!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else {
      // 🔥 SALVA DIRETO NO STORAGE
      await StorageService.add(novo);

      await NotificationService.scheduleNotification(
        title: 'Lembrete de Agendamento',
        body: 'Você tem um agendamento para ${novo.servico} às ${DateFormat('HH:mm').format(novo.inicio)} com ${novo.cliente}.',
        dateTime: novo.inicio.subtract(const Duration(minutes: 30)), // Lembrete 30 minutos antes
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(currentContext, novo);
      if (!mounted) return;
    }
  }

  Future pickDateTime() async {
    final currentContext = context;
    final date = await showDatePicker(
      context: currentContext,
      initialDate: dataHora ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    // ignore: use_build_context_synchronously
    final time = await showTimePicker(
      context: currentContext,
      initialTime: TimeOfDay.fromDateTime(dataHora ?? DateTime.now()),
      initialEntryMode: TimePickerEntryMode.input, // 🔥 AQUI
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time == null || !mounted) return;

    // ignore: use_build_context_synchronously
    setState(() {
      dataHora = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: Text(
          widget.edit == null ? 'Novo Agendamento' : 'Editar Agendamento',
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: clienteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Cliente',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),

                // 🔥 DROPDOWN DINÂMICO DO STORAGE
                DropdownButtonFormField<ServiceType>(
                  initialValue: servicoSelecionado,
                  items: servicos.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text('${s.nome} (${s.duracaoPadrao} min)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      servicoSelecionado = value;
                      duracaoCtrl.text = value!.duracaoPadrao.toString();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tipo de atendimento',
                  ),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  initialValue: duracaoCtrl.text.isNotEmpty
                      ? int.parse(duracaoCtrl.text)
                      : duracao,
                  decoration: const InputDecoration(
                    labelText: 'Duração do atendimento, pode alterar se quiser',
                  ),
                  items: duracoes.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(
                        duracoesDescription.elementAt(duracoes.indexOf(d)),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      duracao = value!;
                      duracaoCtrl.text = value
                          .toString(); // 🔥 SINCRONIZA COM O CONTROLLER
                    });
                  },
                  validator: (v) => v == null ? 'Selecione a duração' : null,
                ),

                /*
                TextFormField(
                  controller: duracaoCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duração'),
                  onChanged: (v) =>
                      duracao = int.tryParse(v) ?? duracao,
                ),
                */
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: pickDateTime,
                  child: const Text('Selecionar data e hora'),
                ),

                const SizedBox(height: 10),

                if (dataHora != null)
                  Text(
                    'Data Selecionada: ${format.format(dataHora!)}',
                    style: const TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: salvar,
                  child: const Text('Salvar agendamento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
