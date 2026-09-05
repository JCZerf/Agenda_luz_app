import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import '../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _settings = NotificationSettingsService();

  bool _carregando = true;
  bool _notificacoesAtivas = true;
  Set<Duration> _offsetsAtivos = {};

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    final ativas = await _settings.notificacoesAtivas();
    final offsets = await _settings.offsetsAtivos();

    if (!mounted) return;
    setState(() {
      _notificacoesAtivas = ativas;
      _offsetsAtivos = offsets;
      _carregando = false;
    });
  }

  Future<void> _alternarNotificacoesAtivas(bool valor) async {
    setState(() => _notificacoesAtivas = valor);
    await _settings.definirNotificacoesAtivas(valor);

    if (valor) {
      await NotificationService.reagendarNotificacoesExistentes();
    } else {
      await NotificationService.cancelarTodasNotificacoes();
    }
  }

  Future<void> _alternarOffset(Duration offset, bool valor) async {
    setState(() {
      if (valor) {
        _offsetsAtivos.add(offset);
      } else {
        _offsetsAtivos.remove(offset);
      }
    });
    await _settings.definirOffsetAtivo(offset, valor);
    await NotificationService.reagendarNotificacoesExistentes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.textoEscuro,
        elevation: 0,
        title: const Text('Lembretes de Atendimento', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: AppColors.rosaClaro,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: const Text('Ativar lembretes'),
                      subtitle: const Text(
                        'Recebe uma notificação no celular antes de cada atendimento, '
                        'para você se preparar.',
                      ),
                      value: _notificacoesAtivas,
                      activeColor: AppColors.rosaPrincipal,
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[300],
                      onChanged: _alternarNotificacoesAtivas,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Quando notificar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoEscuro,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        for (final opcao in NotificationSettingsService.opcoesDisponiveis)
                          SwitchListTile(
                            title: Text(opcao.rotulo),
                            value: _offsetsAtivos.contains(opcao.antecedencia),
                            activeColor: AppColors.rosaPrincipal,
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[300],
                            onChanged: _notificacoesAtivas
                                ? (valor) => _alternarOffset(opcao.antecedencia, valor)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
