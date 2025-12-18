import 'package:flutter/material.dart';
import 'package:essentials_app/util/estados.dart';
import 'package:essentials_app/util/notas.dart';
import 'package:essentials_app/util/perfil.dart';
import 'package:essentials_app/util/recordatorio.dart';
import 'package:essentials_app/util/servicios.dart';
import 'package:essentials_app/util/barrita.dart'; // <--- IMPORTAMOS LA BARRITA

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _indiceActual = 0; // Controla qué pestaña estamos viendo

  @override
  Widget build(BuildContext context) {
    
    // 1. DEFINIMOS LAS 3 PANTALLAS AQUÍ DENTRO
    final List<Widget> paginas = [
      // PÁGINA 0: TU INICIO ORIGINAL (LISTVIEW)
      ListView(
        padding: const EdgeInsets.only(bottom: 100), // Espacio para que la barra no tape lo último
        children: const [
          SizedBox(height: 10),
          Recordatorio(),
          SizedBox(height: 10),
          Notas(),
          SizedBox(height: 30),
          Estados(),
          SizedBox(height: 50),
          Servicios()
        ],
      ),

      // PÁGINA 1: COSAS DE PAREJA (Placeholder)
      const Center(child: Text("Sección de Pareja ❤️")),

      // PÁGINA 2: CALENDARIO (Placeholder)
      const Center(child: Text("Calendario 📅")),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4), // Tu color crema de fondo
      
      // ================= TU APPBAR INTACTO =================
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEEAC9),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        // FRUTILLA
        leadingWidth: 80,
        leading: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xffffeac9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset('assets/images/frutilla.png',
            height: 150,
            width: 150),
        ),
        // MANZANA
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PantallaPerfil()),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffFD7979), width: 2)
              ),
              child: Image.asset('assets/images/manzana-icon.png',
                height: 40,
                width: 40),
            ),
          )
        ],
      ),
      // =====================================================

      // 2. EL CUERPO CAMBIA SEGÚN EL ÍNDICE
      body: paginas[_indiceActual],

      // 3. LA BARRITA ABAJO
      bottomNavigationBar: BarritaNavegacion(
        indiceActual: _indiceActual,
        onCambiarTab: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
      ),
    );
  }
}