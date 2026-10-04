import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/deporte.dart';
import '../models/hito.dart';
import '../models/jugador.dart';
import '../models/partido.dart';
import 'common_widgets.dart';

/// Avatar circular estilizado para el jugador (muestra dorsal o iniciales).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.jugador,
    this.size = 36,
    this.showDorsal = false,
    this.fontSize,
  });

  final Jugador jugador;
  final double size;
  final bool showDorsal;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final text = showDorsal && jugador.dorsal.trim().isNotEmpty
        ? '#${jugador.dorsal.trim()}'
        : jugador.iniciales;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: jugador.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: jugador.color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: fontSize ?? (size * 0.40),
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

/// Pill / Badge interactivo para la AppBar que muestra el jugador en vista.
class PlayerBadge extends StatelessWidget {
  const PlayerBadge({
    super.key,
    required this.jugadorActivo,
    required this.totalJugadores,
    required this.onTap,
  });

  final Jugador? jugadorActivo;
  final int totalJugadores;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTodos = jugadorActivo == null;
    final nombre = isTodos ? 'Todos los Jugadores' : jugadorActivo!.nombreDisplay;
    final subtitulo = isTodos
        ? '$totalJugadores jugadores registrados'
        : '${jugadorActivo!.sportConfig.emoji} ${jugadorActivo!.subtituloDisplay}';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD3E0DC), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTodos)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: appAccentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else
              PlayerAvatar(jugador: jugadorActivo!, size: 32, showDorsal: true),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 165),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: appInkColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade700,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal BottomSheet para cambiar de jugador, ver stats rápidas y agregar perfiles.
class PlayerSwitcherModal extends StatelessWidget {
  const PlayerSwitcherModal({
    super.key,
    required this.jugadores,
    required this.jugadorActivo,
    required this.allPartidos,
    required this.onSelectPlayer,
    required this.onSelectTodos,
    required this.onAddPlayer,
    required this.onEditPlayer,
  });

  final List<Jugador> jugadores;
  final Jugador? jugadorActivo;
  final List<Partido> allPartidos;
  final ValueChanged<Jugador> onSelectPlayer;
  final VoidCallback onSelectTodos;
  final VoidCallback onAddPlayer;
  final ValueChanged<Jugador> onEditPlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre superior
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appAccentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.switch_account_rounded, color: appAccentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seleccionar Jugador',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: appInkColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Cada jugador posee su propio historial y números',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Lista de tarjetas de jugadores
              for (final j in jugadores) ...[
                _buildPlayerCard(context, j),
                const SizedBox(height: 10),
              ],

              // Opción "Ver todos los jugadores"
              _buildTodosCard(context),
              const SizedBox(height: 18),

              // Botón para agregar nuevo jugador
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onAddPlayer();
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text(
                    'Agregar Nuevo Jugador',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: appAccentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, Jugador j) {
    final isSelected = jugadorActivo?.id == j.id;
    final matches = allPartidos.where((p) => p.nombreJugador == j.nombre).toList();
    final stats = Stats.fromPartidos(matches);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        onSelectPlayer(j);
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? appAccentColor : const Color(0xFFE2EBE8),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? appAccentColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            PlayerAvatar(jugador: j, size: 48, showDorsal: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${j.sportConfig.emoji} ${j.nombreDisplay}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: appInkColor,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: appAccentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ACTIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    j.subtituloDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Mini resumen de números
                  Row(
                    children: [
                      _MiniMetric(icon: j.sportConfig.icono, text: '${stats.pj} PJ'),
                      const SizedBox(width: 10),
                      _MiniMetric(icon: Icons.military_tech_rounded, text: '${stats.gp} ${j.sportConfig.labelAnotacionHijo}'),
                      if (stats.campeonatos > 0) ...[
                        const SizedBox(width: 10),
                        _MiniMetric(icon: Icons.emoji_events_rounded, text: '${stats.campeonatos} 🏆', color: const Color(0xFFD97706)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar perfil',
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: Colors.grey.shade600,
              onPressed: () {
                Navigator.pop(context);
                onEditPlayer(j);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodosCard(BuildContext context) {
    final isSelected = jugadorActivo == null;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        onSelectTodos();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? appAccentColor : const Color(0xFFE2EBE8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE5EBE8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: appInkColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ver todos los jugadores',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: appInkColor,
                    ),
                  ),
                  Text(
                    'Vista combinada de todos los partidos (${allPartidos.length} totales)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: appAccentColor, size: 22),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final clr = color ?? Colors.grey.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: clr),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: clr),
        ),
      ],
    );
  }
}

/// Diálogo interactivo para crear o editar los datos de un jugador.
class PlayerFormDialog extends StatefulWidget {
  const PlayerFormDialog({
    super.key,
    this.jugador,
    required this.onSave,
  });

  final Jugador? jugador;
  final ValueChanged<Jugador> onSave;

  @override
  State<PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apodo;
  late final TextEditingController _clubActual;
  late final TextEditingController _categoria;
  late final TextEditingController _dorsal;
  late String _deporte;
  late String _posicion;
  late int _colorHex;
  late List<String> _posiciones;

  @override
  void initState() {
    super.initState();
    final j = widget.jugador;
    _deporte = j?.deporte ?? 'futbol';
    final sport = SportConfig.fromId(_deporte);
    _posiciones = List.from(sport.posicionesDisponibles);
    _nombre = TextEditingController(text: j?.nombre ?? '');
    _apodo = TextEditingController(text: j?.apodo ?? '');
    _clubActual = TextEditingController(
      text: j?.clubActual ?? (_deporte == 'futbol' ? 'Cosmos FC' : ''),
    );
    _categoria = TextEditingController(text: j?.categoria ?? '');
    _dorsal = TextEditingController(text: j?.dorsal ?? '10');
    _posicion = j?.posicionHabitual ?? _posiciones.first;
    if (!_posiciones.contains(_posicion)) _posiciones.add(_posicion);
    _colorHex = j?.colorHex ?? Jugador.coloresDisponibles.first;
  }

  void _onSportChanged(String nuevoDeporte) {
    setState(() {
      _deporte = nuevoDeporte;
      final sport = SportConfig.fromId(_deporte);
      _posiciones = List.from(sport.posicionesDisponibles);
      if (!_posiciones.contains(_posicion)) {
        _posicion = _posiciones.first;
      }
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apodo.dispose();
    _clubActual.dispose();
    _categoria.dispose();
    _dorsal.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final j = Jugador(
      id: widget.jugador?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombre.text.trim(),
      apodo: _apodo.text.trim(),
      clubActual: _clubActual.text.trim().isEmpty ? 'Cosmos FC' : _clubActual.text.trim(),
      categoria: _categoria.text.trim(),
      dorsal: _dorsal.text.trim().isEmpty ? '10' : _dorsal.text.trim(),
      posicionHabitual: _posicion,
      colorHex: _colorHex,
      fotoUrl: widget.jugador?.fotoUrl,
      deporte: _deporte,
    );
    Navigator.pop(context);
    widget.onSave(j);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.jugador != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(_colorHex).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                        color: Color(_colorHex),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar Jugador' : 'Nuevo Jugador',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: appInkColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selector de Deporte
                const Text(
                  'Deporte',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: appInkColor,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in SportConfig.all)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            avatar: Text(s.emoji, style: const TextStyle(fontSize: 14)),
                            label: Text(
                              s.nombre,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _deporte == s.id ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: _deporte == s.id,
                            onSelected: (_) => _onSportChanged(s.id),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nombre completo
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y Apellido *',
                    hintText: 'Ej: Mateo Cau',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresá el nombre del jugador' : null,
                ),
                const SizedBox(height: 12),

                // Apodo y Dorsal
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _apodo,
                        decoration: const InputDecoration(
                          labelText: 'Apodo',
                          hintText: 'Ej: Mati (opcional)',
                          prefixIcon: Icon(Icons.sentiment_satisfied_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dorsal,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dorsal #',
                          hintText: '10',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Club Actual
                TextFormField(
                  controller: _clubActual,
                  decoration: const InputDecoration(
                    labelText: 'Club o Escuela deportiva',
                    hintText: 'Ej: Cosmos FC',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Categoría
                TextFormField(
                  controller: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría / Año',
                    hintText: 'Ej: Cat. 2014',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Posición habitual
                DropdownButtonFormField<String>(
                  key: ValueKey('pos_$_deporte'),
                  initialValue: _posicion,
                  decoration: InputDecoration(
                    labelText: 'Posición habitual',
                    prefixIcon: Icon(SportConfig.fromId(_deporte).icono),
                  ),
                  items: _posiciones
                      .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _posicion = v);
                  },
                ),
                const SizedBox(height: 16),

                // Color de avatar distintivo
                const Text(
                  'Color del jugador',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: appInkColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final col in Jugador.coloresDisponibles)
                      GestureDetector(
                        onTap: () => setState(() => _colorHex = col),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(col),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _colorHex == col ? Colors.black : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: _colorHex == col
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                // Botones Cancelar / Guardar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(backgroundColor: Color(_colorHex)),
                      child: Text(isEditing ? 'Guardar Cambios' : 'Crear Jugador'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal interactivo para elegir jugador, temporada y compartir ficha deportiva por WhatsApp o PDF.
class SharePlayerStatsModal extends StatefulWidget {
  const SharePlayerStatsModal({
    super.key,
    required this.jugadores,
    required this.jugadorInicial,
    required this.allPartidos,
    required this.dateFormat,
  });

  final List<Jugador> jugadores;
  final Jugador? jugadorInicial;
  final List<Partido> allPartidos;
  final dynamic dateFormat;

  @override
  State<SharePlayerStatsModal> createState() => _SharePlayerStatsModalState();
}

class _SharePlayerStatsModalState extends State<SharePlayerStatsModal> {
  late Jugador _selectedJugador;
  String _selectedTemporada = 'Todas';
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    _selectedJugador = widget.jugadorInicial ??
        (widget.jugadores.isNotEmpty
            ? widget.jugadores.first
            : const Jugador(id: '1', nombre: 'Mi Hijo'));
  }

  List<String> get _temporadasDisponibles {
    final temps = widget.allPartidos
        .where((p) => p.nombreJugador == _selectedJugador.nombre)
        .map((p) => p.temporada)
        .where((t) => t.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return ['Todas', ...temps];
  }

  List<Partido> get _partidosFiltrados {
    return widget.allPartidos.where((p) {
      final matchesPlayer = p.nombreJugador == _selectedJugador.nombre;
      final matchesTemp =
          _selectedTemporada == 'Todas' || p.temporada == _selectedTemporada;
      return matchesPlayer && matchesTemp;
    }).toList();
  }

  String _buildShareText(Stats stats, List<Partido> matches) {
    final winPct = stats.pj > 0 ? ((stats.pg / stats.pj) * 100).toStringAsFixed(0) : '0';
    final tempTxt = _selectedTemporada == 'Todas' ? 'Histórico General' : 'Temporada $_selectedTemporada';

    final buffer = StringBuffer();
    buffer.writeln('⚽ FICHA DEPORTIVA - PARTIDOS PRO');
    buffer.writeln('👤 ${_selectedJugador.nombreDisplay} #${_selectedJugador.dorsal}');
    buffer.writeln('🛡️ ${_selectedJugador.clubActual} • ${_selectedJugador.categoria}');
    buffer.writeln('📅 $tempTxt');
    buffer.writeln('');
    buffer.writeln('📊 RENDIMIENTO:');
    buffer.writeln('• Partidos Jugados: ${stats.pj} (Efectividad: $winPct%)');
    buffer.writeln('• 🟢 Ganados: ${stats.pg} | 🟡 Empatados: ${stats.pe} | 🔴 Perdidos: ${stats.pp}');
    buffer.writeln('• ⚽ Goles: ${stats.gp}');
    buffer.writeln('• 🎯 Asistencias: ${stats.asistencias}');
    buffer.writeln('• ⭐ Veces Figura: ${stats.figuras}');
    buffer.writeln('• ⏱️ Minutos disputados: ${stats.minutos} min');
    if (stats.amarillas > 0 || stats.rojas > 0) {
      buffer.writeln('• 🟨 Amarillas: ${stats.amarillas} | 🟥 Rojas: ${stats.rojas}');
    }

    if (stats.campeonatos > 0 || stats.subcampeonatos > 0) {
      buffer.writeln('');
      buffer.writeln('🏆 PALMARÉS Y LOGROS:');
      for (final logro in stats.logros) {
        final icon = logro.campeon ? '🏆' : '🥈';
        final status = logro.campeon ? 'Campeón' : 'Subcampeón';
        buffer.writeln('• $icon $status: ${logro.tituloDisplay}');
      }
    }

    final hitos = HitoDetector.calcularHitos(matches);
    final hitosDestacados = hitos.take(4).toList();
    if (hitosDestacados.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🌟 HITOS Y MOMENTOS DESTACADOS:');
      for (final h in hitosDestacados) {
        buffer.writeln('• ${h.emoji} ${h.titulo}: ${h.subtitulo}');
      }
    }

    buffer.writeln('');
    buffer.writeln('📲 Registrado con Partidos Pro');
    return buffer.toString();
  }

  Future<void> _shareText(Stats stats, List<Partido> matches) async {
    final text = _buildShareText(stats, matches);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Ficha de ${_selectedJugador.nombre}',
      ),
    );
  }

  Future<void> _sharePdf(Stats stats, List<Partido> matches) async {
    setState(() => _generatingPdf = true);
    try {
      await PlayerPdfHelper.exportDossier(
        context: context,
        jugador: _selectedJugador,
        stats: stats,
        matches: matches,
        temporada: _selectedTemporada,
      );
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _partidosFiltrados;
    final stats = Stats.fromPartidos(matches);
    final winPct = stats.pj > 0 ? ((stats.pg / stats.pj) * 100).toStringAsFixed(0) : '0';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appAccentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_rounded, color: appAccentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Compartir Ficha Deportiva',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: appInkColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selector de Jugador si hay más de 1
              if (widget.jugadores.length > 1) ...[
                const Text(
                  '¿De qué jugador querés compartir?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: appInkColor),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final j in widget.jugadores)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: _selectedJugador.id == j.id,
                            avatar: PlayerAvatar(jugador: j, size: 24),
                            label: Text(j.nombreDisplay),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedJugador = j;
                                  _selectedTemporada = 'Todas';
                                });
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Selector de Temporada
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Temporada a incluir:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: appInkColor),
                  ),
                  DropdownButton<String>(
                    value: _selectedTemporada,
                    underline: const SizedBox(),
                    items: _temporadasDisponibles
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedTemporada = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tarjeta deportiva preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _selectedJugador.color,
                      _selectedJugador.color.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedJugador.color.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PlayerAvatar(jugador: _selectedJugador, size: 48, showDorsal: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedJugador.nombreDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _selectedJugador.subtituloDisplay,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedTemporada == 'Todas' ? 'HISTÓRICO' : _selectedTemporada,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _PreviewStatItem(label: 'Partidos', value: '${stats.pj}'),
                          _PreviewStatItem(label: 'Goles', value: '${stats.gp}'),
                          _PreviewStatItem(label: 'Asistencias', value: '${stats.asistencias}'),
                          _PreviewStatItem(label: 'Efectividad', value: '$winPct%'),
                          if (stats.campeonatos > 0)
                            _PreviewStatItem(label: 'Títulos', value: '${stats.campeonatos} 🏆'),
                        ],
                      ),
                    ),
                    if (HitoDetector.calcularHitos(matches).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: HitoDetector.calcularHitos(matches).take(3).map((h) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(h.emoji, style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  h.titulo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botones de Compartir
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generatingPdf ? null : () => _sharePdf(stats, matches),
                      icon: _generatingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Ficha PDF Pro', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _shareText(stats, matches),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('WhatsApp / Texto', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: appAccentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStatItem extends StatelessWidget {
  const _PreviewStatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Helper para generar y compartir el Dossier deportivo completo en PDF
/// con estadísticas, palmarés, hitos y fotos de los partidos.
class PlayerPdfHelper {
  static Future<pw.ImageProvider?> _fetchPdfImage(String pathOrUrl) async {
    try {
      if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
        final res = await http.get(Uri.parse(pathOrUrl)).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return pw.MemoryImage(res.bodyBytes);
        }
      } else {
        final file = File(pathOrUrl);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            return pw.MemoryImage(bytes);
          }
        }
      }
    } catch (e) {
      debugPrint('No se pudo cargar foto para el PDF ($pathOrUrl): $e');
    }
    return null;
  }

  static Future<void> exportDossier({
    required BuildContext context,
    required Jugador jugador,
    required Stats stats,
    required List<Partido> matches,
    String temporada = 'Todas',
  }) async {
    try {
      final doc = pw.Document();
      final winPct = stats.pj > 0 ? ((stats.pg / stats.pj) * 100).toStringAsFixed(0) : '0';

      // Cargar fotos de partidos si existen para incrustar en el PDF (hasta 4)
      final photoMatches = matches
          .where((p) =>
              (p.foto != null && p.foto!.isNotEmpty) ||
              (p.fotoPath != null && p.fotoPath!.isNotEmpty))
          .take(4)
          .toList();

      final loadedImages = await Future.wait(
        photoMatches.map((pm) async {
          final path = (pm.foto != null && pm.foto!.isNotEmpty) ? pm.foto! : pm.fotoPath!;
          final img = await _fetchPdfImage(path);
          if (img != null) {
            return (
              image: img,
              caption: '${pm.equipo} vs ${pm.rival} (${pm.marcador})',
            );
          }
          return null;
        }),
      );

      final pdfImages = loadedImages
          .whereType<({pw.ImageProvider image, String caption})>()
          .toList();

      String cleanPdf(String text) {
        return text
            .replaceAll('•', '-')
            .replaceAll('🏆', '')
            .replaceAll('🥈', '')
            .replaceAll('🌟', '')
            .replaceAll('👕', '')
            .replaceAll('⚽', '')
            .replaceAll('🎩', '')
            .replaceAll('⚡', '')
            .replaceAll('🔟', '')
            .replaceAll('🥉', '')
            .replaceAll('🥇', '')
            .replaceAll('💯', '')
            .replaceAll('⭐', '')
            .replaceAll('📅', '')
            .replaceAll(RegExp(r'[^\x00-\x7F\u00A0-\u00FF]'), '')
            .trim();
      }

      pw.Widget pdfStatBox(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.95, 0.95, 0.95),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
              pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            // Cabecera deportiva
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(jugador.colorHex),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cleanPdf(jugador.nombreDisplay.toUpperCase()),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        cleanPdf('${jugador.clubActual} - #${jugador.dorsal} - ${jugador.categoria}'),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'PARTIDOS PRO',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Resumen de rendimiento
            pw.Text(
              cleanPdf('Rendimiento (${temporada == "Todas" ? "Histórico General" : "Temporada $temporada"})'),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pdfStatBox('PJ', '${stats.pj}'),
                pdfStatBox('PG', '${stats.pg}'),
                pdfStatBox('PE', '${stats.pe}'),
                pdfStatBox('PP', '${stats.pp}'),
                pdfStatBox('Efectividad', '$winPct%'),
                pdfStatBox('Goles', '${stats.gp}'),
                pdfStatBox('Asistencias', '${stats.asistencias}'),
                pdfStatBox('Figuras', '${stats.figuras}'),
              ],
            ),
            pw.SizedBox(height: 16),

            // Títulos y Palmarés con Badges vectoriales
            if (stats.campeonatos > 0 || stats.subcampeonatos > 0) ...[
              pw.Text(
                'Palmarés (${stats.campeonatos} Campeonatos - ${stats.subcampeonatos} Subcampeonatos)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              for (final logro in stats.logros)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: logro.campeon ? const PdfColor(0.85, 0.65, 0.1) : const PdfColor(0.4, 0.45, 0.5),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          logro.campeon ? 'CAMPEÓN' : 'SUBCAMPEÓN',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        cleanPdf(logro.tituloDisplay),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 14),
            ],

            // Hitos destacados con badges vectoriales
            if (HitoDetector.calcularHitos(matches).isNotEmpty) ...[
              pw.Text(
                'Hitos y Recuerdos Destacados',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              for (final h in HitoDetector.calcularHitos(matches).take(6))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(h.color.toARGB32()),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          cleanPdf(h.titulo).toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          '${cleanPdf(h.subtitulo)} (${cleanPdf(h.partido.fechaTexto)})',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 14),
            ],

            // Galería de fotos del jugador en partidos si existen
            if (pdfImages.isNotEmpty) ...[
              pw.Text(
                'Fotos Destacadas de Partidos',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                runSpacing: 10,
                children: pdfImages.map((pImg) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(
                          pImg.image,
                          width: 155,
                          height: 105,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.SizedBox(
                        width: 155,
                        child: pw.Text(
                          cleanPdf(pImg.caption),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 14),
            ],

            // Tabla de partidos
            pw.Text(
              'Detalle de Partidos (${matches.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Fecha', 'Torneo/Liga', 'Fase', 'Resultado', 'G', 'A'],
              data: matches.map((p) {
                return [
                  p.fechaTexto,
                  p.torneo,
                  p.fase,
                  '${p.equipo} ${p.marcador} ${p.rival}',
                  '${p.golesHijo}',
                  '${p.asistencias}',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'ficha_${jugador.nombre.toLowerCase().replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No pude generar PDF: $e')),
        );
      }
    }
  }
}
