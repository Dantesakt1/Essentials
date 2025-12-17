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
  String nombrePareja = "..."; // Aquí guardaremos el nombre (ej: "Kenita")
  bool cargando = true;
  
  // Controlador para leer lo que el usuario escribe
  final _mensajeController = TextEditingController();

  // Tu ID de usuario
  final miId = Supabase.instance.client.auth.currentUser?.id;

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

  // Función maestra para cargar notas y nombres al mismo tiempo
  Future<void> _cargarTodo() async {
    await _obtenerDatosPareja(); // 1. Averiguar nombre de la pareja
    await _buscarNotas();        // 2. Buscar si hay notas
  }

  // --- NUEVA: OBTENER NOMBRE DE LA PAREJA ---
Future<void> _obtenerDatosPareja() async {
    try {
      // 1. Buscamos MI perfil para obtener el ID de mi pareja
      final miPerfil = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', miId!)
          .single();

      final idPareja = miPerfil['partner_id'];

      if (idPareja != null) {
        // 2. Buscamos el perfil de la PAREJA
        final perfilPareja = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', idPareja)
            .single();

        if (mounted) {
          setState(() {
            // PRIORIDAD: 1. Nickname (Apodo), 2. Username, 3. "Amor"
            final apodo = perfilPareja['nickname'];
            final usuario = perfilPareja['username'];
            
            // Si apodo no es nulo, úsalo. Si no, usa usuario. Si no, "Amor".
            nombrePareja = apodo ?? usuario ?? "Amor"; 
          });
        }
      } else {
        // Si no tienes pareja enlazada en la BD
        if (mounted) setState(() => nombrePareja = "tu pareja");
      }
    } catch (e) {
      print("Error buscando pareja: $e");
      if (mounted) setState(() => nombrePareja = "Amor");
    }
  }

  // 1. BUSCAR NOTAS
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
      print("Error buscando notas: $e");
      if (mounted) setState(() => cargando = false);
    }
  }

  // 2. ENVIAR NOTA
  Future<void> _enviarNota() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    try {
      await Supabase.instance.client.from('sticky_notes').insert({
        'sender_id': miId,
        'content': texto,
        'is_active': true,
      });

      _mensajeController.clear();
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

  // 3. VENTANA EMERGENTE
  void _mostrarDialogoEscribir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Nota para $nombrePareja", style: const TextStyle(color: Color(0xFF5A3E3E))),
        content: TextField(
          controller: _mensajeController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Escribe algo bonito...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
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
      ),
    );
  }

  // --- NUEVA: FECHA EN ESPAÑOL MANUAL ---
  // Hacemos esto manual para no configurar Locales complejos por ahora
  String _fechaEnEspanol(DateTime fecha) {
    List<String> meses = [
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return "${fecha.day} de ${meses[fecha.month - 1]}, ${fecha.year}";
  }

  // Ayudante para convertir el string de Supabase a DateTime
  String _procesarFechaBD(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return _fechaEnEspanol(fecha);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: Column(
        children: [
          
          // --- LÓGICA DE VISUALIZACIÓN ---
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
                // AQUÍ USAMOS EL NOMBRE DE LA PAREJA
                Text("$nombrePareja te ha mandado una nota", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD0F0FD),
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
                      // FECHA DE LA NOTA
                      Text(_procesarFechaBD(ultimaNota!['created_at']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      // QUIEN LA MANDÓ
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
                  // AQUÍ TAMBIÉN USAMOS EL NOMBRE
                  Text(
                    "Mándale una nota a $nombrePareja ...",
                    style: const TextStyle(fontSize: 16, color: Color(0xFF5A3E3E), fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // FECHA DE HOY (Actualizada al momento)
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