import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:essentials_app/util/barrita.dart'; // <--- IMPORTANTE: Importa tu barrita

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final miId = Supabase.instance.client.auth.currentUser?.id;
  String _nombrePareja = "...";
  String? _idPareja;

  // Controladores
  final _tituloController = TextEditingController();
  final _precioController = TextEditingController();
  final _linkController = TextEditingController();

  // Tus Colores
  final Color colorFondo = const Color(0xFFFFFBF4); 
  final Color colorRojo = const Color(0xFFFF6B6B); 
  final Color colorTexto = const Color(0xFF5A3E3E);

  @override
  void initState() {
    super.initState();
    _obtenerDatosPareja();
  }

  Future<void> _obtenerDatosPareja() async {
    try {
      if (miId == null) return;
      final dataYo = await Supabase.instance.client.from('profiles').select('partner_id').eq('id', miId!).single();
      _idPareja = dataYo['partner_id'];

      if (_idPareja != null) {
        final dataPareja = await Supabase.instance.client.from('profiles').select('nickname').eq('id', _idPareja!).single();
        if (mounted) setState(() => _nombrePareja = dataPareja['nickname'] ?? "Tu pareja");
      }
    } catch (e) { print(e); }
  }

  // --- LÓGICA DE BASE DE DATOS (Igual que antes) ---
  Future<void> _agregarDeseo() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) return;
    try {
      await Supabase.instance.client.from('wishes').insert({
        'user_id': miId,
        'title': titulo,
        'price_estimate': double.tryParse(_precioController.text) ?? 0.0,
        'link_url': _linkController.text.trim(),
        'is_fulfilled': false,
      });
      _tituloController.clear(); _precioController.clear(); _linkController.clear();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Deseo agregado! ✨")));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }

  Future<void> _borrarDeseo(int id) async {
    await Supabase.instance.client.from('wishes').delete().eq('id', id);
  }

  Future<void> _cumplirDeseo(int id, bool estadoActual) async {
    await Supabase.instance.client.from('wishes').update({
      'is_fulfilled': !estadoActual,
      'fulfilled_by': !estadoActual ? miId : null,
    }).eq('id', id);
  }

  void _mostrarDialogoAgregar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Nuevo Deseo ✨", style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _tituloController, decoration: InputDecoration(hintText: "¿Qué deseas?", prefixIcon: Icon(Icons.star_border, color: colorRojo), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 10),
            TextField(controller: _precioController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Precio aprox", prefixIcon: Icon(Icons.attach_money, color: colorRojo), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 10),
            TextField(controller: _linkController, decoration: InputDecoration(hintText: "Link (opcional)", prefixIcon: Icon(Icons.link, color: colorRojo), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: _agregarDeseo, style: ElevatedButton.styleFrom(backgroundColor: colorRojo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Guardar", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      
      // --- 1. TU APPBAR EXACTO ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEEAC9),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
        ),
        leadingWidth: 80,
        leading: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xffffeac9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset('assets/images/frutilla.png', height: 150, width: 150),
        ),
        title: Text("Wishlist", style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          GestureDetector(
            onTap: () {
              // CAMBIO IMPORTANTE: Volver atrás en lugar de ir al perfil
              Navigator.pop(context);
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              width: 50, // Le di ancho fijo para que sea redondo perfecto
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffFD7979), width: 2)
              ),
              // Usamos un icono de flecha atrás pero con TU estilo de contenedor
              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xffFD7979), size: 20),
            ),
          )
        ],
      ),

      // --- 2. CONTENIDO PRINCIPAL ---
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // SECCIÓN 1: MI WISHLIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mis deseos...", style: TextStyle(color: colorRojo, fontSize: 16, decoration: TextDecoration.underline)),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoAgregar,
                icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                label: const Text("Agregar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: colorRojo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
              )
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder(
            stream: Supabase.instance.client.from('wishes').stream(primaryKey: ['id']).eq('user_id', miId!).order('created_at'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final deseos = snapshot.data as List<dynamic>;
              if (deseos.isEmpty) return const Center(child: Text("Tu lista está vacía.", style: TextStyle(color: Colors.grey)));
              return Column(children: deseos.map((d) => _buildWishCard(d, true)).toList());
            },
          ),

          const SizedBox(height: 40),

          // SECCIÓN 2: PAREJA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colorRojo, borderRadius: BorderRadius.circular(15)),
            child: Text("Deseos de $_nombrePareja", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 15),
          if (_idPareja != null)
            StreamBuilder(
              stream: Supabase.instance.client.from('wishes').stream(primaryKey: ['id']).eq('user_id', _idPareja!).order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final deseos = snapshot.data as List<dynamic>;
                if (deseos.isEmpty) return const Center(child: Text("Aún no ha pedido nada.", style: TextStyle(color: Colors.grey)));
                return Column(children: deseos.map((d) => _buildWishCard(d, false)).toList());
              },
            )
          else
            const Center(child: Text("Vincula a tu pareja ❤️")),
        ],
      ),

      // --- 3. TU BARRITA DE ABAJO ---
      bottomNavigationBar: BarritaNavegacion(
        // La marcamos como que estamos en una pestaña "especial" o la del medio
        indiceActual: 3, // Ponemos un índice que no existe (3) para que ninguno se ponga blanco, o pon 0 si quieres que marque Home
        onCambiarTab: (index) {
          // Si tocan algo en la barra, volvemos al inicio y cambiamos tab
          Navigator.pop(context); 
          // Nota: Para cambiar el tab real en Inicio, necesitaríamos pasar una función callback más compleja,
          // pero hacer pop() es lo más natural para volver.
        },
      ),
    );
  }

  // Tarjeta auxiliar (Mismo diseño limpio)
  Widget _buildWishCard(Map<String, dynamic> item, bool esMio) {
    bool cumplido = item['is_fulfilled'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: cumplido ? Border.all(color: Colors.green.shade200, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cumplido ? Colors.green.shade50 : colorRojo.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(cumplido ? Icons.check_circle : (esMio ? Icons.card_giftcard : Icons.favorite), color: cumplido ? Colors.green : colorRojo),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTexto, decoration: cumplido ? TextDecoration.lineThrough : null)),
              if (item['price_estimate'] > 0) Text("\$${item['price_estimate']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
          ),
          if (esMio) IconButton(icon: Icon(Icons.delete_outline, color: Colors.grey[400]), onPressed: () => _borrarDeseo(item['id']))
          else IconButton(icon: Icon(cumplido ? Icons.check_box : Icons.check_box_outline_blank, color: cumplido ? Colors.green : Colors.grey), onPressed: () => _cumplirDeseo(item['id'], cumplido)),
        ],
      ),
    );
  }
}