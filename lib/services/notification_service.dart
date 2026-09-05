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

      await _notifications.initialize(settings);

      if (Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  static Future<void> agendarNotificacoesAtendimento(Atendimento atendimento) async {
    if (!_isInitialized) {
      return;
    }

    try {
      final agora = DateTime.now();
      final dataAtendimento = atendimento.dataHora;

      await cancelarNotificacoesAtendimento(atendimento.id!);

      if (dataAtendimento.isBefore(agora)) {
        return;
      }

      final corpoNotificacao = await _criarCorpoNotificacao(atendimento, '');

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
      // falha silenciosa
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
    } catch (e) {
      // falha silenciosa
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
      await _notifications.cancel(atendimentoId * 10 + 1);
      await _notifications.cancel(atendimentoId * 10 + 2);
      await _notifications.cancel(atendimentoId * 10 + 3);
    } catch (e) {
      // falha silenciosa
    }
  }

  static Future<void> cancelarTodasNotificacoes() async {
    if (!_isInitialized) return;

    try {
      await _notifications.cancelAll();
    } catch (e) {
      // falha silenciosa
    }
  }

  static Future<void> reagendarNotificacoesExistentes() async {
    if (!_isInitialized) return;

    try {
      final atendimentos = await DatabaseHelper().listarAtendimentos();
      final agora = DateTime.now();

      for (final atendimento in atendimentos) {
        if (atendimento.dataHora.isAfter(agora) && !atendimento.concluido) {
          await agendarNotificacoesAtendimento(atendimento);
        }
      }
    } catch (e) {
      // falha silenciosa
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
      // falha silenciosa
    }
  }

  static Future<List<PendingNotificationRequest>> obterNotificacoesPendentes() async {
    if (!_isInitialized) return [];

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }
}
