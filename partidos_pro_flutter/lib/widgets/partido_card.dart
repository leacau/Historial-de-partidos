import 'package:flutter/material.dart';
import '../models/hito.dart';
import '../models/partido.dart';
import 'common_widgets.dart';
import 'photo_viewer.dart';

class PartidoCard extends StatelessWidget {
  const PartidoCard({
    super.key,
    required this.partido,
    required this.date,
    this.hitos = const [],
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  final Partido partido;
  final String date;
  final List<HitoDeportivo> hitos;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final sport = partido.sportConfig;
    final Color resultColor;
    final String resultText;
    final IconData resultIcon;

    if (partido.gano) {
      resultColor = const Color(0xFF087C63);
      resultText = 'VICTORIA';
      resultIcon = Icons.check_circle_rounded;
    } else if (partido.empato) {
      resultColor = const Color(0xFFD97706);
      resultText = 'EMPATE';
      resultIcon = Icons.remove_circle_outline_rounded;
    } else {
      resultColor = const Color(0xFFDC2626);
      resultText = 'DERROTA';
      resultIcon = Icons.cancel_outlined;
    }

    final typeColor = switch (partido.tipoPartido) {
      'Torneo' => Colors.purple.shade700,
      'Amistoso' => Colors.teal.shade700,
      _ => Colors.blue.shade700,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: resultColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra superior de resultado y torneo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: resultColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: resultColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(resultIcon, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          resultText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${sport.emoji} ${partido.tipoPartido}',
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (partido.esCampeon) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🏆', style: TextStyle(fontSize: 10)),
                          SizedBox(width: 3),
                          Text(
                            'CAMPEÓN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (partido.esSubcampeon) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🥈', style: TextStyle(fontSize: 10)),
                          SizedBox(width: 3),
                          Text(
                            'SUBCAMPEÓN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Torneo y fase
                  Text(
                    partido.fase.isNotEmpty
                        ? '${partido.torneo} • ${partido.fase}'
                        : partido.torneo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: appInkColor,
                    ),
                  ),
                  if (hitos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: hitos.map((h) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                h.color.withValues(alpha: 0.16),
                                h.color.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: h.color.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(h.emoji, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                h.titulo,
                                style: TextStyle(
                                  color: h.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Marcador principal tipo transmisión deportiva
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2EBE8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            partido.equipo,
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: appInkColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${partido.scoreHijo} - ${partido.scoreRival}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: resultColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              if (partido.scoreDetalle != null &&
                                  partido.scoreDetalle!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    partido.scoreDetalle!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              if (partido.penales)
                                Text(
                                  '(${partido.scorePenalesEquipo} - ${partido.scorePenalesRival} pen.)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            partido.rival,
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: appInkColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Destacados de actuación de Salvador/jugador
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (partido.figuraPartido)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'FIGURA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (partido.golesHijo > 0)
                        _ChipRendimiento(
                          icon: sport.emoji,
                          label:
                              '${partido.golesHijo} ${partido.golesHijo == 1 ? (sport.id == 'rugby' ? 'try' : (sport.id == 'futbol' || sport.id == 'hockey' ? 'gol' : sport.labelAnotacionHijo.toLowerCase())) : (sport.id == 'rugby' ? 'tries' : (sport.id == 'futbol' || sport.id == 'hockey' ? 'goles' : sport.labelAnotacionHijo.toLowerCase()))}',
                          color: const Color(0xFF087C63),
                        ),
                      if (partido.asistencias > 0)
                        _ChipRendimiento(
                          icon: '👟',
                          label: '${partido.asistencias} asist.',
                          color: Colors.teal.shade700,
                        ),
                      if (partido.posicion.isNotEmpty)
                        _ChipRendimiento(
                          icon: '📍',
                          label: partido.posicion,
                          color: Colors.blueGrey.shade700,
                        ),
                      if (partido.minutosJugados > 0)
                        _ChipRendimiento(
                          icon: '⏱️',
                          label: '${partido.minutosJugados} min',
                          color: Colors.indigo.shade700,
                        ),
                    ],
                  ),

                  // Previsualización de Foto si existe
                  if (partido.foto != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        FullScreenImageViewer.show(
                          context,
                          imageUrl: partido.foto!,
                          title: '${partido.equipo} ${partido.marcador} ${partido.rival}',
                          subtitle: '${partido.torneo} • $date',
                          badge: resultText,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              partido.foto!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 150,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                    ),
                                  ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fullscreen_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ver foto',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Acciones rápidas al pie de la tarjeta
                  const SizedBox(height: 8),
                  const Divider(height: 16, thickness: 0.7),
                  Row(
                    children: [
                      if (partido.cancha.isNotEmpty) ...[
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            partido.cancha,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onShare,
                        icon: const Icon(Icons.share_outlined, size: 18),
                        tooltip: 'Compartir',
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Eliminar',
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: onOpen,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text(
                          'Detalles',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
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

class _ChipRendimiento extends StatelessWidget {
  const _ChipRendimiento({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
