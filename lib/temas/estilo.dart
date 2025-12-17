import 'package:flutter/material.dart';

class Estilos {
  // COLORES
  static const Color colorFondo = Color(0xFFFFF5E1);      // beige claro
  static const Color colorBarras = Color(0xFFFEEAC9);    // amarillo claro
  static const Color colorRojo = Color(0xFFFD7979);       // rojo frutilla
  static const Color colorTexto = Color(0xFF333333);      // Negro suave
  
  // ESTILOS DE TEXTO
  static const TextStyle textoTitulo = TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.bold, 
    color: Colors.black87
  );
  
  static const TextStyle textoSubtitulo = TextStyle(
    fontSize: 14, 
    fontWeight: FontWeight.bold, 
    color: colorRojo
  );

  // DECORACIONES (Las formas redondeadas)
  static final BoxDecoration decoracionTarjeta = BoxDecoration(
    color: colorBarras,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}