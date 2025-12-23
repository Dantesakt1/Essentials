import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:essentials_app/util/nuevo_evento.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _idiomaCargado = false;

  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _selectedEvents = [];

  final Color colorVerdeOscuro = const Color(0xFF778873);
  final Color colorVerdeMedio = const Color(0xFFA1BC98);
  final Color colorVerdeClaro = const Color(0xFFD2DCB6);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('es_ES', null).then((_) {
      if (mounted) setState(() => _idiomaCargado = true);
    });
    _cargarEventos();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  Future<void> _cargarEventos() async {
    try {
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .order('start_time', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      Map<DateTime, List<Map<String, dynamic>>> eventsLoaded = {};

      for (var event in data) {
        if (event['start_time'] != null) {
          final fechaInicio = DateTime.parse(event['start_time']); // SIN toLocal() para leer tal cual
          final fechaNormalizada = _normalizeDate(fechaInicio);

          if (eventsLoaded[fechaNormalizada] == null) {
            eventsLoaded[fechaNormalizada] = [];
          }
          eventsLoaded[fechaNormalizada]!.add(event);
        }
      }

      if (mounted) {
        setState(() {
          _events = eventsLoaded;
          if (_selectedDay != null) {
             _selectedEvents = _getEventsForDay(_selectedDay!);
          }
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  // ABRIR FORMULARIO (Crear o Editar)
  Future<void> _abrirFormulario({Map<String, dynamic>? evento}) async {
    final fecha = _selectedDay ?? DateTime.now();
    
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevoEvento(
          fechaSeleccionada: fecha, 
          eventoParaEditar: evento // Pasamos el evento si es edición
        )
      ),
    );

    if (resultado == true) {
      await _cargarEventos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(evento == null ? "Plan creado" : "Plan actualizado")),
      );
    }
  }

  Future<void> _eliminarEvento(int id) async {
    try {
      await Supabase.instance.client.from('events').delete().eq('id', id);
      await _cargarEventos();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eliminado correctamente")));
    } catch(e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    if (!_idiomaCargado) return const Center(child: CircularProgressIndicator());

    return Container(
      color: const Color.fromARGB(206, 236, 247, 223),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: colorVerdeMedio.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]),
            child: TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              headerStyle: HeaderStyle(titleCentered: true, formatButtonVisible: false, titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colorVerdeOscuro), leftChevronIcon: Icon(Icons.chevron_left_rounded, color: colorVerdeMedio, size: 30), rightChevronIcon: Icon(Icons.chevron_right_rounded, color: colorVerdeMedio, size: 30)),
              calendarStyle: CalendarStyle(markerDecoration: BoxDecoration(color: colorVerdeMedio, shape: BoxShape.circle), selectedDecoration: BoxDecoration(color: colorVerdeMedio, shape: BoxShape.circle), todayDecoration: BoxDecoration(color: colorVerdeClaro, shape: BoxShape.circle), todayTextStyle: TextStyle(color: colorVerdeMedio, fontWeight: FontWeight.bold)),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; _selectedEvents = _getEventsForDay(selectedDay); });
                }
              },
              onPageChanged: (focusedDay) { _focusedDay = focusedDay; },
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedDay != null ? DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDay!).toUpperCase() : "SELECCIONA UN DÍA", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[400])),
                      GestureDetector(
                        onTap: () => _abrirFormulario(), // Crear nuevo
                        child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: colorVerdeOscuro, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, size: 20, color: Colors.white)),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _selectedEvents.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey[300]), const SizedBox(height: 10), Text("Sin planes", style: TextStyle(color: Colors.grey[400]))]))
                      : ListView.builder(
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = _selectedEvents[index];
                            return _EventoItem(
                              titulo: event['title'] ?? 'Sin título',
                              descripcion: event['description'] ?? '',
                              fechaHora: event['start_time'],
                              categoria: event['category'],
                              // BOTONES CONECTADOS
                              onEdit: () => _abrirFormulario(evento: event),
                              onDelete: () {
                                showDialog(context: context, builder: (ctx) => AlertDialog(
                                  title: const Text("¿Borrar?"),
                                  content: const Text("Se eliminará para siempre."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")), TextButton(onPressed: () { Navigator.pop(ctx); _eliminarEvento(event['id']); }, child: const Text("Borrar", style: TextStyle(color: Colors.red)))]
                                ));
                              },
                            );
                          },
                        ),
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

class _EventoItem extends StatelessWidget {
  final String titulo, descripcion; final String? fechaHora, categoria;
  final VoidCallback onEdit, onDelete;

  const _EventoItem({required this.titulo, required this.descripcion, this.fechaHora, this.categoria, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    String horaStr = "--:--";
    if (fechaHora != null) {
      final dt = DateTime.parse(fechaHora!); // Sin toLocal() para mantener hora exacta
      horaStr = DateFormat('HH:mm').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          // Hora
          Text(horaStr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color.fromARGB(255, 94, 110, 91))),
          const SizedBox(width: 15),
          // Línea
          Container(width: 4, height: 50, decoration: BoxDecoration(color: const Color(0xFFA1BC98), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 15),
          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (descripcion.isNotEmpty) Text(descripcion, style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (categoria != null && categoria!.isNotEmpty) Text(categoria!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF778873))),
            ]),
          ),
          // ICONOS DE ACCIÓN
          Row(children: [
            IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.grey), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 10),
            IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[300]), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ])
        ],
      ),
    );
  }
}