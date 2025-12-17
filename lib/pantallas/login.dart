import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Para acceder a la variable 'supabase'
import 'navbar.dart';  // Para ir al menú principal

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // Controladores de texto (donde se guarda lo que escribes)
  final _usuarioController = TextEditingController();
  final _claveController = TextEditingController();
  bool _cargando = false;

  Future<void> _iniciarSesion() async {
    // Validamos que no estén vacíos
    if (_usuarioController.text.isEmpty || _claveController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor llena los campos")),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      // TRUCO: Agregamos el dominio @amor.cl automáticamente al nombre
      final emailCompleto = "${_usuarioController.text.trim()}@amor.cl";
      
      await supabase.auth.signInWithPassword(
        email: emailCompleto,
        password: _claveController.text.trim(),
      );
      
      if (mounted) {
        // Si todo sale bien, vamos a la pantalla principal y borramos el login del historial
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const PantallaNavegacion())
        );
      }
    } on AuthException catch (error) {
      // Errores de Supabase (contraseña mala, usuario no existe)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${error.message}"), backgroundColor: Colors.red),
      );
    } catch (error) {
      // Otros errores
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error inesperado"), backgroundColor: Colors.red),
      );
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla del celular
    final tamano = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco base
      body: SingleChildScrollView( // Permite hacer scroll si sale el teclado
        child: SizedBox(
          height: tamano.height,
          child: Stack(
            children: [
              // 1. EL FONDO BEIGE CON CURVA (Parte superior)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: tamano.height * 0.35, // Ocupa el 35% de arriba
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF5E1), // Color Crema
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(60), // La curva estética
                    ),
                  ),
                ),
              ),

              // 2. EL CONTENIDO (Frutilla y Formulario)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: tamano.height * 0.12), // Espacio arriba
                    
                    // LA FRUTILLA 🍓
                    Image.asset(
                      'assets/images/frutilla.png', 
                      width: 80, 
                    ),

                    SizedBox(height: tamano.height * 0.25), // Bajamos hasta la zona blanca

                    // CAMPO USUARIO
                    TextField(
                      controller: _usuarioController,
                      decoration: InputDecoration(
                        labelText: "Usuario",
                        filled: true,
                        fillColor: Colors.grey[100], // Gris muy clarito
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // CAMPO CONTRASEÑA
                    TextField(
                      controller: _claveController,
                      obscureText: true, // Ocultar texto
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // BOTÓN INICIAR SESIÓN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B), // Rojo Fresa
                          foregroundColor: Colors.white, // Letra blanca
                          elevation: 0, // Sin sombra (Diseño plano)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Botón redondo
                          ),
                        ),
                        child: _cargando 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Iniciar sesión",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}