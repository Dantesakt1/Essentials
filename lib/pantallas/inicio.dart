import 'package:essentials_app/pantallas/calendario.dart';
import 'package:essentials_app/util/ajustes_chat.dart';
import 'package:flutter/material.dart';
import 'package:essentials_app/util/estados.dart';
import 'package:essentials_app/util/notas.dart';
import 'package:essentials_app/util/perfil.dart';
import 'package:essentials_app/util/recordatorio.dart';
import 'package:essentials_app/util/servicios.dart';
import 'package:essentials_app/util/barrita.dart';
import 'package:essentials_app/pantallas/chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _indiceActual = 0; 
  String _nombrePareja = "Cargando..."; // Texto temporal mientras carga

  @override
  void initState() {
    super.initState();
    _obtenerNombrePareja();
  }

  // Función limpia para obtener el nombre
  Future<void> _obtenerNombrePareja() async {
    try {
      final myId = Supabase.instance.client.auth.currentUser?.id;
      if (myId == null) return;

      // 1. Buscamos mi perfil
      final miPerfil = await Supabase.instance.client
          .from('profiles')
          .select('partner_id')
          .eq('id', myId)
          .single();

      final partnerId = miPerfil['partner_id'];

      if (partnerId != null) {
        // 2. Buscamos perfil de la pareja
        final perfilPareja = await Supabase.instance.client
            .from('profiles')
            .select('nickname, username')
            .eq('id', partnerId)
            .single();

        if (mounted) {
          setState(() {
            _nombrePareja = perfilPareja['nickname'] ?? perfilPareja['username'] ?? "Mi Pareja";
          });
        }
      } else {
         if (mounted) setState(() => _nombrePareja = "Sin Pareja");
      }
    } catch (e) {
      // Si falla, dejamos un nombre por defecto para no romper la UI
      if (mounted) setState(() => _nombrePareja = "Mi Amor");
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final List<Widget> paginas = [
      // PÁGINA 0: INICIO
      ListView(
        padding: const EdgeInsets.only(bottom: 100),
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

      const ChatPage(),

      const CalendarioPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      
      // Barra condicional: Chat vs Normal
      appBar: _indiceActual == 1 
          ? _barraChat() 
          : _barraNormal(), 

      body: paginas[_indiceActual],

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

  // --- BARRA NORMAL ---
  PreferredSizeWidget _barraNormal() {
    return AppBar(
      backgroundColor: const Color(0xFFD2DCB6),
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
      leadingWidth: 80,
      leading: Container(
        margin: const EdgeInsets.all(15),
        alignment: Alignment.center,
        width: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFD2DCB6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset('assets/images/gato-icon.png', height: 150, width: 150),
      ),
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
              color: const Color.fromARGB(255, 241, 241, 241),
              shape: BoxShape.circle,
            ),
            child: 
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                  Image.asset('assets/images/heart-icon.png', height: 30, width: 30, fit: BoxFit.contain),
          ),
        )
      )],
    );
  }

  // --- BARRA CHAT (NOMBRE PAREJA) ---
PreferredSizeWidget _barraChat() {
    return AppBar(
      backgroundColor: const Color(0xFFD2DCB6),
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

      // 1. Damos espacio al botón
      leadingWidth: 70, 

      // BOTÓN DE AJUSTES MEJORADO ⚙️
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AjustesChat()),
          );
        },
        child: Container(
          // 2. Márgenes ajustados para que quede centrado y grande
          margin: const EdgeInsets.fromLTRB(15, 15, 5, 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6), // Un poco más visible
            borderRadius: BorderRadius.circular(15), // Más redondeado
          ),
          // 3. Icono un poco más grande y oscuro
          child: const Icon(Icons.settings_outlined, color: Colors.black87, size: 26),
        ),
      ),

      title: Text(
        _nombrePareja,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18
        )
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 245, 245, 245),
            radius: 22,
            backgroundImage: const AssetImage('assets/images/gato_1.png'),
          ),
        )
      ],
    );
  }
}