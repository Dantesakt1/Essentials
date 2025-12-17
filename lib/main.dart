import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Importamos tus pantallas con nombres en español
import 'pantallas/login.dart';
import 'pantallas/navbar.dart'; 

// 1. CONFIGURACIÓN INICIAL
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos la conexión a Supabase
  await Supabase.initialize(
    url: 'https://xwezvyofkgmmuutbevao.supabase.co', 
    anonKey: 'sb_publishable_NJg3bxDpAP8JxaDJ_RcnEw_XjrX1IzD',
  );

  runApp(const MiApp());
}

// Variable global para usar la base de datos en cualquier parte
final supabase = Supabase.instance.client;

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Essentials',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B), // Rojo Fresa
          background: const Color(0xFFFFF5E1), // Crema fondo
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(), // Fuente moderna
      ),
      // LÓGICA DE INICIO:
      // Si hay sesión activa -> Vamos a la Pantalla de Navegación (Home)
      // Si no -> Vamos a la Pantalla de Login
      home: supabase.auth.currentSession != null 
          ? const PantallaNavegacion() 
          : const PantallaLogin(),
    );
  }
}