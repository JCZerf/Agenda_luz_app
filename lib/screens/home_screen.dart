import 'package:AgendaLuz/utils/developerSignature.dart';
import 'package:flutter/material.dart';

import 'agenda_screen.dart';
import 'atendimentos_screen.dart';
import 'clientes_screen.dart';
import 'financeiro_screen.dart';
import 'servicos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final rosaPrincipal = const Color(0xFFD9A7B0);
  final rosaClaro = const Color(0xFFFFF1F3);
  final rosaTexto = const Color(0xFF8A4B57);

  final List<Widget> _telas = const [
    AgendaScreen(),
    AtendimentosScreen(),
    ClientesScreen(),
    ServicosScreen(),
    FinanceiroScreen(),
  ];

  final List<BottomNavigationBarItem> _botoes = const [
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Agenda'),
    BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Atendimentos'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
    BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Serviços'),
    BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Financeiro'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _telas[_selectedIndex]),
            const DeveloperSignature(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: rosaTexto,
            unselectedItemColor: rosaTexto.withOpacity(0.5),
            selectedFontSize: 12,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: _botoes,
          ),
        ),
      ),
    );
  }
}
