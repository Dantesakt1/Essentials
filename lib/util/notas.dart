import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Notas extends StatefulWidget {
  const Notas({super.key});

  @override
  State<Notas> createState() => _NotasState();
}

class _NotasState extends State<Notas> {
  // Variables de datos
  Map<String, dynamic>? ultimaNota;
  String nombrePareja = "..."; 
  bool cargando = true;
  
  // Controlador para leer lo que el usuario escribe
  final _mensajeController = TextEditingController();

  // Tu ID de usuario
  final miId = Supabase.instance.client.auth.currentUser?.id;

  // --- NUEVO: COLORES DISPONIBLES ---
  // Mapa de colores: Nombre -> Código de Color
  final List<Color> paletaColores = [
    const Color(0xFFD0F0FD), // Azul (Original)
    const Color(0xFFFFCFCF), // Rosa
    const Color(0xFFEDF7C7), // Verde Limón Pastel
    const Color(0xFFFFF4BD), // Amarillo Pollito
  ];

  // Variable para guardar el color elegido al escribir (Por defecto el Azul)
  Color colorSeleccionado = const Color(0xFFD0F0FD);

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    await _obtenerDatosPareja();
    await _buscarNotas();       
  }

  Future<void> _obtenerDatosPareja() async {
    try {
      final miPerfil = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', miId!)
          .single();

      final idPareja = miPerfil['partner_id'];

      if (idPareja != null) {
        final perfilPareja = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', idPareja)
            .single();

        if (mounted) {
          setState(() {
            final apodo = perfilPareja['nickname'];
            final usuario = perfilPareja['username'];
            nombrePareja = apodo ?? usuario ?? "Amor"; 
          });
        }
      } else {
        if (mounted) setState(() => nombrePareja = "tu pareja");
      }
    } catch (e) {
      if (mounted) setState(() => nombrePareja = "Amor");
    }
  }

  Future<void> _buscarNotas() async {
    try {
      final response = await Supabase.instance.client
          .from('sticky_notes')
          .select()
          .neq('sender_id', miId!) 
          .order('created_at', ascending: false)
          .limit(1);

      if (mounted) {
        setState(() {
          ultimaNota = response.isNotEmpty ? response[0] : null;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  // --- NUEVO: ENVIAR CON COLOR ---
  Future<void> _enviarNota() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    // Convertimos el objeto Color a String (ej: "0xffd0f0fd") para guardarlo en la BD
    String colorString = colorSeleccionado.value.toRadixString(16);
    // Nos aseguramos que tenga el formato 0xFF...
    colorString = "0x$colorString";

    try {
      await Supabase.instance.client.from('sticky_notes').insert({
        'sender_id': miId,
        'content': texto,
        'is_active': true,
        'color': colorString, // <--- Guardamos el color aquí
      });

      _mensajeController.clear();
      // Reseteamos el color al azul por defecto para la próxima
      colorSeleccionado = const Color(0xFFD0F0FD); 
      
      if (mounted) Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Nota enviada con amor! ❤️"),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar: $e")),
      );
    }
  }

  // --- NUEVO: DIÁLOGO CON SELECTOR DE COLOR ---
  void _mostrarDialogoEscribir() {
    // Usamos StatefulBuilder para que el diálogo pueda actualizarse (cambiar colores)
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFF5E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Nota para $nombrePareja", style: const TextStyle(color: Color(0xFF5A3E3E))),
            content: Column(
              mainAxisSize: MainAxisSize.min, // Que ocupe solo lo necesario
              children: [
                TextField(
                  controller: _mensajeController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Escribe algo bonito...",
                    filled: true,
                    fillColor: Colors.white, // El input se queda blanco para leer bien
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Elige un color:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                
                // FILA DE BOLITAS DE COLORES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: paletaColores.map((color) {
                    bool esSeleccionado = colorSeleccionado == color;
                    return GestureDetector(
                      onTap: () {
                        // Actualizamos el estado SOLO del diálogo
                        setStateDialog(() {
                          colorSeleccionado = color;
                        });
                      },
                      child: Container(
                        width: 35, height: 35,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: esSeleccionado 
                              ? Border.all(color: const Color(0xFF5A3E3E), width: 2) // Borde si está elegido
                              : Border.all(color: Colors.grey.withOpacity(0.3)), // Borde suave si no
                          boxShadow: [
                             if(esSeleccionado) BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
                          ]
                        ),
                        // Check si está seleccionado
                        child: esSeleccionado 
                            ? const Icon(Icons.check, size: 20, color: Color(0xFF5A3E3E)) 
                            : null,
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _enviarNota,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Enviar"),
              ),
            ],
          );
        }
      ),
    );
  }

  // Ayudante fechas
  String _fechaEnEspanol(DateTime fecha) {
    List<String> meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    return "${fecha.day} de ${meses[fecha.month - 1]}, ${fecha.year}";
  }
  
  String _procesarFechaBD(String fechaIso) {
    try {
      return _fechaEnEspanol(DateTime.parse(fechaIso));
    } catch (e) { return ""; }
  }

  // --- NUEVO: CONVERTIR STRING BD A COLOR ---
  Color _obtenerColorDeBD(String? colorString) {
    if (colorString == null) return const Color(0xFFD0F0FD); // Azul por defecto
    try {
      // Supabase devuelve "0xff..." o "0xFF...", hay que parsearlo
      return Color(int.parse(colorString));
    } catch (e) {
      return const Color(0xFFD0F0FD); // Si falla, devuelve azul
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: Column(
        children: [
          
          if (ultimaNota == null) ...[
            // ESTADO VACÍO
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/sad.png', height: 80),
                const SizedBox(width: 15),
                const Text("Aun nada por aquí...", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            // ESTADO CON NOTA
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/happy.png', height: 60),
                const SizedBox(width: 10),
                Text("$nombrePareja te ha mandado una nota", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            
            // --- AQUÍ APLICAMOS EL COLOR DE LA BD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _obtenerColorDeBD(ultimaNota!['color']), // <--- ¡AQUÍ ESTÁ LA MAGIA!
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ultimaNota!['content'] ?? "",
                    style: const TextStyle(fontSize: 18, color: Color(0xFF5A3E3E), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_procesarFechaBD(ultimaNota!['created_at']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("De $nombrePareja", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // --- BOTÓN PARA ENVIAR ---
          GestureDetector(
            onTap: _mostrarDialogoEscribir,
            child: Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCFCF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                   BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Mándale una nota a $nombrePareja ...",
                    style: const TextStyle(fontSize: 16, color: Color(0xFF5A3E3E), fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fechaEnEspanol(DateTime.now()),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8D6E63)),
                      ),
                      const Icon(Icons.edit, color: Color(0xFF5A3E3E)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}