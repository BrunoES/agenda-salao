import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializa
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    // Permissão Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission().then(  
            (granted) => {
              if (granted == null) {
                  print('Permissão de notificações não necessária (Android < 13)')
                } else if (granted == false) {
                  print('Permissão de notificações negada')
                } else {
                  showInstantNotification(
                    title: 'Notificações Ativadas',
                    body: 'Você receberá notificações agendadas',
                  )
              }
            }
          );
  }

  static Future<void> showInstantNotification({
  required String title,
  required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel', // ID do canal
      'Notificações Instantâneas', // Nome do canal
      channelDescription: 'Canal para testes e alertas imediatos',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // Útil para garantir que apareça no topo
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0, // ID da notificação
      title,
      body,
      details,
    );
  }

  /// Agenda notificações para minutos pares
  /*
  static Future<void> scheduleEvenMinuteNotifications() async {
    final now = DateTime.now();

    const androidDetails = AndroidNotificationDetails(
      'even_minute_channel',
      'Minutos Pares',
      channelDescription: 'Notifica em minutos pares',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // Agenda para próximos 60 minutos
    for (int i = 1; i <= 60; i++) {
      final futureTime = now.add(Duration(minutes: i));

      // Se minuto for par
      if (futureTime.minute % 2 == 0) {
        await _notifications.zonedSchedule(
          i, // ID único
          'Minuto Par',
          'Veja essa notificação',
          tz.TZDateTime.from(futureTime, tz.local),
          details,
          androidScheduleMode:
              AndroidScheduleMode.exact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }
  */
  
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    // Inicializa timezone (caso ainda não tenha sido feito)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Gera ID único baseado no timestamp
    final int id =
        DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Notificações',
      channelDescription: 'Canal padrão',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // Evita agendar no passado
    if (dateTime.isBefore(DateTime.now())) {
      print('Data já passou, não será agendada');
      return;
    }

    await _notifications.zonedSchedule(
      1111,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    ).then(
      (_) => _notifications.show(1112345, title, 'Notificação agendada para $dateTime',details,),
    ).catchError(
      (error) => print('Erro ao agendar notificação: $error'),
    );
  }

  /// Cancela todas
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}