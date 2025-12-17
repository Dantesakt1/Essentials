import 'package:essentials_app/util/notas.dart';
import 'package:essentials_app/util/recordatorio.dart';
import 'package:flutter/material.dart';


class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFEEAC9),
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),

        //FRUTILLA
        leadingWidth: 80,
        leading: Container(
          margin: EdgeInsets.all(10),
          alignment: Alignment.center,
          width: 40,
          child: Image.asset('assets/images/frutilla.png',
            height: 150,
            width: 150),
          decoration: BoxDecoration(
            color: Color(0xffffeac9),
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // MANZANA
        actions: [
          GestureDetector(
            onTap: () {
              // Acción al tocar la manzana (si es necesario)
            },
          child: Container(
          margin: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: Image.asset('assets/images/manzana-icon.png',
            height: 40,
            width: 40),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xffFD7979), width: 2)
          ),
        )
      )
        ],
      ),
      body: ListView(
        children: [
          Recordatorio(),
          Notas()
        ],
      ),
    );
  }
}