import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final myId = Supabase.instance.client.auth.currentUser?.id;
  final ScrollController _scrollController = ScrollController();
  
  // --- AUDIO ---
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  
  // --- STREAM ---
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- LÓGICA DE ENVÍO ----------------

  // 1. TEXTO
  Future<void> _enviarTexto() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _guardarEnBD(content: text, type: 'text');
  }

  // 2. FOTOS / VIDEO
  Future<void> _enviarMultimedia(ImageSource source, {bool isVideo = false}) async {
    final picker = ImagePicker();
    XFile? file;
    if (isVideo) {
      file = await picker.pickVideo(source: source);
    } else {
      file = await picker.pickImage(source: source, imageQuality: 70); // Calidad media para rapidez
    }
    if (file != null) await _subirArchivo(File(file.path), isVideo ? 'video' : 'image');
  }

  // 3. ARCHIVOS
  Future<void> _enviarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      await _subirArchivo(File(result.files.single.path!), 'file');
    }
  }

  // 4. AUDIO (Grabar/Parar)
  Future<void> _toggleGrabacion() async {
    try {
      if (_isRecording) {
        // DETENER Y ENVIAR
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) await _subirArchivo(File(path), 'audio');
      } else {
        // EMPEZAR A GRABAR
        if (await Permission.microphone.request().isGranted) {
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => _isRecording = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Necesitamos permiso del micrófono")));
        }
      }
    } catch (e) {
      print("Error audio: $e");
      setState(() => _isRecording = false);
    }
  }

  // ---------------- SUBIDA A SUPABASE ----------------

  Future<void> _subirArchivo(File file, String type) async {
    try {
      final name = '${DateTime.now().millisecondsSinceEpoch}_${myId ?? "user"}';
      final path = '$type/$name'; // Organiza por carpetas: image/..., audio/...

      // 1. Subir al Bucket 'chat_files'
      await Supabase.instance.client.storage.from('chat_files').upload(path, file);

      // 2. Obtener URL
      final url = Supabase.instance.client.storage.from('chat_files').getPublicUrl(path);

      // 3. Guardar en BD
      await _guardarEnBD(content: url, type: type);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error subiendo: $e")));
    }
  }

  Future<void> _guardarEnBD({required String content, required String type}) async {
    await Supabase.instance.client.from('messages').insert({
      'content': content,
      'sender_id': myId,
      'message_type': type,
    });
  }

  // ---------------- UI: MENU DEL "+" ----------------
  void _mostrarMenuAdjuntos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 180,
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _botonMenu(Icons.image, Colors.purple, "Galería", () => _enviarMultimedia(ImageSource.gallery)),
            _botonMenu(Icons.camera_alt, Colors.pink, "Cámara", () => _enviarMultimedia(ImageSource.camera)),
            _botonMenu(Icons.videocam, Colors.orange, "Video", () => _enviarMultimedia(ImageSource.gallery, isVideo: true)),
            _botonMenu(Icons.insert_drive_file, Colors.blue, "Archivo", _enviarArchivo),
          ],
        ),
      ),
    );
  }

  Widget _botonMenu(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }

  // ---------------- PANTALLA PRINCIPAL ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. LISTA DE MENSAJES
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                
                if (messages.isEmpty) {
                  return Center(child: Text("Escribe algo..", style: TextStyle(color: Colors.grey[400])));
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final esMio = msg['sender_id'] == myId;
                    return _BurbujaMensaje(msg: msg, esMio: esMio);
                  },
                );
              },
            ),
          ),

          // 2. INPUT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: const Color(0xFFF9F9F9),
            child: Row(
              children: [
                // BOTÓN +
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFA1BC98), size: 30), // TU VERDE OSCURO
                  onPressed: _mostrarMenuAdjuntos,
                ),
                
                // CAMPO DE TEXTO
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
                        hintText: "Mensaje...", 
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10)
                      ),
                      onChanged: (val) {
                        setState(() {}); // Para cambiar icono Micrófono <-> Enviar
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),

                // BOTÓN DINÁMICO (ENVIAR O GRABAR)
                GestureDetector(
                  onLongPress: _controller.text.isEmpty ? _toggleGrabacion : null, // Mantener para grabar
                  onTap: _controller.text.isEmpty ? _toggleGrabacion : _enviarTexto, // Click corto
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : const Color(0xFFA1BC98), // Rojo si graba, Verde si no
                      shape: BoxShape.circle,
                      boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] : null
                    ),
                    child: Icon(
                      _controller.text.isEmpty 
                          ? (_isRecording ? Icons.stop : Icons.mic) // Micrófono o Stop
                          : Icons.send, // Avión si hay texto
                      color: Colors.white, 
                      size: 20
                    ),
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

// ---------------- WIDGET DE LA BURBUJA ----------------
class _BurbujaMensaje extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool esMio;

  const _BurbujaMensaje({required this.msg, required this.esMio});

  @override
  Widget build(BuildContext context) {
    final type = msg['message_type'] ?? 'text';
    final content = msg['content'] ?? '';
    final time = DateFormat('HH:mm').format(DateTime.parse(msg['created_at']).toLocal());

    Widget body;

    // Renderizar según tipo
    switch (type) {
      case 'image':
        body = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(content, height: 200, width: 200, fit: BoxFit.cover,
            loadingBuilder: (_, child, loading) => loading == null ? child : Container(height: 200, width: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
          ),
        );
        break;
      case 'video':
        body = Container(
          padding: const EdgeInsets.all(10),
          color: Colors.black12,
          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_circle_fill, size: 30), SizedBox(width: 10), Text("Video")]),
        );
        break;
      case 'audio':
        body = _ReproductorAudioSimple(url: content, esMio: esMio);
        break;
      case 'file':
        body = Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.attach_file), const SizedBox(width: 5), const Text("Archivo adjunto", style: TextStyle(decoration: TextDecoration.underline))]);
        break;
      default:
        body = Text(content, style: TextStyle(color: esMio ? Colors.white : Colors.black87, fontSize: 16));
    }

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: esMio ? const Color(0xFFA1BC98) : const Color(0xFFF2F2F7), // TUS COLORES
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: esMio ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: esMio ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            body,
            const SizedBox(height: 4),
            Text(time, style: TextStyle(fontSize: 10, color: esMio ? Colors.white70 : Colors.black38)),
          ],
        ),
      ),
    );
  }
}

// ---------------- REPRODUCTOR AUDIO MINI ----------------
class _ReproductorAudioSimple extends StatefulWidget {
  final String url;
  final bool esMio;
  const _ReproductorAudioSimple({required this.url, required this.esMio});

  @override
  State<_ReproductorAudioSimple> createState() => _ReproductorAudioSimpleState();
}

class _ReproductorAudioSimpleState extends State<_ReproductorAudioSimple> {
  final player = AudioPlayer();
  bool isPlaying = false;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: widget.esMio ? Colors.white : Colors.black87),
          onPressed: () async {
            if (isPlaying) {
              await player.pause();
              setState(() => isPlaying = false);
            } else {
              await player.play(UrlSource(widget.url));
              setState(() => isPlaying = true);
              player.onPlayerComplete.listen((_) => setState(() => isPlaying = false));
            }
          },
        ),
        Text("Audio Clip", style: TextStyle(color: widget.esMio ? Colors.white : Colors.black87)),
      ],
    );
  }
}