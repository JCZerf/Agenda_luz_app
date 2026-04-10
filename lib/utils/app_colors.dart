import 'package:flutter/material.dart';

/// Classe com todas as cores do aplicativo AgendaLuz
/// Paleta sofisticada e minimalista com tons de rosa suaves
class AppColors {
  // Cores principais - Tom rosa nude elegante
  static const Color rosaPrincipal = Color(0xFFD4A5A5);      // Rosa nude suave
  static const Color rosaEscuro = Color(0xFF8B6F7A);         // Malva terroso elegante
  static const Color rosaClaro = Color(0xFFFAF5F5);          // Off-white rosado delicado
  static const Color rosaFundoGeral = Color(0xFFF9F4F5);     // Fundo muito sutil
  static const Color rosaMedio = Color(0xFFC9999A);          // Rosa acinzentado refinado
  
  // Cores de texto
  static const Color textoEscuro = Color(0xFF6B5660);        // Tom mais suave para melhor leitura
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
