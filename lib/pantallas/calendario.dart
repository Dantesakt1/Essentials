import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// IMPORTAMOS LA PANTALLA NUEVA
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
          final fechaInicio = DateTime.parse(event['start_time']).toLocal();
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
      print("Error cargando eventos: $e");
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  // --- FUNCIÓN PARA ABRIR EL FORMULARIO ---
  Future<void> _abrirFormulario() async {
    // Si no hay día seleccionado, usamos hoy
    final fecha = _selectedDay ?? DateTime.now();

    // Navegamos y esperamos el resultado (true si guardó)
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NuevoEvento(fechaSeleccionada: fecha)),
    );

    // Si devolvió true, recargamos los eventos para ver el puntito
    if (resultado == true) {
      await _cargarEventos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Plan añadido al calendario!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_idiomaCargado) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFD7979)));
    }

    return Container(
      color: const Color(0xFFFFFBF4),
      child: Column(
        children: [
          // --- 1. CALENDARIO ---
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFD7979).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay, // ESTO PONE LOS PUNTITOS AUTOMÁTICAMENTE

              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontSize: 19, 
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5A3E3E),
                ),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Color(0xFFFD7979), size: 30),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Color(0xFFFD7979), size: 30),
              ),

              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Color(0xFFFD7979),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                selectedDecoration: BoxDecoration(
                  color: Color(0xFFFD7979),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFFEEAC9),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Color(0xFF5A3E3E), 
                  fontWeight: FontWeight.bold
                ),
              ),

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvents = _getEventsForDay(selectedDay);
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),

          // --- 2. LISTA DE PLANES ---
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay != null 
                          ? DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDay!).toUpperCase()
                          : "SELECCIONA UN DÍA",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.grey[400],
                        ),
                      ),
                      // BOTÓN + PEQUEÑO
                      GestureDetector(
                        onTap: _abrirFormulario, // Llama a la pantalla nueva
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEEAC9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 20, color: Color(0xFF5A3E3E)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: _selectedEvents.isEmpty
                        ? _EmptyState(onPressed: _abrirFormulario)
                        : ListView.builder(
                            itemCount: _selectedEvents.length,
                            itemBuilder: (context, index) {
                              final event = _selectedEvents[index];
                              return _EventoItem(
                                titulo: event['title'] as String? ?? 'Sin título',
                                descripcion: event['description'] as String? ?? '',
                                fechaHora: event['start_time'] as String?,
                                categoria: event['category'] as String?,
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onPressed;
  const _EmptyState({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Sin planes para este día",
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: onPressed, 
            child: const Text("Añadir un plan +", style: TextStyle(color: Color(0xFFFD7979)))
          )
        ],
      ),
    );
  }
}

class _EventoItem extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String? fechaHora;
  final String? categoria;

  const _EventoItem({
    required this.titulo,
    required this.descripcion,
    this.fechaHora,
    this.categoria,
  });

  @override
  Widget build(BuildContext context) {
    String horaStr = "--:--";
    if (fechaHora != null) {
      final dt = DateTime.parse(fechaHora!).toLocal();
      horaStr = DateFormat('HH:mm').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                horaStr,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF5A3E3E)),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFD7979),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (categoria?.isNotEmpty == true) 
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEAC9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      categoria!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}