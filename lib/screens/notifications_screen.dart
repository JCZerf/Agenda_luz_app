import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<PendingNotificationRequest> _notificacoesPendentes = [];
  bool _carregando = true;

  final rosaPrincipal = const Color(0xFFD9A7B0);
  final rosaClaro = const Color(0xFFFFF1F3);
  final rosaTexto = const Color(0xFF8A4B57);

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  Future<void> _carregarNotificacoes() async {
    setState(() => _carregando = true);
    final notificacoes = await NotificationService.obterNotificacoesPendentes();
    setState(() {
      _notificacoesPendentes = notificacoes;
      _carregando = false;
    });
  }

  Future<void> _reagendarTodasNotificacoes() async {
    await NotificationService.reagendarNotificacoesExistentes();
    await _carregarNotificacoes();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notificações reagendadas com sucesso!')));
    }
  }

  Future<void> _cancelarTodasNotificacoes() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Notificações'),
        content: const Text('Deseja realmente cancelar todas as notificações de lembrete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await NotificationService.cancelarTodasNotificacoes();
      await _carregarNotificacoes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Todas as notificações foram canceladas!')));
      }
    }
  }

  Future<void> _testarNotificacao() async {
    await NotificationService.mostrarNotificacaoImediata(
      titulo: 'Teste de Notificação',
      corpo: 'Esta é uma notificação de teste do AgendALuz!',
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notificação de teste enviada!')));
    }
  }

  String _formatarTipoNotificacao(String? payload) {
    if (payload == null) return 'Desconhecido';

    try {
      // Aqui você pode parsear o payload JSON para extrair informações
      if (payload.contains('dois_dias_antes')) {
        return '2 dias antes';
      } else if (payload.contains('um_dia_antes')) {
        return '1 dia antes';
      } else if (payload.contains('duas_horas_antes')) {
        return '2 horas antes';
      }
    } catch (e) {
      // Ignora erros de parsing
    }

    return 'Lembrete';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaTexto,
        elevation: 0,
        title: const Text('Notificações', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: rosaClaro,
        child: Column(
          children: [
            // Botões de ação
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _reagendarTodasNotificacoes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reagendar Todas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rosaPrincipal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testarNotificacao,
                          icon: const Icon(Icons.notifications),
                          label: const Text('Testar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cancelarTodasNotificacoes,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar Todas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informações
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: rosaTexto),
                  const SizedBox(width: 8),
                  Text(
                    'Notificações pendentes: ${_notificacoesPendentes.length}',
                    style: TextStyle(color: rosaTexto, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Lista de notificações
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _notificacoesPendentes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma notificação pendente',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crie um novo agendamento para ver as notificações',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _notificacoesPendentes.length,
                      itemBuilder: (context, index) {
                        final notificacao = _notificacoesPendentes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: rosaPrincipal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(Icons.notifications, color: rosaTexto),
                            ),
                            title: Text(
                              notificacao.title ?? 'Sem título',
                              style: TextStyle(fontWeight: FontWeight.w600, color: rosaTexto),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notificacao.body ?? 'Sem conteúdo',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tipo: ${_formatarTipoNotificacao(notificacao.payload)}',
                                  style: TextStyle(
                                    color: rosaPrincipal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              'ID: ${notificacao.id}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
