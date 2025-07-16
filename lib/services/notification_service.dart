import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/database_helper.dart';
import '../models/atendimento.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      // Inicializa timezone
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Aqui você pode adicionar lógica para quando o usuário toca na notificação
          debugPrint('Notificação tocada: ${response.payload}');
        },
      );

      // Solicitar permissões no Android 13+
      if (Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar notificações: $e');
      _isInitialized = false;
    }
  }

  static Future<void> agendarNotificacoesAtendimento(Atendimento atendimento) async {
    if (!_isInitialized) {
      debugPrint('Notificações não inicializadas, pulando agendamento');
      return;
    }

    try {
      final agora = DateTime.now();
      final dataAtendimento = atendimento.dataHora;

      // Cancelar notificações anteriores para este atendimento
      await cancelarNotificacoesAtendimento(atendimento.id!);

      // Só agenda notificações para atendimentos futuros
      if (dataAtendimento.isBefore(agora)) {
        return;
      }

      final corpoNotificacao = await _criarCorpoNotificacao(atendimento, '');

      // Notificação 2 dias antes
      final doisDiasAntes = dataAtendimento.subtract(const Duration(days: 2));
      if (doisDiasAntes.isAfter(agora)) {
        await _agendarNotificacao(
          id: atendimento.id! * 10 + 1, // ID único baseado no ID do atendimento
          titulo: 'Lembrete: Atendimento em 2 dias',
          corpo: corpoNotificacao,
          dataAgendamento: doisDiasAntes,
          payload: jsonEncode({'atendimento_id': atendimento.id, 'tipo': 'dois_dias_antes'}),
        );
      }

      // Notificação 1 dia antes
      final umDiaAntes = dataAtendimento.subtract(const Duration(days: 1));
      if (umDiaAntes.isAfter(agora)) {
        await _agendarNotificacao(
          id: atendimento.id! * 10 + 2,
          titulo: 'Lembrete: Atendimento amanhã',
          corpo: corpoNotificacao,
          dataAgendamento: umDiaAntes,
          payload: jsonEncode({'atendimento_id': atendimento.id, 'tipo': 'um_dia_antes'}),
        );
      }

      // Notificação 2 horas antes
      final duasHorasAntes = dataAtendimento.subtract(const Duration(hours: 2));
      if (duasHorasAntes.isAfter(agora)) {
        await _agendarNotificacao(
          id: atendimento.id! * 10 + 3,
          titulo: 'Atendimento em 2 horas',
          corpo: corpoNotificacao,
          dataAgendamento: duasHorasAntes,
          payload: jsonEncode({'atendimento_id': atendimento.id, 'tipo': 'duas_horas_antes'}),
        );
      }
    } catch (e) {
      debugPrint('Erro ao agendar notificações: $e');
    }
  }

  static Future<void> _agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataAgendamento,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'agenda_channel',
        'Agendamentos',
        channelDescription: 'Lembretes de agendamentos',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFD9A7B0),
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notifications.zonedSchedule(
        id,
        titulo,
        corpo,
        tz.TZDateTime.from(dataAgendamento, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        'Notificação agendada: $titulo para ${DateFormat('dd/MM/yyyy HH:mm').format(dataAgendamento)}',
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
  }

  static Future<String> _criarCorpoNotificacao(Atendimento atendimento, String quando) async {
    String nomeCliente = 'Cliente não identificado';

    try {
      if (atendimento.clienteId != null) {
        final clientes = await DatabaseHelper().listarClientes();
        final cliente = clientes.firstWhere(
          (c) => c.id == atendimento.clienteId,
          orElse: () => throw Exception('Cliente não encontrado'),
        );
        nomeCliente = cliente.nome;
      } else if (atendimento.nomeLivre.isNotEmpty) {
        nomeCliente = atendimento.nomeLivre;
      }
    } catch (e) {
      nomeCliente = 'Cliente não identificado';
    }

    final horario = DateFormat('HH:mm').format(atendimento.dataHora);
    final data = DateFormat('dd/MM/yyyy').format(atendimento.dataHora);

    return 'Atendimento com $nomeCliente $quando às $horario ($data)';
  }

  static Future<void> cancelarNotificacoesAtendimento(int atendimentoId) async {
    if (!_isInitialized) return;

    try {
      // Cancela todas as notificações relacionadas a um atendimento
      await _notifications.cancel(atendimentoId * 10 + 1); // 2 dias antes
      await _notifications.cancel(atendimentoId * 10 + 2); // 1 dia antes
      await _notifications.cancel(atendimentoId * 10 + 3); // 2 horas antes
    } catch (e) {
      debugPrint('Erro ao cancelar notificações: $e');
    }
  }

  static Future<void> cancelarTodasNotificacoes() async {
    if (!_isInitialized) return;

    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Erro ao cancelar todas as notificações: $e');
    }
  }

  static Future<void> reagendarNotificacoesExistentes() async {
    if (!_isInitialized) return;

    try {
      // Reagenda notificações para todos os atendimentos futuros
      final atendimentos = await DatabaseHelper().listarAtendimentos();
      final agora = DateTime.now();

      for (final atendimento in atendimentos) {
        if (atendimento.dataHora.isAfter(agora) && !atendimento.concluido) {
          await agendarNotificacoesAtendimento(atendimento);
        }
      }
    } catch (e) {
      debugPrint('Erro ao reagendar notificações: $e');
    }
  }

  static Future<void> mostrarNotificacaoImediata({
    required String titulo,
    required String corpo,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'imediato_channel',
        'Notificações Imediatas',
        channelDescription: 'Notificações imediatas do sistema',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFD9A7B0),
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titulo,
        corpo,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Erro ao mostrar notificação imediata: $e');
    }
  }

  static Future<List<PendingNotificationRequest>> obterNotificacoesPendentes() async {
    if (!_isInitialized) return [];

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Erro ao obter notificações pendentes: $e');
      return [];
    }
  }
}
