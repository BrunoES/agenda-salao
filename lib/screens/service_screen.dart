import 'package:flutter/material.dart';
import '../models/service_type.dart';
import '../services/service_type_storage.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  List<ServiceType> services = [];

  final nameCtrl = TextEditingController();

  int duracao = 60;
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
    load();
  }

  void load() async {
    services = await ServiceTypeStorage.load();
    if (!mounted) return;
    setState(() {});

    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Crie tipos de atendimento, como: Pintura, Corte, Manicure pé, mãos, etc. Depois, ao criar um agendamento, escolha o tipo para preencher a duração automaticamente! :)',
          ),
          duration: Duration(seconds: 7),
          backgroundColor: Colors.pinkAccent,
        ),
      );
    }
  }

  void add() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool wasEmpty = services.isEmpty;

    final newItem = ServiceType(
      id: DateTime.now().toString(),
      nome: nameCtrl.text,
      duracaoPadrao: duracao,
    );

    services.add(newItem);
    await ServiceTypeStorage.save(services);

    nameCtrl.clear();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tipo de atendimento adicionado!'),
        backgroundColor: Color.fromARGB(255, 114, 201, 140),
      ),
    );

    if (wasEmpty && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Está pronto!'),
            content: const Text(
              'Agora você já pode voltar para a tela anterior para criar agendamentos :D, '
              'ou aproveitar e cadastrar mais tipos de atendimento se preferir !',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void delete(ServiceType item) async {
    services.removeWhere((e) => e.id == item.id);
    await ServiceTypeStorage.save(services);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tipos de Atendimento')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do serviço (exemplo: Corte, Pintura, etc)',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe o nome do serviço'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: duracao,
                decoration: const InputDecoration(
                  labelText: 'Duração - Quanto tempo geralmente leva?',
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
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: add,
                child: const Text('Adicionar tipo'),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (_, i) {
                    final s = services[i];

                    return Card(
                      child: ListTile(
                        title: Text(s.nome),
                        subtitle: Text('${s.duracaoPadrao} minutos'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => delete(s),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
