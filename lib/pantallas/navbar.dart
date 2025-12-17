import 'package:flutter/material.dart';

import 'inicio.dart';

class PantallaNavegacion extends StatefulWidget {
  const PantallaNavegacion({super.key});

  @override
  State<PantallaNavegacion> createState() => _PantallaNavegacionState();
}

class _PantallaNavegacionState extends State<PantallaNavegacion> {
  int _paginaActual = 0;
  
  // Lista de pantallas (Pestañas)
  final List<Widget> _paginas = [
    const PantallaInicio(),
    const Center(child: Text("Aquí irá el CHAT")),
    const Center(child: Text("Aquí irá el CALENDARIO")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Muestra la página seleccionada según el índice
      body: _paginas[_paginaActual],
      
      // Barra de abajo
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual,
        onTap: (indice) => setState(() => _paginaActual = indice),
        backgroundColor: const Color(0xFFFFF5E1), // Fondo Crema
        selectedItemColor: const Color(0xFFFF6B6B), // Rojo activo
        unselectedItemColor: Colors.grey, // Gris inactivo
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 30), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded, size: 30), label: 'Amor'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded, size: 30), label: 'Calendario'),
        ],
      ),
    );
  }
}