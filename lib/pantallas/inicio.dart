import 'package:essentials_app/util/recordatorio.dart';
import 'package:flutter/material.dart';


class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFEEAC9),
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: Image.asset('assets/images/frutilla.png',
            height: 100,
            width: 100),
          decoration: BoxDecoration(
            color: Color(0xffffeac9),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        actions: [
          Container(
          margin: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: Image.asset('assets/images/manzana-icon.png',
            height: 50,
            width: 50),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xffFD7979), width: 2)
          ),
        )
        ],
      ),
      body: ListView(
        children: [
          Recordatorio()
        ],
      ),
    );
  }
}