import 'package:AgendaLuz/screens/cliente_form_screen.dart';
import 'package:AgendaLuz/screens/movimentacao_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/agendamento_form_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBEFF1), // fundo geral bem claro
        primaryColor: const Color(0xFFD9A7B0), // rosa principal
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFD9A7B0),
          secondary: const Color(0xFFE9B6C0), // tom médio para destaque
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD9A7B0),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF8A4B57), // rosa escuro
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: Color(0xFF8A4B57), fontSize: 16),
          labelLarge: TextStyle(color: Color(0xFF8A4B57), fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFF1F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIconColor: const Color(0xFFD9A7B0),
        ),
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Color(0xFFD9A7B0)),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD9A7B0),
          foregroundColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD9A7B0)),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/agendamento': (context) => const AgendamentoFormScreen(),
        '/cliente_form': (context) => const ClienteFormScreen(),
        '/nova_movimentacao': (context) => const MovimentacaoFormScreen(),
      },
    );
  }
}
