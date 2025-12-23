import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Estados extends StatefulWidget {
  const Estados({super.key});

  @override
  State<Estados> createState() => _EstadosState();
}

class _EstadosState extends State<Estados> {
  // Variables de datos
  String nombrePareja = "..."; 
  String? idPareja; 
  Map<String, dynamic>? estadoPareja; // Último estado confirmado de la pareja
  Map<String, dynamic>? miEstadoActual; // Mi último estado confirmado en BD
  
  // --- Estado temporal (Previsualización) ---
  String? emocionSeleccionada; 
  bool enviando = false;
  bool cargando = true;
  
  final miId = Supabase.instance.client.auth.currentUser?.id;

  // MAPA DE GATITOS
  final Map<String, String> catalogoGatos = {
    'lokotron': 'assets/images/gato_1.png',
    'serio': 'assets/images/gato_2.png',
    'feliz': 'assets/images/gato_4.png',
    'pensandola': 'assets/images/gato_3.png',
  };

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    await _obtenerDatosPareja();
    if (miId != null) await _obtenerMiEstado(); 
    if (idPareja != null) await _obtenerEstadoPareja(); 
    if (mounted) setState(() => cargando = false);
  }

  Future<void> _obtenerDatosPareja() async {
    try {
      final miPerfil = await Supabase.instance.client.from('profiles').select().eq('id', miId!).single();
      idPareja = miPerfil['partner_id'];
      if (idPareja != null) {
        final perfilPareja = await Supabase.instance.client.from('profiles').select().eq('id', idPareja!).single();
        if (mounted) setState(() => nombrePareja = perfilPareja['nickname'] ?? perfilPareja['username'] ?? "Tu pareja");
      }
    } catch (e) { print("Error pareja: $e"); }
  }

  Future<void> _obtenerMiEstado() async {
    try {
      final response = await Supabase.instance.client.from('moods').select().eq('user_id', miId!).order('created_at', ascending: false).limit(1);
      if (mounted) setState(() => miEstadoActual = response.isNotEmpty ? response[0] : null);
    } catch (e) { print("Error mi estado: $e"); }
  }

  Future<void> _obtenerEstadoPareja() async {
    try {
      final response = await Supabase.instance.client.from('moods').select().eq('user_id', idPareja!).order('created_at', ascending: false).limit(1);
      if (mounted) setState(() => estadoPareja = response.isNotEmpty ? response[0] : null);
    } catch (e) { print("Error estado pareja: $e"); }
  }

  Future<void> _enviarEstado() async {
    if (emocionSeleccionada == null) return;
    setState(() => enviando = true);
    try {
      await Supabase.instance.client.from('moods').insert({
        'user_id': miId, 'mood_value': emocionSeleccionada, 'note': '', 
      });
      await _obtenerMiEstado();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Actualizaste como te sientes"), backgroundColor: Color(0xFFA1BC98), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al enviar")));
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  Widget _botonGatoPequeno(String emocion) {
    bool isSelected = emocionSeleccionada == emocion;
    return GestureDetector(
      onTap: () => setState(() => emocionSeleccionada = emocion),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 40, width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFFA1BC98) : Colors.grey.shade200, 
            width: isSelected ? 2 : 1
          ),
          image: DecorationImage(
            image: AssetImage(catalogoGatos[emocion]!), 
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    );
  }

  Widget _circuloEstadoGrande(String? emocion, {bool esPareja = false}) {
    String imagen = esPareja 
        ? 'assets/images/monito_verde.png' 
        : 'assets/images/gato_2.png'; 

    if (emocion != null && catalogoGatos.containsKey(emocion)) {
      imagen = catalogoGatos[emocion]!;
    }

    return Container(
      height: 90, width: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
        image: DecorationImage(
          image: AssetImage(imagen), 
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          opacity: emocion == null ? 0.5 : 1.0, 
        ),
      ),
      child: emocion == null && esPareja
        ? const Icon(Icons.question_mark, color: Colors.grey) 
        : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));

    String? estadoAMostrar = emocionSeleccionada ?? miEstadoActual?['mood_value'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3E0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), 
              blurRadius: 20, 
              offset: const Offset(0, 10), 
            )
          ],
        ),
        child: Column(
          children: [
            // --- NUEVO TÍTULO ARRIBA ---
            const Text(
              "¿Cómo te sientes hoy?",
              style: TextStyle(
                color: Colors.grey, 
                fontSize: 14, 
                fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 20),

            // ==================== FILA SUPERIOR (MI ZONA) ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                
                // 1. Lista de Gatitos (AHORA A LA IZQUIERDA)
                Column(
                  children: [
                     _botonGatoPequeno('lokotron'),
                     _botonGatoPequeno('serio'),
                     _botonGatoPequeno('feliz'),
                     _botonGatoPequeno('pensandola'),
                  ],
                ),

                // 2. Mi Círculo (AHORA AL MEDIO)
                _circuloEstadoGrande(estadoAMostrar),

                // 3. Nombre + Botón Enviar (SE QUEDA A LA DERECHA)
                SizedBox(
                  width: 100, 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        emocionSeleccionada?.toUpperCase() ?? "...", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color.fromARGB(255, 72, 84, 69)),
                        textAlign: TextAlign.center,
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 15),

                      if (emocionSeleccionada != null)
                        GestureDetector(
                          onTap: enviando ? null : _enviarEstado,
                          child: Container(
                            height: 45, width: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFF778873), 
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF778873).withOpacity(0.4), blurRadius: 6, offset: const Offset(0,2))
                              ]
                            ),
                            child: enviando 
                                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                          ),
                        )
                      else
                        const SizedBox(height: 45),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 20),

            // ==================== FILA INFERIOR (ZONA PAREJA) ====================
            Row(
              children: [
                 _circuloEstadoGrande(estadoPareja?['mood_value'], esPareja: true),
                 
                 const SizedBox(width: 20),

                 // TEXTOS ACTUALIZADOS
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // 1. "(Nombre) se siente..."
                     Text(
                       "$nombrePareja se siente...", 
                       style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                     ),
                     const SizedBox(height: 5),
                     // 2. ESTADO (Ej: FELIZ)
                     Text(
                       estadoPareja?['mood_value']?.toString().toUpperCase() ?? "...",
                       style: const TextStyle(
                         fontWeight: FontWeight.bold, 
                         fontSize: 18, 
                         color: Color(0xFF5A3E3E)
                        ),
                     )
                   ],
                 )
              ],
            )
          ],
        ),
      ),
    );
  }
}