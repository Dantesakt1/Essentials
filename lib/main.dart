import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'pantallas/login.dart';


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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const PantallaLogin(),
    );
  }
}