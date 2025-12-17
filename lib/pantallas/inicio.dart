import 'package:flutter/material.dart';
import '../temas/estilo.dart'; // <--- IMPORTANTE: Importamos tu archivo de estilos

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ==========================================
            // ENCABEZADO
            // ==========================================

            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Estilos.colorFondo, // <--- donde se usa el estilo
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/images/frutilla.png', width: 70), // logo frutilla
                  
                  Column(
                    children: [
                      const Text("Perfil", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 5),
                      
                      // btn de perfil
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Estilos.colorRojo, width: 1),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {},
                          icon: Image.asset('assets/images/manzana-icon.png',height: 30), // cambiarlo
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // RECORDATORIO
            // ==========================================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              decoration: Estilos.decoracionTarjeta, // <--- estilo de la tarjeta
              
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Imagen del título + gato
                  Image.asset('assets/images/recordatorio.png', height: 300),

                  const SizedBox(height: 20),

                  // Cajita blanca fecha
                  Container(
                    margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Text("25 de Diciembre", style: Estilos.textoTitulo), // Usando estilo
                        SizedBox(height: 5),
                        Text("Navidad", style: Estilos.textoSubtitulo),      // Usando estilo
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}