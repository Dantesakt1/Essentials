import 'package:flutter/material.dart';

class BarritaNavegacion extends StatelessWidget {
  final int indiceActual;
  final Function(int) onCambiarTab;

  const BarritaNavegacion({
    super.key,
    required this.indiceActual,
    required this.onCambiarTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        // Corregí el código de color (tenía un dígito extra), asumo que es el Beige
        color: const Color(0xFFFEEAC9), 
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ItemBarra(
            icono: 'assets/images/home.png',
            index: 0,
            isSelected: indiceActual == 0,
            onTap: onCambiarTab,
          ),
          _ItemBarra(
            icono: 'assets/images/heart.png',
            index: 1,
            isSelected: indiceActual == 1,
            onTap: onCambiarTab,
          ),
          _ItemBarra(
            icono: 'assets/images/calendario.png',
            index: 2,
            isSelected: indiceActual == 2,
            onTap: onCambiarTab,
          ),
        ],
      ),
    );
  }
}

class _ItemBarra extends StatelessWidget {
  final String icono;
  final int index;
  final bool isSelected;
  final Function(int) onTap;

  const _ItemBarra({
    required this.icono,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Ajusté el padding para que el cuadro blanco se vea bonito
        padding: const EdgeInsets.all(15), 
        decoration: BoxDecoration(
          // --- AQUÍ ESTÁ EL CAMBIO ---
          // Si está seleccionado = Blanco. Si no = Transparente
          color: isSelected ? Colors.white : Colors.transparent,
          
          // Bordes redondeados para el cuadrito
          borderRadius: BorderRadius.circular(20),
          
          // Una sombra muy suave para que el botón blanco resalte un poquito
          boxShadow: isSelected ? [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Image.asset(
          icono,
          width: 30,
          height: 30,
          // Mantenemos tu lógica de poner gris los no seleccionados
          color: isSelected ? null : Colors.grey.withOpacity(0.5), 
          scale: isSelected ? 0.9 : 1.0,
        ),
      ),
    );
  }
}