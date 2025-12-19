import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NuevoEvento extends StatefulWidget {
  final DateTime fechaSeleccionada;

  const NuevoEvento({super.key, required this.fechaSeleccionada});

  @override
  State<NuevoEvento> createState() => _NuevoEventoState();
}

class _NuevoEventoState extends State<NuevoEvento> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _categoriaController = TextEditingController();

  DateTime _horaSeleccionada = DateTime.now();
  bool _cargando = false;

  // TU PALETA DE COLORES
  final Color colorFondo = const Color(0xFFFFFBF4);      // Crema Fondo
  final Color colorBorde = const Color(0xFFFEEAC9);      // Beige Borde
  final Color colorAcento = const Color(0xFFFD7979);     // Rojo Manzana
  final Color colorIconoFondo = const Color(0xFFFFF0F0); // Rojo muy clarito
  final Color colorTexto = const Color(0xFF5A3E3E);      // Marrón oscuro

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
  }

  Future<void> _guardarEvento() async {
    if (_tituloController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("¡Falta el título!"),
          content: const Text("Escribe qué vamos a hacer para poder guardar."),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final myId = Supabase.instance.client.auth.currentUser?.id;
      final fechaFinal = DateTime(
        widget.fechaSeleccionada.year,
        widget.fechaSeleccionada.month,
        widget.fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      await Supabase.instance.client.from('events').insert({
        'title': _tituloController.text.trim(),
        'description': _descripcionController.text.trim(),
        'start_time': fechaFinal.toIso8601String(),
        'category': _categoriaController.text.trim().isEmpty ? 'General' : _categoriaController.text.trim(),
        'created_by': myId,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarSelectorHora() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colorBorde)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      "Listo", 
                      style: TextStyle(color: colorAcento, fontWeight: FontWeight.bold, fontSize: 17)
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _horaSeleccionada,
                onDateTimeChanged: (val) => setState(() => _horaSeleccionada = val),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechaString = DateFormat('EEEE, d MMMM', 'es_ES').format(widget.fechaSeleccionada);

    return Scaffold(
      backgroundColor: colorFondo,
      
      appBar: AppBar(
        backgroundColor: colorFondo,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Quitamos la flecha automática
        title: Text(
          "Nuevo Plan", 
          style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold, fontSize: 18)
        ),
      ),
      
      // Usamos Column para separar el contenido scrolleable de los botones fijos abajo
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // --- BLOQUE 1: TÍTULO ---
                    _CustomGroup(
                      colorBorde: colorBorde,
                      children: [
                        TextField(
                          controller: _tituloController,
                          style: TextStyle(fontSize: 18, color: colorTexto, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: "¿Qué vamos a hacer?",
                            hintStyle: TextStyle(color: colorTexto.withOpacity(0.3)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            isDense: true,
                            icon: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Icon(Icons.favorite, color: colorAcento, size: 24),
                            )
                          ),
                          cursorColor: colorAcento,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text("FECHA Y HORA", style: TextStyle(color: colorTexto.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                    // --- BLOQUE 2: FECHA Y HORA ---
                    _CustomGroup(
                      colorBorde: colorBorde,
                      children: [
                        _CustomListTile(
                          label: "Fecha",
                          value: fechaString.replaceFirst(fechaString[0], fechaString[0].toUpperCase()),
                          icon: Icons.calendar_today_rounded,
                          colorIcono: colorAcento,
                          colorFondoIcono: colorIconoFondo,
                          colorTexto: colorTexto,
                          showDivider: true,
                          colorBorde: colorBorde,
                        ),
                        
                        GestureDetector(
                          onTap: _mostrarSelectorHora,
                          behavior: HitTestBehavior.opaque,
                          child: _CustomListTile(
                            label: "Hora",
                            value: DateFormat('h:mm a').format(_horaSeleccionada),
                            icon: Icons.access_time_rounded,
                            colorIcono: colorAcento,
                            colorFondoIcono: colorIconoFondo,
                            colorTexto: colorTexto,
                            isAction: true, 
                            colorAction: colorAcento,
                            showDivider: false,
                            colorBorde: colorBorde,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text("DETALLES", style: TextStyle(color: colorTexto.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                    // --- BLOQUE 3: DETALLES ---
                    _CustomGroup(
                      colorBorde: colorBorde,
                      children: [
                        TextField(
                          controller: _categoriaController,
                          style: TextStyle(fontSize: 16, color: colorTexto),
                          decoration: InputDecoration(
                            hintText: "Categoría (Cita, Cine, Viaje...)",
                            hintStyle: TextStyle(color: colorTexto.withOpacity(0.3)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            isDense: true,
                            icon: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: colorIconoFondo, borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.bookmark_rounded, size: 18, color: colorAcento),
                              ),
                            )
                          ),
                          cursorColor: colorAcento,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        
                        Divider(height: 1, indent: 60, color: colorBorde),

                        Container(
                          constraints: const BoxConstraints(minHeight: 100),
                          child: TextField(
                            controller: _descripcionController,
                            maxLines: null,
                            style: TextStyle(fontSize: 16, color: colorTexto),
                            decoration: InputDecoration(
                              hintText: "Notas o descripción...",
                              hintStyle: TextStyle(color: colorTexto.withOpacity(0.3)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              icon: Padding(
                                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: colorIconoFondo, borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.notes_rounded, size: 18, color: colorAcento),
                                ),
                              )
                            ),
                            cursorColor: colorAcento,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- BOTONES INFERIORES ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorFondo,
                border: Border(top: BorderSide(color: colorBorde, width: 2)), // Línea divisoria suave
              ),
              child: Row(
                children: [
                  // Botón Cancelar
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: CupertinoColors.systemGrey5, // Un gris suave para el botón secundario
                      borderRadius: BorderRadius.circular(15),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancelar", 
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Botón Guardar
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: colorAcento, // Tu rojo manzana
                      borderRadius: BorderRadius.circular(15),
                      onPressed: _cargando ? null : _guardarEvento,
                      child: _cargando
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            "Guardar", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                    ),
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

// --- WIDGETS PERSONALIZADOS (Igual que antes) ---

class _CustomGroup extends StatelessWidget {
  final List<Widget> children;
  final Color colorBorde;

  const _CustomGroup({required this.children, required this.colorBorde});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorBorde, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A3E3E).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color colorIcono;
  final Color colorFondoIcono;
  final Color colorTexto;
  final Color colorBorde;
  final bool showDivider;
  final bool isAction;
  final Color? colorAction;

  const _CustomListTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorIcono,
    required this.colorFondoIcono,
    required this.colorTexto,
    required this.colorBorde,
    this.showDivider = true,
    this.isAction = false,
    this.colorAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorFondoIcono,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: colorIcono),
              ),
              const SizedBox(width: 15),
              Text(
                label,
                style: TextStyle(fontSize: 16, color: colorTexto, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: isAction ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5) : null,
                decoration: isAction 
                  ? BoxDecoration(color: colorFondoIcono, borderRadius: BorderRadius.circular(10))
                  : null,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16, 
                    color: isAction ? colorAction : colorTexto.withOpacity(0.6),
                    fontWeight: isAction ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 60, color: colorBorde),
      ],
    );
  }
}