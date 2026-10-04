import 'package:flutter/material.dart';
import '../models/partido.dart';

// Colores globales de la aplicación
const appAccentColor = Color(0xFF087C63);
const appInkColor = Color(0xFF17211F);
const appFieldFillColor = Color(0xFFF7FAF9);
const appMutedColor = Color(0xFF6B7280);

class Header extends StatelessWidget {
  const Header({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: appAccentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.sports_soccer_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: appInkColor,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: appAccentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appFieldFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class SecurityRow extends StatelessWidget {
  const SecurityRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.stats, this.compact = false});

  final Stats stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('PJ', stats.pj, appInkColor),
      ('PG', stats.pg, Colors.green.shade700),
      ('PE', stats.pe, Colors.orange.shade800),
      ('PP', stats.pp, Colors.red.shade700),
      ('GF', stats.gf, Colors.blue.shade700),
      ('GC', stats.gc, Colors.blueGrey.shade700),
      ('DG', stats.dg, Colors.indigo.shade700),
      ('GP', stats.gp, appAccentColor),
      ('AST', stats.asistencias, Colors.teal.shade700),
      ('FIG', stats.figuras, Colors.purple.shade700),
      ('MIN', stats.minutos, Colors.brown.shade700),
      ('TAR', stats.amarillas + stats.rojas, Colors.deepOrange.shade700),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: compact ? 1.15 : 1.05,
      children: [
        for (final item in items)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE6E3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.$1,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.$2}',
                  style: TextStyle(
                    fontSize: 22,
                    color: item.$3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class CalendarCell extends StatelessWidget {
  const CalendarCell({
    super.key,
    required this.day,
    required this.count,
    this.onTap,
  });

  final int day;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: active
              ? appAccentColor.withValues(alpha: 0.12)
              : appFieldFillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? appAccentColor : const Color(0xFFDDE6E3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: const TextStyle(fontWeight: FontWeight.w900)),
            if (active)
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  color: appAccentColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PartidoChip extends StatelessWidget {
  const PartidoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: appAccentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Transición fluida entre pantallas estilo Material 3 Shared Axis X.
///
/// Preserva el estado completo de todas las pantallas hijas (scroll, formularios,
/// selección de filtros) dentro de un [Stack] con [Offstage], eliminando
/// saltos visuales o recargas bruscas.
class SharedAxisTabSwitcher extends StatefulWidget {
  const SharedAxisTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 260),
    this.slideOffset = 0.07,
  });

  final int currentIndex;
  final List<Widget> children;
  final Duration duration;
  final double slideOffset;

  @override
  State<SharedAxisTabSwitcher> createState() => _SharedAxisTabSwitcherState();
}

class _SharedAxisTabSwitcherState extends State<SharedAxisTabSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIncoming;
  late Animation<double> _fadeOutgoing;
  late Animation<Offset> _slideIncoming;
  late Animation<Offset> _slideOutgoing;

  int _previousIndex = 0;
  int _targetIndex = 0;
  bool _isMovingRight = true;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _targetIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _updateAnimations();
    _controller.value = 1.0;
  }

  void _updateAnimations() {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeIncoming = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _fadeOutgoing = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeInQuad),
      ),
    );

    final dir = _isMovingRight ? widget.slideOffset : -widget.slideOffset;
    _slideIncoming = Tween<Offset>(
      begin: Offset(dir, 0.0),
      end: Offset.zero,
    ).animate(curved);

    _slideOutgoing = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-dir * 0.6, 0.0),
    ).animate(curved);
  }

  @override
  void didUpdateWidget(covariant SharedAxisTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _targetIndex = widget.currentIndex;
      _isMovingRight = _targetIndex > _previousIndex;
      _updateAnimations();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isAnimating = _controller.isAnimating;

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final isTarget = index == _targetIndex;
            final isPrevious = index == _previousIndex;

            if (!isAnimating) {
              return Offstage(
                offstage: !isTarget,
                child: TickerMode(
                  enabled: isTarget,
                  child: FocusScope(
                    canRequestFocus: isTarget,
                    child: widget.children[index],
                  ),
                ),
              );
            }

            if (isTarget) {
              return FadeTransition(
                opacity: _fadeIncoming,
                child: SlideTransition(
                  position: _slideIncoming,
                  child: FocusScope(
                    canRequestFocus: true,
                    child: widget.children[index],
                  ),
                ),
              );
            } else if (isPrevious) {
              return FadeTransition(
                opacity: _fadeOutgoing,
                child: SlideTransition(
                  position: _slideOutgoing,
                  child: IgnorePointer(
                    child: widget.children[index],
                  ),
                ),
              );
            } else {
              return Offstage(
                offstage: true,
                child: TickerMode(
                  enabled: false,
                  child: widget.children[index],
                ),
              );
            }
          }),
        );
      },
    );
  }
}

