import 'package:AgendaLuz/screens/cliente_form_screen.dart';
import 'package:AgendaLuz/screens/dashboard_financeiro_screen.dart';
import 'package:AgendaLuz/screens/movimentacao_form_screen.dart';
import 'package:AgendaLuz/screens/notifications_screen.dart';
import 'package:AgendaLuz/screens/servico_form_screen.dart';
import 'package:AgendaLuz/services/notification_service.dart';
import 'package:AgendaLuz/services/backup_service.dart';
import 'package:AgendaLuz/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/agendamento_form_screen.dart';
import 'screens/home_screen.dart';
import 'screens/configuracoes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o serviço de notificações com tratamento de erro
  try {
    await NotificationService.initialize();
  } catch (e) {
    // Se falhar, continua sem notificações
    print('Erro ao inicializar notificações: $e');
  }

  // Fazer backup automático na inicialização
  try {
    final backupService = BackupService();
    await backupService.fazerBackupAutomatico();
    print('Backup automático realizado com sucesso');
  } catch (e) {
    print('Erro ao fazer backup automático: $e');
  }

  await initializeDateFormatting('pt_BR', null);
  await Future.delayed(const Duration(seconds: 2));

  runApp(const AgendALuzApp());
}

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class AgendALuzApp extends StatelessWidget {
  const AgendALuzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendALuz',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.rosaFundoGeral,
        primaryColor: AppColors.rosaEscuro,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.rosaEscuro,
          secondary: AppColors.rosaMedio,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.rosaEscuro,
          foregroundColor: AppColors.textoBranco,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textoBranco,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: AppColors.textoEscuro,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: AppColors.textoEscuro, fontSize: 16),
          labelLarge: TextStyle(color: AppColors.textoEscuro, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.rosaClaro,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: AppColors.cinza),
          prefixIconColor: AppColors.rosaPrincipal,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.rosaPrincipal),
            foregroundColor: WidgetStatePropertyAll(AppColors.textoBranco),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.rosaPrincipal,
          foregroundColor: AppColors.textoBranco,
        ),
        iconTheme: IconThemeData(color: AppColors.rosaPrincipal),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/agendamento': (context) => const AgendamentoFormScreen(),
        '/cliente_form': (context) => const ClienteFormScreen(),
        '/nova_movimentacao': (context) => const MovimentacaoFormScreen(),
        '/servico_form': (context) => const ServicoFormScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
        '/dashboard_financeiro': (context) => const DashboardFinanceiroScreen(),
      },
    );
  }
}
