import 'package:flutter/material.dart';
import '../models/appointment.dart';

class ScheduleGrid extends StatelessWidget {
  final List<Appointment> appointments;
  final Function(Appointment) onEdit;
  final Function(Appointment) onDelete;
  final ScrollController? scrollController;

  final DateTime selectedDate;

  const ScheduleGrid(
    this.appointments, {
    required this.onEdit,
    required this.onDelete,
    required this.selectedDate,
    this.scrollController,
    super.key,
  });

  static const double hourHeight = 70;

  @override
  Widget build(BuildContext context) {
    final day = selectedDate;

    final dayAppointments =
        appointments
            .where(
              (a) =>
                  a.inicio.year == day.year &&
                  a.inicio.month == day.month &&
                  a.inicio.day == day.day,
            )
            .toList()
          ..sort((a, b) => a.inicio.compareTo(b.inicio));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: 24 * hourHeight,
            width: constraints.maxWidth,
            child: Stack(
              children: [
                // 📏 GRID base (horas)
                Column(
                  children: List.generate(24, (i) {
                    if (i < 6) {
                      return Container(height: 0);
                    }
                    return Container(
                      height: hourHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 8),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${i.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 99, 99, 99),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }),
                ),

                // 🔴 EVENTOS (sem overflow agora)
                ...dayAppointments.map((a) {
                  final startMinutes =
                      (a.inicio.hour - 6) * 60 +
                      a
                          .inicio
                          .minute; // Aqui faz menos 6 horas para alinhar com o grid que começa às 6h. Se quiser começar às 0h, basta usar a.inicio.hour * 60 + a.inicio.minute.

                  final top = (startMinutes / 60) * hourHeight;
                  final height = (a.duracao / 60) * hourHeight;

                  return Positioned(
                    top: top,
                    left: 80,
                    right: 10,
                    height: height.clamp(30.0, double.infinity),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(233, 113, 207, 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color.fromARGB(255, 255, 72, 133),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // 📌 conteúdo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${a.cliente} - ${a.servico} (${a.duracao} min)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),

                          // ✏️ editar
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.edit,
                                size: 22,
                                color: Colors.white,
                              ),
                              onPressed: () => onEdit(a),
                            ),
                          ),

                          const SizedBox(width: 20),

                          // 🗑️ deletar
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.delete,
                                size: 22,
                                color: Colors.white,
                              ),
                              onPressed: () => onDelete(a),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
