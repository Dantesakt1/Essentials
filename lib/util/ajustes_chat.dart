import 'package:flutter/material.dart';

class AjustesChat extends StatelessWidget {
  const AjustesChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4), // Tu color crema
      appBar: AppBar(
        title: const Text(
          "Ajustes del Chat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFEEAC9), // Tu color beige
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black), // Flecha negra
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _OpcionAjuste(
            titulo: "Cambiar Fondo",
            icono: Icons.image_outlined,
            onTap: () {},
          ),
          _OpcionAjuste(
            titulo: "Apodo de mi Pareja",
            icono: Icons.edit_outlined,
            onTap: () {},
          ),
          _OpcionAjuste(
            titulo: "Borrar Chat",
            icono: Icons.delete_outline,
            colorTexto: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// Un widget pequeño para que las opciones se vean bonitas
class _OpcionAjuste extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final VoidCallback onTap;
  final Color colorTexto;

  const _OpcionAjuste({
    required this.titulo,
    required this.icono,
    required this.onTap,
    this.colorTexto = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEEAC9).withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: Colors.black54),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorTexto,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}