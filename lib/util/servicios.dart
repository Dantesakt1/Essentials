import 'package:essentials_app/util/ruleta.dart';
import 'package:essentials_app/util/wishlist.dart';
import 'package:flutter/material.dart';

class Servicios extends StatelessWidget {
  const Servicios({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 1. TARJETA CAJA DE DESEOS (Pikmin)
          _tarjetaServicio(
            imagen: 'assets/images/wishlist.png',
            onTap: () {
              // --- NAVEGACIÓN AQUÍ ---
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),

          const SizedBox(height: 25), // Espacio entre las tarjetas

          // 2. TARJETA RULETA
          _tarjetaServicio(
            imagen: 'assets/images/ruleta.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RuletaPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para crear las tarjetas con estilo
  Widget _tarjetaServicio({required String imagen, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Que ocupe todo el ancho
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30), // Bordes redondos igual que tu imagen
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Sombra suave
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        // ClipRRect asegura que la imagen se recorte en los bordes redondos
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset(
            imagen,
            fit: BoxFit.contain, // Se ajusta perfecto
          ),
        ),
      ),
    );
  }
}