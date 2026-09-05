import 'package:shared_preferences/shared_preferences.dart';

class LembreteOpcao {
  final Duration antecedencia;
  final String rotulo;

  const LembreteOpcao(this.antecedencia, this.rotulo);
}

class NotificationSettingsService {
  static final NotificationSettingsService _instance = NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  static const String _chaveAtivo = 'notificacoes_ativas';
  static const String _chaveOffsets = 'notificacoes_offsets_ativos_minutos';

  static const List<LembreteOpcao> opcoesDisponiveis = [
    LembreteOpcao(Duration(days: 7), '1 semana antes'),
    LembreteOpcao(Duration(days: 3), '3 dias antes'),
    LembreteOpcao(Duration(days: 2), '2 dias antes'),
    LembreteOpcao(Duration(days: 1), '1 dia antes'),
    LembreteOpcao(Duration(hours: 3), '3 horas antes'),
    LembreteOpcao(Duration(hours: 2), '2 horas antes'),
    LembreteOpcao(Duration(hours: 1), '1 hora antes'),
    LembreteOpcao(Duration(minutes: 30), '30 minutos antes'),
  ];

  static final Set<Duration> _offsetsAtivosPorPadrao = {
    const Duration(days: 2),
    const Duration(days: 1),
    const Duration(hours: 2),
  };

  Future<bool> notificacoesAtivas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveAtivo) ?? true;
  }

  Future<void> definirNotificacoesAtivas(bool ativo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveAtivo, ativo);
  }

  Future<Set<Duration>> offsetsAtivos() async {
    final prefs = await SharedPreferences.getInstance();
    final salvos = prefs.getStringList(_chaveOffsets);

    if (salvos == null) {
      return _offsetsAtivosPorPadrao;
    }

    return salvos.map((minutos) => Duration(minutes: int.parse(minutos))).toSet();
  }

  Future<void> definirOffsetAtivo(Duration offset, bool ativo) async {
    final atuais = await offsetsAtivos();

    if (ativo) {
      atuais.add(offset);
    } else {
      atuais.remove(offset);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _chaveOffsets,
      atuais.map((d) => d.inMinutes.toString()).toList(),
    );
  }
}
