import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Notas extends StatefulWidget {
  const Notas({super.key});

  @override
  State<Notas> createState() => _NotasState();
}

class _NotasState extends State<Notas> {
  String nombrePareja = "...";
  final miId = Supabase.instance.client.auth.currentUser?.id;
  
  // --- NUEVA VARIABLE DE ESTADO ---
  bool _tieneNotasPareja = false; // Empieza asumiendo que no hay

  // Controlador para escribir
  final _mensajeController = TextEditingController();

  // --- COLORES ---
  final List<Color> paletaColores = [
    const Color(0xFFD0F0FD), // Azul
    const Color(0xFFFFCFCF), // Rosa
    const Color(0xFFEDF7C7), // Verde
    const Color(0xFFFFF4BD), // Amarillo
  ];
  Color colorSeleccionado = const Color(0xFFD0F0FD);

  @override
  void initState() {
    super.initState();
    _obtenerNombrePareja();
    _verificarNotasPareja(); // <--- Verificamos al iniciar
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _obtenerNombrePareja() async {
    try {
      if (miId == null) return;
      final dataYo = await Supabase.instance.client.from('profiles').select('partner_id').eq('id', miId!).single();
      final partnerId = dataYo['partner_id'];
      if (partnerId != null) {
        final dataPareja = await Supabase.instance.client.from('profiles').select('nickname, username').eq('id', partnerId).single();
        if (mounted) {
          setState(() => nombrePareja = dataPareja['nickname'] ?? dataPareja['username'] ?? "Tu pareja");
        }
      }
    } catch (e) { print("Error obteniendo nombre: $e"); }
  }

  // --- NUEVA FUNCIÓN PARA VERIFICAR SI HAY NOTAS ---
  Future<void> _verificarNotasPareja() async {
    if (miId == null) return;
    try {
      // Buscamos si existe al menos UNA nota donde yo NO soy el remitente
      final response = await Supabase.instance.client
          .from('sticky_notes')
          .select('id') // Solo necesitamos un campo cualquiera
          .neq('sender_id', miId!)
          .limit(1) // Solo necesitamos 1 para saber si hay
          .maybeSingle(); // Devuelve null si no hay nada

      if (mounted) {
        setState(() {
          _tieneNotasPareja = response != null; // Si response no es null, es que hay notas
        });
      }
    } catch (e) {
      print("Error verificando notas: $e");
    }
  }

  // --- 1. ENVIAR NOTA A SUPABASE ---
  Future<void> _enviarNota() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;
    String colorString = "0x${colorSeleccionado.value.toRadixString(16)}";
    try {
      await Supabase.instance.client.from('sticky_notes').insert({
        'sender_id': miId, 'content': texto, 'is_active': true, 'color': colorString,
      });
      _mensajeController.clear();
      colorSeleccionado = paletaColores[0]; 
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Nota enviada! 💌"), backgroundColor: Color(0xFFFD7979)));
    } catch (e) { print("Error enviando: $e"); }
  }

  // --- 2. DIÁLOGO PARA CREAR (EL "+") ---
  void _abrirCrearNota() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Nota para $nombrePareja", style: const TextStyle(color: Color(0xFF5A3E3E), fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _mensajeController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Escribe algo bonito...", hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true, fillColor: const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                const Text("Color de la notita:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: paletaColores.map((color) {
                    bool isSelected = colorSeleccionado == color;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => colorSeleccionado = color),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black54, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: _enviarNota,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFD7979), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Enviar", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- 3. VER HISTORIAL (BOTTOM SHEET) ---
  void _verHistorial() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Notas de $nombrePareja ❤️", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A3E3E))),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: Supabase.instance.client
                    .from('sticky_notes')
                    .stream(primaryKey: ['id'])
                    .neq('sender_id', miId!)
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final notas = snapshot.data as List<dynamic>;
                  
                  // AQUÍ TAMBIÉN ACTUALIZAMOS EL ESTADO SI CAMBIA EN TIEMPO REAL
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_tieneNotasPareja != notas.isNotEmpty && mounted) {
                        setState(() => _tieneNotasPareja = notas.isNotEmpty);
                      }
                  });

                  if (notas.isEmpty) {
                    return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mark_email_unread_outlined, size: 40, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("Aún no tienes notas de $nombrePareja", style: const TextStyle(color: Colors.grey)),
                      ],
                    ));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notas.length,
                    itemBuilder: (context, index) {
                      final nota = notas[index];
                      final colorBg = _parsearColor(nota['color']);
                      final fecha = DateTime.parse(nota['created_at']).toLocal();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: colorBg, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nota['content'], style: const TextStyle(fontSize: 16, color: Color(0xFF5A3E3E), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            Align(alignment: Alignment.bottomRight, child: Text(DateFormat('d MMM • HH:mm').format(fecha), style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4)))),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parsearColor(String? colorString) {
    if (colorString == null) return const Color(0xFFD0F0FD);
    try { return Color(int.parse(colorString)); } catch (e) { return const Color(0xFFD0F0FD); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // --- 1. SECCIÓN CONDICIONAL (GATO + TEXTO) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen condicional
              Image.asset(
                _tieneNotasPareja ? 'assets/images/happy.png' : 'assets/images/sad.png',
                height: 80, // Tamaño ajustado al diseño minimalista
              ), 
              const SizedBox(width: 15),
              // Texto condicional
              Flexible(
                child: Text(
                  _tieneNotasPareja 
                      ? "$nombrePareja te ha mandado una nota"
                      : "Aun nada por aquí...",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // 2. BOTÓN "Ver notas"
          SizedBox(
            width: 200,
            height: 45,
            child: ElevatedButton(
              onPressed: _verHistorial,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5ECDD),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("Ver notas", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 20),

          // 3. BOTÓN "+"
          GestureDetector(
            onTap: _abrirCrearNota,
            child: Container(
              width: 50, height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF5ECDD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          )
        ],
      ),
    );
  }
}