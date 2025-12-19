import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final myId = Supabase.instance.client.auth.currentUser?.id;
  
  // Stream para escuchar mensajes nuevos automáticamente
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    // Escuchamos la tabla 'messages', ordenados por fecha (el más nuevo arriba)
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Función para enviar mensaje a Supabase
  Future<void> _enviarMensaje() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear(); // Limpiamos el campo rápido

    try {
      await Supabase.instance.client.from('messages').insert({
        'content': text,
        'sender_id': myId,
        'message_type': 'text',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Función sencilla para mostrar la hora (ej: 14:05) sin instalar paquetes extra
  String _formatoHora(String fechaIso) {
    final fecha = DateTime.parse(fechaIso).toLocal();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return "$hora:$minuto";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Fondo del chat
      child: Column(
        children: [
          // 1. LISTA DE MENSAJES (Burbujas)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_chat_unread_outlined, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("Escribe el primer mensaje ❤️", style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Importante: los mensajes nuevos salen abajo
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final esMio = msg['sender_id'] == myId;

                    return Align(
                      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          // Azul para mí, Gris para la pareja
                          color: esMio ? const Color(0xFF007AFF) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: esMio ? const Radius.circular(20) : const Radius.circular(4),
                            bottomRight: esMio ? const Radius.circular(4) : const Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end, // Hora a la derecha
                          children: [
                            Text(
                              msg['content'] ?? "",
                              style: TextStyle(
                                color: esMio ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatoHora(msg['created_at']),
                              style: TextStyle(
                                color: esMio ? Colors.white70 : Colors.black38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. BARRA DE ESCRITURA (Input)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Botón + (Decorativo por ahora)
                const Icon(Icons.add, color: Color(0xFF007AFF), size: 30),
                const SizedBox(width: 8),
                
                // Campo de Texto
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _enviarMensaje(), // Enviar al dar Enter
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Botón Enviar (Avión de papel o Micrófono)
                GestureDetector(
                  onTap: _enviarMensaje,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}