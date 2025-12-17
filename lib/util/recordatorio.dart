import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha bonito

class Recordatorio extends StatefulWidget {
  const Recordatorio({super.key});

  @override
  State<Recordatorio> createState() => _RecordatorioState();
}

class _RecordatorioState extends State<Recordatorio> {
  // Variables para guardar los datos del evento
  Map<String, dynamic>? eventoMasCercano;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerEvento();
  }

  // Lógica para pedir el evento a Supabase
  Future<void> _obtenerEvento() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Consulta a la tabla 'events'
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .gte('start_time', now)       // 1. Que la fecha sea mayor o igual a hoy
          .order('start_time', ascending: true) // 2. El más cercano primero
          .limit(1);                    // 3. Solo quiero uno

      if (mounted) {
        setState(() {
          if (response.isNotEmpty) {
            eventoMasCercano = response[0];
          } else {
            eventoMasCercano = null; // No hay eventos futuros
          }
          cargando = false;
        });
      }
    } catch (e) {
      print("Error buscando evento: $e");
      if (mounted) setState(() => cargando = false);
    }
  }

  // Ayudante para formatear la fecha (Ej: "25 de Diciembre")
  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      // Usamos DateFormat de intl. 
      // Si quieres español asegúrate de inicializarlo en el main, 
      // por ahora usaremos formato numérico limpio o inglés simple para que no falle.
      return DateFormat('dd/MM - HH:mm').format(fecha); 
    } catch (e) {
      return "--/--";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Container(
        width: double.infinity, // Que ocupe todo el ancho disponible
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xffF5ECDD), // Tu color beige
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            // 1. IMAGEN DEL GATO/TÍTULO
            Image.asset(
              'assets/images/recordatorio.png',
              height: 120, // Ajusta según tu imagen
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 15), // Espacio entre imagen y cajita blanca

            // 2. CAJITA BLANCA CON DATOS DEL EVENTO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 50,
              offset: const Offset(0, 5))],
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: cargando
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2)) // Cargando...
                  : eventoMasCercano == null
                      ? const Column(
                          children: [
                            Text("Sin planes próximos", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("¡Añade uno en el calendario!", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      : Column(
                          children: [
                            // Muestra la FECHA
                            Text(
                              _formatearFecha(eventoMasCercano!['start_time']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Muestra el TÍTULO (En rojo como tu diseño)
                            Text(
                              eventoMasCercano!['title'] ?? "Evento",
                              style: const TextStyle(
                                color: Color(0xffFD7979), // Rojo Fresa
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}