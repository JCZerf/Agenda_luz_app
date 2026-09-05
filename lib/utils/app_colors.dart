import 'package:flutter/material.dart';

/// Paleta feminina vibrante e alegre do AgendaLuz.
class AppColors {
  static const Color rosaPrincipal = Color(0xFFFF99AC);
  static const Color rosaEscuro = Color(0xFFD45D79);
  static const Color rosaClaro = Color(0xFFFFF0F3);
  static const Color rosaFundoGeral = Color(0xFFFFF5F7);
  static const Color rosaMedio = Color(0xFFFFB3C6);

  static const Color textoEscuro = Color(0xFFD45D79);
  static const Color textoBranco = Colors.white;

  static const Color sucesso = Colors.green;
  static const Color erro = Colors.red;
  static const Color alerta = Colors.orange;
  static const Color info = Colors.blue;

  static const Color cinza = Colors.grey;
  static const Color branco = Colors.white;
  static const Color rosa = Colors.pink;

  static Color rosaPrincipalComOpacidade(double opacity) =>
      rosaPrincipal.withValues(alpha: opacity);

  static Color rosaEscuroComOpacidade(double opacity) =>
      rosaEscuro.withValues(alpha: opacity);

  static Color rosaTextoComOpacidade(double opacity) =>
      textoEscuro.withValues(alpha: opacity);

  static Color cinzaComOpacidade(double opacity) =>
      cinza.withValues(alpha: opacity);
}
