import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/database_helper.dart';
import '../models/atendimento.dart';
import 'notification_settings_service.dart';

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

  static final NotificationSettingsService _settings = NotificationSettingsService();

  static Future<void> agendarNotificacoesAtendimento(Atendimento atendimento) async {
    if (!_isInitialized) {
      return;
    }

    try {
      await cancelarNotificacoesAtendimento(atendimento.id!);

      if (!await _settings.notificacoesAtivas()) {
        return;
      }

      final agora = DateTime.now();
      final dataAtendimento = atendimento.dataHora;

      if (dataAtendimento.isBefore(agora)) {
        return;
      }

      final offsetsAtivos = await _settings.offsetsAtivos();
      if (offsetsAtivos.isEmpty) {
        return;
      }

      final corpoNotificacao = await _criarCorpoNotificacao(atendimento, '');
      const opcoes = NotificationSettingsService.opcoesDisponiveis;

      for (var i = 0; i < opcoes.length; i++) {
        final opcao = opcoes[i];
        if (!offsetsAtivos.contains(opcao.antecedencia)) continue;

        final dataAgendamento = dataAtendimento.subtract(opcao.antecedencia);
        if (!dataAgendamento.isAfter(agora)) continue;

        await _agendarNotificacao(
          id: atendimento.id! * 100 + i,
          titulo: 'Lembrete: Atendimento ${opcao.rotulo}',
          corpo: corpoNotificacao,
          dataAgendamento: dataAgendamento,
          payload: jsonEncode({
            'atendimento_id': atendimento.id,
            'antecedencia_minutos': opcao.antecedencia.inMinutes,
          }),
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
      for (var i = 0; i < NotificationSettingsService.opcoesDisponiveis.length; i++) {
        await _notifications.cancel(atendimentoId * 100 + i);
      }
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

}
