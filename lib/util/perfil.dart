import 'dart:io'; // Necesario para manejar archivos
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // El paquete que instalamos

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool cargando = true;
  bool subiendoFoto = false; // Para mostrar cargando en la foto
  
  String? avatarUrl; // Aquí guardaremos el link de Supabase
  File? _archivoImagen; // Aquí guardaremos la foto temporal del celular

  final miId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', miId!)
          .single();

      if (mounted) {
        setState(() {
          _usuarioController.text = data['username'] ?? "";
          _passwordController.text = "******"; 
          avatarUrl = data['avatar_url']; // <--- Cargamos la URL de la foto si existe
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  // --- NUEVA FUNCIÓN: CAMBIAR FOTO ---
  Future<void> _cambiarFoto() async {
    final ImagePicker picker = ImagePicker();
    // 1. Abrir galería
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    
    if (imagen == null) return; // Si canceló, no hacemos nada

    setState(() {
      _archivoImagen = File(imagen.path); // Mostramos la foto localmente
      subiendoFoto = true;
    });

    try {
      // 2. Crear nombre único para la foto (ej: mi_id_fecha.jpg)
      final nombreArchivo = '/$miId/perfil_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 3. Subir a Supabase Storage (Bucket 'avatars')
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(nombreArchivo, _archivoImagen!, fileOptions: const FileOptions(upsert: true));

      // 4. Obtener la URL pública para verla
      final urlPublica = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(nombreArchivo);

      // 5. Guardar la URL en la tabla 'profiles'
      await Supabase.instance.client.from('profiles').update({
        'avatar_url': urlPublica,
      }).eq('id', miId!);

      if (mounted) {
        setState(() {
          avatarUrl = urlPublica;
          subiendoFoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Foto actualizada! 📸")),
        );
      }

    } catch (e) {
      print("Error subiendo foto: $e");
      if (mounted) {
        setState(() => subiendoFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen")),
        );
      }
    }
  }

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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFFEEAC9),
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
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.asset('assets/images/frutilla.png', width: 70),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
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

            // 2. CONTENIDO (Avatar Interactivo)
            Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                children: [
                  // --- AVATAR CON GESTURE DETECTOR ---
                  GestureDetector(
                    onTap: subiendoFoto ? null : _cambiarFoto, // <--- CLIC PARA CAMBIAR FOTO
                    child: Stack(
                      children: [
                        Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                            border: Border.all(color: Colors.white, width: 5),
                            // Lógica para mostrar la imagen correcta
                            image: _archivoImagen != null
                                ? DecorationImage(image: FileImage(_archivoImagen!), fit: BoxFit.cover) // 1. Foto recién seleccionada
                                : avatarUrl != null
                                    ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover) // 2. Foto de la BD
                                    : null, // 3. Sin foto
                          ),
                          child: _archivoImagen == null && avatarUrl == null
                              ? const Icon(Icons.person, size: 80, color: Colors.white) // Icono por defecto
                              : null,
                        ),
                        
                        // Icono de camarita pequeño para indicar que se puede editar
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B6B),
                              shape: BoxShape.circle,
                            ),
                            child: subiendoFoto 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  const Text(
                    "tap para cambiar la foto de perfil...",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 5),

                  Text(
                    _usuarioController.text.isEmpty ? "Cargando..." : _usuarioController.text,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 30),

                  // FORMULARIO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Usuario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usuarioController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text("Contraseña", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          readOnly: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
                          ),
                        ),
                        
                        const SizedBox(height: 30),

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