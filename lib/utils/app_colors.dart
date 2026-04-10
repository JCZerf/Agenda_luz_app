import 'package:flutter/material.dart';

/// Classe com todas as cores do aplicativo AgendaLuz
/// Paleta feminina vibrante e alegre
class AppColors {
  // Cores principais - Tom rosa vibrante e feminino
  static const Color rosaPrincipal = Color(0xFFFF99AC);      // Rosa chiclete vibrante
  static const Color rosaEscuro = Color(0xFFD45D79);         // Rosa intenso elegante
  static const Color rosaClaro = Color(0xFFFFF0F3);          // Rosa clarinho delicado
  static const Color rosaFundoGeral = Color(0xFFFFF5F7);     // Fundo rosa suave
  static const Color rosaMedio = Color(0xFFFFB3C6);          // Rosa médio alegre
  
  // Cores de texto
  static const Color textoEscuro = Color(0xFFD45D79);        // Rosa intenso para textos
  static const Color textoBranco = Colors.white;
  
  // Cores de status
  static const Color sucesso = Colors.green;
  static const Color erro = Colors.red;
  static const Color alerta = Colors.orange;
  static const Color info = Colors.blue;
  
  // Cores secundárias
  static const Color cinza = Colors.grey;
  static const Color branco = Colors.white;
  static const Color rosa = Colors.pink;
  
  // Métodos auxiliares para cores com opacidade
  static Color rosaPrincipalComOpacidade(double opacity) => 
      rosaPrincipal.withOpacity(opacity);
  
  static Color rosaEscuroComOpacidade(double opacity) => 
      rosaEscuro.withOpacity(opacity);
  
  static Color rosaTextoComOpacidade(double opacity) => 
      textoEscuro.withOpacity(opacity);
  
  static Color cinzaComOpacidade(double opacity) => 
      cinza.withOpacity(opacity);
}
