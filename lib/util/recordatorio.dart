import 'package:flutter/material.dart';

class Recordatorio extends StatelessWidget {
  const Recordatorio({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Container(
        child: Image.asset('assets/images/recordatorio.png',
        height: 350,
        width: 350),
        decoration: BoxDecoration(
          
          color: Color(0xffffeac9),
          borderRadius: BorderRadius.circular(50),
        )
      )
    );
  }
}