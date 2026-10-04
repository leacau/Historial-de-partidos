import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/hito.dart';
import '../models/partido.dart';
import '../widgets/common_widgets.dart';
import '../widgets/partido_card.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    super.key,
    required this.partidos,
    required this.allPartidos,
    this.hitosPorPartido = const {},
    this.efemerides = const [],
    required this.search,
    required this.filterResultado,
    required this.filterTipo,
    required this.winningStreak,
    this.playerName,
    required this.dateFormat,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onResultadoChanged,
    required this.onTipoChanged,
    required this.onClearFilters,
    required this.onOpenFiltersModal,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onNewMatch,
  });

  final List<Partido> partidos;
  final List<Partido> allPartidos;
  final Map<String, List<HitoDeportivo>> hitosPorPartido;
  final List<EfemerideDeportiva> efemerides;
  final String search;
  final String filterResultado;
  final String filterTipo;
  final int winningStreak;
  final String? playerName;
  final DateFormat dateFormat;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onResultadoChanged;
  final ValueChanged<String> onTipoChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onOpenFiltersModal;
  final ValueChanged<Partido> onOpenDetail;
  final ValueChanged<Partido> onEdit;
  final ValueChanged<Partido> onDelete;
  final ValueChanged<Partido> onShare;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    // Calculamos balance rápido
    var wins = 0;
    var draws = 0;
    var losses = 0;
    for (final p in partidos) {
      if (p.gano) {
        wins++;
      } else if (p.empato) {
        draws++;
      } else {
        losses++;
      }
    }

    final calcLogros = Stats.calcularLogros(partidos);

    final hasActiveFilters =
        search.isNotEmpty ||
        filterResultado != 'Todos' ||
        filterTipo != 'Todos';

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Banner de resumen rápido
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3D33), Color(0xFF087C63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF087C63).withValues(alpha: 0.25),
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
                    const Icon(
                      Icons.sports_soccer_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      playerName != null && playerName!.isNotEmpty
                          ? 'Historial • $playerName'
                          : 'Historial de Partidos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (winningStreak > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '$winningStreak ganados',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                      label: 'Partidos',
                      value: '${partidos.length}',
                      sub: 'de ${allPartidos.length}',
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _MiniStat(
                      label: 'Ganados',
                      value: '$wins',
                      color: const Color(0xFF86EFAC),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _MiniStat(
                      label: 'Empatados',
                      value: '$draws',
                      color: const Color(0xFFFDE047),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _MiniStat(
                      label: 'Perdidos',
                      value: '$losses',
                      color: const Color(0xFFFCA5A5),
                    ),
                  ],
                ),
                if (calcLogros.campeonatos > 0 ||
                    calcLogros.subcampeonatos > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (calcLogros.campeonatos > 0) ...[
                          const Text('🏆', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            '${calcLogros.campeonatos} ${calcLogros.campeonatos == 1 ? 'Campeonato' : 'Campeonatos'}',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                        if (calcLogros.campeonatos > 0 &&
                            calcLogros.subcampeonatos > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        if (calcLogros.subcampeonatos > 0) ...[
                          const Text('🥈', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            '${calcLogros.subcampeonatos} ${calcLogros.subcampeonatos == 1 ? 'Subcampeonato' : 'Subcampeonatos'}',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
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
          if (efemerides.isNotEmpty && !hasActiveFilters) ...[
            const SizedBox(height: 14),
            for (final efe in efemerides)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onOpenDetail(efe.partido),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('📅', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'UN DÍA COMO HOY • ${efe.textoAnos.toUpperCase()}',
                                      style: const TextStyle(
                                        color: Color(0xFFC7D2FE),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${efe.partido.equipo} vs ${efe.partido.rival} (${efe.partido.marcador})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  efe.partido.golesHijo > 0
                                      ? '${efe.partido.torneo} • Anotó ${efe.partido.golesHijo} ${efe.partido.golesHijo == 1 ? 'gol' : 'goles'} ⚽'
                                      : (efe.partido.esCampeon
                                          ? '${efe.partido.torneo} • ¡Salieron Campeones! 🏆'
                                          : efe.partido.torneo),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 14),

          // Barra de búsqueda rápida y botón de filtros
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar rival, torneo, cancha...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => onSearchChanged(''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Filtros avanzados',
                onPressed: onOpenFiltersModal,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Chips horizontales de filtros rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (hasActiveFilters) ...[
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 15),
                    label: const Text('Limpiar'),
                    onPressed: onClearFilters,
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                for (final res in ['Todos', 'Ganados', 'Empatados', 'Perdidos'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: filterResultado == res,
                      label: Text(res),
                      onSelected: (selected) {
                        if (selected) onResultadoChanged(res);
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: filterResultado == res
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                for (final tipo in ['Liga', 'Torneo', 'Amistoso'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: filterTipo == tipo,
                      label: Text(tipo),
                      onSelected: (selected) {
                        onTipoChanged(selected ? tipo : 'Todos');
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: filterTipo == tipo
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Lista de partidos o estado vacío
          if (partidos.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDDE6E3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_soccer_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No hay partidos que coincidan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: appInkColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasActiveFilters
                        ? 'Probá cambiando o limpiando los filtros de búsqueda.'
                        : (playerName != null && playerName!.isNotEmpty
                            ? 'Todavía no hay partidos registrados para $playerName. ¡Cargá el primero!'
                            : 'Todavía no tenés partidos registrados. ¡Cargá el primero!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  if (hasActiveFilters)
                    OutlinedButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Quitar filtros'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: onNewMatch,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Cargar primer partido'),
                    ),
                ],
              ),
            )
          else
            for (final p in partidos)
              PartidoCard(
                partido: p,
                date: dateFormat.format(p.fechaPartido.toLocal()),
                hitos: hitosPorPartido[p.documentName ??
                        p.id ??
                        '${p.fechaPartido.millisecondsSinceEpoch}_${p.nombreJugador}_${p.rival}'] ??
                    const [],
                onOpen: () => onOpenDetail(p),
                onEdit: () => onEdit(p),
                onDelete: () => onDelete(p),
                onShare: () => onShare(p),
              ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.sub,
    this.color = Colors.white,
  });

  final String label;
  final String value;
  final String? sub;
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (sub != null)
          Text(
            sub!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9.5,
            ),
          ),
      ],
    );
  }
}
