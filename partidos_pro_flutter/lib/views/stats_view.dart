import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deporte.dart';
import '../models/hito.dart';
import '../models/partido.dart';
import '../widgets/common_widgets.dart';

class StatsView extends StatefulWidget {
  const StatsView({
    super.key,
    required this.partidos,
    required this.allPartidos,
    required this.playerName,
    required this.winningStreak,
    required this.calendarMonth,
    required this.dateFormat,
    required this.onRefresh,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
    required this.onExportCsv,
    required this.onExportPdf,
    this.onShareStats,
    this.onOpenDetail,
  });

  final List<Partido> partidos;
  final List<Partido> allPartidos;
  final String playerName;
  final int winningStreak;
  final DateTime calendarMonth;
  final DateFormat dateFormat;
  final Future<void> Function() onRefresh;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(DateTime day, List<Partido> partidos) onDayTap;
  final VoidCallback? onExportCsv;
  final VoidCallback? onExportPdf;
  final VoidCallback? onShareStats;
  final ValueChanged<Partido>? onOpenDetail;

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  int _selectedSection = 0; // 0: Rendimiento, 1: Torneos, 2: Rivales, 3: Calendario, 4: Exportar

  Stats _statsFor(Iterable<Partido> partidos) {
    return Stats.fromPartidos(partidos);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statsFor(widget.partidos);
    final sport = widget.partidos.isNotEmpty
        ? widget.partidos.first.sportConfig
        : SportConfig.futbol;
    final winPercentage = stats.pj > 0 ? ((stats.pg / stats.pj) * 100).toStringAsFixed(0) : '0';

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Cabecera deportiva con botón de compartir ficha
          Row(
            children: [
              Expanded(
                child: Header(
                  title: 'Rendimiento',
                  subtitle: '${widget.playerName} • ${widget.partidos.length} partidos analizados',
                ),
              ),
              if (widget.onShareStats != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: IconButton.filledTonal(
                    tooltip: 'Compartir Ficha Deportiva',
                    onPressed: widget.onShareStats,
                    icon: const Icon(Icons.share_rounded, color: appAccentColor),
                  ),
                ),
            ],
          ),

          // Tarjeta principal de KPIs destacados
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3D33), Color(0xFF087C63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF087C63).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _KpiItem(label: 'Jugados', value: '${stats.pj}', icon: sport.icono),
                    _KpiItem(label: 'Efectividad', value: '$winPercentage%', icon: Icons.speed_rounded),
                    _KpiItem(
                      label: sport.labelAnotacionHijo,
                      value: '${stats.gp}',
                      icon: Icons.military_tech_rounded,
                      highlight: true,
                    ),
                    _KpiItem(label: 'Figuras', value: '${stats.figuras}', icon: Icons.star_rounded),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SubKpi(label: 'Victorias', value: '${stats.pg}'),
                      _SubKpi(label: 'Empates', value: '${stats.pe}'),
                      _SubKpi(label: 'Derrotas', value: '${stats.pp}'),
                      _SubKpi(label: 'Asistencias', value: '${stats.asistencias}'),
                      _SubKpi(label: 'Minutos', value: '${stats.minutos}'),
                    ],
                  ),
                ),
                if (stats.campeonatos > 0 || stats.subcampeonatos > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (stats.campeonatos > 0) ...[
                          const Text('🏆', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '${stats.campeonatos} ${stats.campeonatos == 1 ? 'Campeonato' : 'Campeonatos'}',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                        if (stats.campeonatos > 0 && stats.subcampeonatos > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        if (stats.subcampeonatos > 0) ...[
                          const Text('🥈', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '${stats.subcampeonatos} ${stats.subcampeonatos == 1 ? 'Subcampeonato' : 'Subcampeonatos'}',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Selector de sección de estadísticas mediante SegmentedButton
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('General'), icon: Icon(Icons.analytics_outlined)),
                ButtonSegment(value: 1, label: Text('Torneos'), icon: Icon(Icons.emoji_events_outlined)),
                ButtonSegment(value: 2, label: Text('Recuerdos 🌟'), icon: Icon(Icons.auto_awesome_rounded)),
                ButtonSegment(value: 3, label: Text('Rivales'), icon: Icon(Icons.leaderboard_outlined)),
                ButtonSegment(value: 4, label: Text('Calendario'), icon: Icon(Icons.calendar_month_outlined)),
                ButtonSegment(value: 5, label: Text('Exportar'), icon: Icon(Icons.ios_share_rounded)),
              ],
              selected: {_selectedSection},
              onSelectionChanged: (val) => setState(() => _selectedSection = val.first),
            ),
          ),

          const SizedBox(height: 16),

          // Contenido dinámico según la sección seleccionada con transición suave
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_selectedSection),
              child: switch (_selectedSection) {
                0 => _buildGeneralSection(stats),
                1 => _buildTournamentSection(),
                2 => _buildRecuerdosSection(),
                3 => _buildRivalesSection(),
                4 => _buildCalendarSection(),
                5 => _buildExportSection(),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(Stats stats) {
    final recent = widget.partidos.take(10).toList().reversed.toList();
    return Column(
      children: [
        StatsGrid(stats: stats),
        const SizedBox(height: 12),
        _GoalChart(partidos: recent),
        const SizedBox(height: 12),
        _EvolutionSummary(
          partidos: widget.partidos,
          streak: widget.winningStreak,
        ),
        const SizedBox(height: 12),
        _ProDashboard(partidos: widget.partidos),
      ],
    );
  }

  Widget _buildTournamentSection() {
    final tournamentMatches =
        widget.partidos.where((p) => p.tipoPartido == 'Torneo').toList();
    final tournamentStats = Stats.fromPartidos(tournamentMatches);

    final byTournament = <String, List<Partido>>{};
    for (final p in tournamentMatches) {
      byTournament.putIfAbsent(p.torneo, () => []).add(p);
    }

    return Column(
      children: [
        if (tournamentStats.logros.isNotEmpty) ...[
          SectionCard(
            title: 'Palmarés y Títulos',
            icon: Icons.emoji_events_rounded,
            child: Column(
              children: tournamentStats.logros.map((logro) {
                final isCamp = logro.campeon;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCamp
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCamp
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isCamp ? '🏆' : '🥈',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCamp ? '¡CAMPEÓN!' : 'SUBCAMPEÓN',
                              style: TextStyle(
                                color: isCamp
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF475569),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              logro.tituloDisplay,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: appInkColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        logro.finalMatch.marcador,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: appInkColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _TournamentMode(partidos: widget.partidos),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Detalle por torneo',
          icon: Icons.emoji_events_outlined,
          child: byTournament.isEmpty
              ? const Text('No hay datos para torneos.')
              : Column(
                  children: byTournament.entries.map((entry) {
                    final tStats = Stats.fromPartidos(entry.value);
                    Widget? tBadge;
                    if (tStats.campeonatos > 0) {
                      tBadge = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text(
                          '🏆 Campeón',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    } else if (tStats.subcampeonatos > 0) {
                      tBadge = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF94A3B8)),
                        ),
                        child: const Text(
                          '🥈 Subcampeón',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }
                    return PageStorage(
                      bucket: PageStorageBucket(),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            ?tBadge,
                          ],
                        ),
                        subtitle: Text(
                          '${tStats.pj} partidos | ${tStats.pg}G ${tStats.pe}E ${tStats.pp}P',
                        ),
                        children: [
                          StatsGrid(stats: tStats, compact: true),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildRecuerdosSection() {
    final hitos = HitoDetector.calcularHitos(widget.partidos);
    if (hitos.isEmpty) {
      return SectionCard(
        title: 'Álbum de Recuerdos',
        icon: Icons.auto_awesome_rounded,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 54, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Aún no hay hitos registrados para ${widget.playerName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: appInkColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A medida que registres partidos, la app inmortalizará automáticamente debuts, goles clave, partidos redondos (#10, #25, #50), campeonatos y momentos mágicos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalHitos = hitos.length;
    final titulos = hitos.where((h) => h.tipo == TipoHito.campeon).length;
    final presencias = hitos.where((h) =>
        h.tipo == TipoHito.partidoRedondo ||
        h.tipo == TipoHito.debut ||
        h.tipo == TipoHito.debutClub).length;
    final goles = hitos.where((h) =>
        h.tipo == TipoHito.primerGol ||
        h.tipo == TipoHito.golRedondo ||
        h.tipo == TipoHito.hatTrick ||
        h.tipo == TipoHito.poker).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tarjeta cabecera del Álbum Vivo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3730A3).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Álbum Deportivo Vivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalHitos ${totalHitos == 1 ? 'momento' : 'momentos'}',
                      style: const TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Los recuerdos más memorables en la historia de ${widget.playerName}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RecuerdoMiniKpi(label: 'Total Hitos', value: '$totalHitos', color: Colors.amber.shade300),
                    _RecuerdoMiniKpi(label: 'Títulos 🏆', value: '$titulos', color: Colors.yellow.shade200),
                    _RecuerdoMiniKpi(label: 'Partidos Clave', value: '$presencias', color: Colors.cyan.shade200),
                    _RecuerdoMiniKpi(label: 'Goles Épicos', value: '$goles', color: Colors.greenAccent.shade200),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Línea de tiempo de hitos
        SectionCard(
          title: 'Línea de Tiempo de Recuerdos',
          icon: Icons.timeline_rounded,
          child: Column(
            children: hitos.map((h) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: h.color.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: h.color.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.onOpenDetail != null ? () => widget.onOpenDetail!(h.partido) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: h.color.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: h.color.withValues(alpha: 0.3),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(h.emoji, style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.titulo,
                                      style: TextStyle(
                                        color: h.color,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${h.partido.equipo} vs ${h.partido.rival} (${h.partido.marcador})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: appInkColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                widget.dateFormat.format(h.fecha.toLocal()),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            h.descripcion,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (h.partido.analisis.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💬 ', style: TextStyle(fontSize: 12)),
                                  Expanded(
                                    child: Text(
                                      '"${h.partido.analisis}"',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRivalesSection() {
    return _RivalRanking(partidos: widget.partidos);
  }

  Widget _buildCalendarSection() {
    return _CalendarSection(
      month: widget.calendarMonth,
      partidos: widget.allPartidos,
      dateFormat: widget.dateFormat,
      onPrev: widget.onPrevMonth,
      onNext: widget.onNextMonth,
      onDayTap: widget.onDayTap,
    );
  }

  Widget _buildExportSection() {
    return _ExportSection(
      count: widget.partidos.length,
      onCsv: widget.onExportCsv,
      onPdf: widget.onExportPdf,
      onShareStats: widget.onShareStats,
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: highlight ? const Color(0xFFFDE047) : Colors.white70,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFFDE047) : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SubKpi extends StatelessWidget {
  const _SubKpi({required this.label, required this.value});

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
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GoalChart extends StatelessWidget {
  const _GoalChart({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final maxGoals = max(
      1,
      partidos.fold<int>(0, (m, p) => max(m, p.golesHijo)),
    );
    return SectionCard(
      title: 'Goles últimos ${partidos.length} partidos',
      icon: Icons.bar_chart_rounded,
      child: partidos.isEmpty
          ? const Text('No hay partidos recientes para graficar.')
          : SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final p in partidos)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${p.golesHijo}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 22,
                          height: max(8, (p.golesHijo / maxGoals) * 92),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: p.golesHijo > 0
                                  ? [const Color(0xFF087C63), const Color(0xFF10B981)]
                                  : [Colors.grey.shade300, Colors.grey.shade400],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.rival.length > 3 ? p.rival.substring(0, 3) : p.rival,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _EvolutionSummary extends StatelessWidget {
  const _EvolutionSummary({required this.partidos, required this.streak});

  final List<Partido> partidos;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final stats = Stats();
    final byPosition = <String, int>{};
    var maxGoals = 0;
    for (final p in partidos) {
      stats.add(p);
      byPosition[p.posicion] = (byPosition[p.posicion] ?? 0) + 1;
      maxGoals = max(maxGoals, p.golesHijo);
    }
    final averageGoals = stats.pj == 0 ? 0 : stats.gp / stats.pj;
    final favoritePosition = byPosition.entries.isEmpty
        ? 'Sin datos'
        : (byPosition.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return SectionCard(
      title: 'Evolución',
      icon: Icons.trending_up_rounded,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: [
          InfoTile(
            label: 'Promedio goles',
            value: averageGoals.toStringAsFixed(2),
          ),
          InfoTile(label: 'Mejor marca', value: '$maxGoals goles'),
          InfoTile(label: 'Racha actual', value: '$streak victorias'),
          InfoTile(label: 'Posición usual', value: favoritePosition),
        ],
      ),
    );
  }
}

class _ProDashboard extends StatelessWidget {
  const _ProDashboard({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final stats = Stats.fromPartidos(partidos);
    final byCancha = <String, Stats>{};
    final byTemporada = <String, Stats>{};
    final byRival = <String, Stats>{};
    for (final p in partidos) {
      if (p.cancha.isNotEmpty) byCancha.putIfAbsent(p.cancha, Stats.new).add(p);
      if (p.temporada.isNotEmpty) {
        byTemporada.putIfAbsent(p.temporada, Stats.new).add(p);
      }
      if (p.rival.isNotEmpty) byRival.putIfAbsent(p.rival, Stats.new).add(p);
    }

    String bestLabel(Map<String, Stats> values, int Function(Stats) score) {
      if (values.isEmpty) return 'Sin datos';
      final list = values.entries.toList()
        ..sort((a, b) => score(b.value).compareTo(score(a.value)));
      return list.first.key;
    }

    final avgMinutes = stats.pj == 0 ? 0 : stats.minutos / stats.pj;
    final totalCards = stats.amarillas + stats.rojas;

    return SectionCard(
      title: 'Dashboard Pro',
      icon: Icons.dashboard_customize_outlined,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.75,
        children: [
          InfoTile(
            label: 'Mejor cancha',
            value: bestLabel(byCancha, (s) => s.pg * 3 + s.pe),
          ),
          InfoTile(
            label: 'Temporada top',
            value: bestLabel(byTemporada, (s) => s.gp + s.asistencias),
          ),
          InfoTile(
            label: 'Rival más difícil',
            value: bestLabel(byRival, (s) => s.pp * 3 + s.gc),
          ),
          InfoTile(
            label: 'Prom. minutos',
            value: avgMinutes.toStringAsFixed(0),
          ),
          InfoTile(label: 'Asistencias', value: '${stats.asistencias}'),
          InfoTile(label: 'Tarjetas', value: '$totalCards'),
          InfoTile(label: '🏆 Campeón', value: '${stats.campeonatos}'),
          InfoTile(label: '🥈 Subcampeón', value: '${stats.subcampeonatos}'),
        ],
      ),
    );
  }
}

class _TournamentMode extends StatelessWidget {
  const _TournamentMode({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final tournaments = <String, List<Partido>>{};
    for (final p in partidos.where((p) => p.tipoPartido == 'Torneo')) {
      tournaments.putIfAbsent(p.torneo, () => []).add(p);
    }

    return SectionCard(
      title: 'Modo torneo',
      icon: Icons.account_tree_outlined,
      child: tournaments.isEmpty
          ? const Text(
              'Marcá partidos como Torneo para ver fases, copas y resumen.',
            )
          : Column(
              children: tournaments.entries.map((entry) {
                final stats = Stats.fromPartidos(entry.value);
                final phases = <String, int>{};
                for (final p in entry.value) {
                  final label = p.copa != 'Ninguna' && p.copa.isNotEmpty
                      ? '${p.fase} - Copa ${p.copa}'
                      : p.fase;
                  phases[label] = (phases[label] ?? 0) + 1;
                }

                Widget? trophyBadge;
                if (stats.campeonatos > 0) {
                  trophyBadge = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Text(
                      '🏆 Campeón',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                } else if (stats.subcampeonatos > 0) {
                  trophyBadge = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF94A3B8)),
                    ),
                    child: const Text(
                      '🥈 Subcampeón',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }

                return PageStorage(
                  bucket: PageStorageBucket(),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        ?trophyBadge,
                      ],
                    ),
                    subtitle: Text(
                      '${stats.pj} partidos | DG ${stats.dg} | ${stats.gp} goles',
                    ),
                    children: [
                      StatsGrid(stats: stats, compact: true),
                      const SizedBox(height: 8),
                      for (final phase in phases.entries)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.flag_outlined),
                          title: Text(phase.key.isEmpty ? 'Sin fase' : phase.key),
                          trailing: Text('${phase.value}'),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class RivalSummary {
  RivalSummary(this.rival);

  final String rival;
  final stats = Stats();

  void add(Partido p) => stats.add(p);
}

class _RivalRanking extends StatelessWidget {
  const _RivalRanking({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final rivals = <String, RivalSummary>{};
    for (final p in partidos) {
      rivals.putIfAbsent(p.rival, () => RivalSummary(p.rival)).add(p);
    }
    final ranking = rivals.values.toList()
      ..sort((a, b) {
        final byPoints = (b.stats.pg * 3 + b.stats.pe).compareTo(
          a.stats.pg * 3 + a.stats.pe,
        );
        return byPoints != 0 ? byPoints : b.stats.gp.compareTo(a.stats.gp);
      });

    return SectionCard(
      title: 'Ranking de rivales',
      icon: Icons.leaderboard_rounded,
      child: ranking.isEmpty
          ? const Text('Todavía no hay datos para rankear.')
          : Column(
              children: ranking.take(10).map((r) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    r.rival,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${r.stats.pj} PJ | ${r.stats.pg}G ${r.stats.pe}E ${r.stats.pp}P',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF087C63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${r.stats.gp} goles',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF087C63),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.month,
    required this.partidos,
    required this.dateFormat,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  final DateTime month;
  final List<Partido> partidos;
  final DateFormat dateFormat;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime day, List<Partido> partidos) onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final firstWeekday = first.weekday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final monthPartidos = partidos.where((p) {
      final d = p.fechaPartido.toLocal();
      return d.year == month.year && d.month == month.month;
    }).toList();
    final byDay = <int, List<Partido>>{};
    for (final p in monthPartidos) {
      final day = p.fechaPartido.toLocal().day;
      byDay.putIfAbsent(day, () => []).add(p);
    }
    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final dayPartidos = byDay[day] ?? [];
      cells.add(
        CalendarCell(
          day: day,
          count: dayPartidos.length,
          onTap: dayPartidos.isEmpty
              ? null
              : () => onDayTap(
                  DateTime(month.year, month.month, day),
                  dayPartidos,
                ),
        ),
      );
    }

    return SectionCard(
      title: 'Calendario de partidos',
      icon: Icons.calendar_month_rounded,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy', 'es_AR').format(month).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: cells,
          ),
          const SizedBox(height: 10),
          Text(
            '${monthPartidos.length} partidos jugados este mes',
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({
    required this.count,
    required this.onCsv,
    required this.onPdf,
    this.onShareStats,
  });

  final int count;
  final VoidCallback? onCsv;
  final VoidCallback? onPdf;
  final VoidCallback? onShareStats;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Compartir y Exportación',
      icon: Icons.ios_share_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onShareStats != null) ...[
            FilledButton.icon(
              onPressed: onShareStats,
              icon: const Icon(Icons.share_rounded),
              label: const Text(
                'Compartir Ficha Deportiva',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: appAccentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
          ],
          Text(
            'Exportar los $count partidos analizados a archivos externos:',
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onCsv,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Exportar Planilla CSV'),
              ),
              OutlinedButton.icon(
                onPressed: onPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generar Reporte PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecuerdoMiniKpi extends StatelessWidget {
  const _RecuerdoMiniKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
