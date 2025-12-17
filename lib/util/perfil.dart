import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool cargando = true;
  String? avatarUrl; // Para futuro uso

  // Tu ID
  final miId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  // Cargar datos de Supabase
  Future<void> _cargarPerfil() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', miId!)
          .single();

      if (mounted) {
        setState(() {
          // Llenamos el input con el nombre real
          _usuarioController.text = data['username'] ?? "";
          // La contraseña NO se puede leer por seguridad, así que la dejamos vacía 
          // o con asteriscos visuales
          _passwordController.text = "******"; 
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  // Función para Guardar cambios (Por si quieres editar el nombre)
  Future<void> _guardarCambios() async {
    final nuevoNombre = _usuarioController.text.trim();
    if (nuevoNombre.isEmpty) return;

    try {
      await Supabase.instance.client.from('profiles').update({
        'username': nuevoNombre,
      }).eq('id', miId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado ✅")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo del cuerpo
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // 1. HEADER (Igual al home pero con botón volver)
            // ==========================================
            Container(
              height: 180, // Altura del fondo beige
              decoration: const BoxDecoration(
                color: Color(0xFFFEEAC9), // Beige
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    children: [
                      // Frutilla a la izquierda
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.asset('assets/images/frutilla.png', width: 70),
                        ),
                      ),
                      
                      // Botón VOLVER a la derecha (Flecha Roja)
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context), // <--- Vuelve atrás
                          child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF6B6B), size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================
            // 2. CONTENIDO DEL PERFIL (Avatar y Campos)
            // ==========================================
            // Usamos Transform para subir el avatar y que quede mitad en beige, mitad blanco
            Transform.translate(
              offset: const Offset(0, -60), // Subimos 60 pixeles
              child: Column(
                children: [
                  // AVATAR CIRCULAR
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300], // Color gris placeholder
                      border: Border.all(color: Colors.white, width: 5), // Borde blanco grueso
                    ),
                    // Aquí iría la imagen si tuviéramos subida de fotos
                    child: const Icon(Icons.person, size: 80, color: Colors.white), 
                  ),
                  
                  const SizedBox(height: 10),
                  
                  const Text(
                    "tap para cambiar la foto de perfil...",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 5),

                  // NOMBRE GRANDE DEBAJO DE LA FOTO
                  Text(
                    _usuarioController.text.isEmpty ? "Cargando..." : _usuarioController.text,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 30),

                  // === FORMULARIO ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CAMPO USUARIO
                        const Text("Usuario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usuarioController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5), // Gris muy clarito
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey), // Borde gris suave
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // CAMPO CONTRASEÑA
                        const Text("Contraseña", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true, // Ocultar texto
                          readOnly: true, // Por ahora solo lectura para no complicar con cambio de clave
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // BOTÓN GUARDAR (Opcional, para que tenga funcionalidad)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _guardarCambios,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Guardar Cambios"),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}