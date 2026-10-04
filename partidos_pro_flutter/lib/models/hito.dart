import 'package:flutter/material.dart';
import 'partido.dart';

enum TipoHito {
  debut,
  debutClub,
  partidoRedondo,
  primerGol,
  golRedondo,
  hatTrick,
  poker,
  campeon,
  subcampeon,
  figura,
  efemeride,
}

class HitoDeportivo {
  const HitoDeportivo({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.partido,
    required this.fecha,
    required this.emoji,
    required this.color,
    this.numero,
    this.esDestacado = false,
  });

  final String id;
  final TipoHito tipo;
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final Partido partido;
  final DateTime fecha;
  final String emoji;
  final Color color;
  final int? numero;
  final bool esDestacado;

  String get matchKey =>
      partido.documentName ??
      partido.id ??
      '${partido.fechaPartido.millisecondsSinceEpoch}_${partido.nombreJugador}_${partido.rival}';
}

class EfemerideDeportiva {
  const EfemerideDeportiva({
    required this.partido,
    required this.anosAtras,
  });

  final Partido partido;
  final int anosAtras;

  String get textoAnos => anosAtras == 1 ? 'hace 1 año' : 'hace $anosAtras años';
}

class HitoDetector {
  static const List<int> _partidosClave = [10, 25, 50, 75, 100, 150, 200, 250, 300, 400, 500];
  static const List<int> _golesClave = [10, 25, 50, 100, 150, 200];

  /// Calcula todos los hitos deportivos para una lista de partidos de un jugador,
  /// procesándolos en riguroso orden cronológico.
  static List<HitoDeportivo> calcularHitos(Iterable<Partido> partidos) {
    if (partidos.isEmpty) return [];

    final list = List<Partido>.from(partidos)
      ..sort((a, b) => a.fechaPartido.compareTo(b.fechaPartido));

    final hitos = <HitoDeportivo>[];
    final clubesVistos = <String>{};
    var partidosCount = 0;
    var totalGoles = 0;
    var primerGolDetectado = false;

    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      partidosCount++;
      final fecha = p.fechaPartido;
      final clubKey = p.equipo.trim().toLowerCase();

      // 1. Debut Oficial absoluto
      if (partidosCount == 1) {
        hitos.add(
          HitoDeportivo(
            id: 'debut_${p.id ?? i}',
            tipo: TipoHito.debut,
            titulo: '🌟 Debut Oficial',
            subtitulo: p.equipo.isNotEmpty ? 'Con ${p.equipo}' : 'Primer partido registrado',
            descripcion: 'Primer partido oficial registrado en su historial',
            partido: p,
            fecha: fecha,
            emoji: '🌟',
            color: const Color(0xFFF59E0B), // Dorado
            esDestacado: true,
          ),
        );
      }

      // 2. Debut en un nuevo club (si cambió de camiseta)
      if (clubKey.isNotEmpty && !clubesVistos.contains(clubKey) && partidosCount > 1) {
        hitos.add(
          HitoDeportivo(
            id: 'debut_club_${clubKey}_${p.id ?? i}',
            tipo: TipoHito.debutClub,
            titulo: '👕 Debut en ${p.equipo}',
            subtitulo: 'Primera vez con estos colores',
            descripcion: 'Debut defendiendo la camiseta de ${p.equipo}',
            partido: p,
            fecha: fecha,
            emoji: '👕',
            color: const Color(0xFF0284C7), // Azul cielo
            esDestacado: false,
          ),
        );
      }
      if (clubKey.isNotEmpty) {
        clubesVistos.add(clubKey);
      }

      // 3. Partidos redondos (#10, #25, #50, #100, etc.)
      if (_partidosClave.contains(partidosCount)) {
        final (emoji, color, titulo) = switch (partidosCount) {
          10 => ('🔟', const Color(0xFF0D9488), 'Partido #10'),
          25 => ('🥉', const Color(0xFFD97706), 'Partido #25'),
          50 => ('🥈', const Color(0xFFF59E0B), '¡Partido #50!'),
          75 => ('🥇', const Color(0xFFEAB308), '¡Partido #75!'),
          100 => ('💯', const Color(0xFFB45309), '¡Partido #100!'),
          _ => ('⭐', const Color(0xFF4F46E5), '¡Partido #$partidosCount!'),
        };

        hitos.add(
          HitoDeportivo(
            id: 'pj_$partidosCount',
            tipo: TipoHito.partidoRedondo,
            titulo: titulo,
            subtitulo: 'vs ${p.rival} (${p.torneo})',
            descripcion: 'Alcanzó la marca de $partidosCount partidos disputados',
            partido: p,
            fecha: fecha,
            emoji: emoji,
            color: color,
            numero: partidosCount,
            esDestacado: partidosCount >= 25,
          ),
        );
      }

      // 4. Goles / Tries / Puntos
      if (p.golesHijo > 0) {
        final sport = p.sportConfig;
        final anotacionNombre = sport.id == 'rugby' ? 'Try' : (sport.id == 'basquet' ? 'Puntos' : 'Gol');
        // Primer gol / try / anotación en la historia
        if (!primerGolDetectado) {
          primerGolDetectado = true;
          hitos.add(
            HitoDeportivo(
              id: 'primer_gol_${p.id ?? i}',
              tipo: TipoHito.primerGol,
              titulo: '${sport.emoji} ¡Primer $anotacionNombre!',
              subtitulo: 'Frente a ${p.rival}',
              descripcion: 'Inauguró su cuenta personal en ${p.torneo}',
              partido: p,
              fecha: fecha,
              emoji: sport.emoji,
              color: const Color(0xFF10B981), // Esmeralda
              esDestacado: true,
            ),
          );
        }

        // Hat-trick (3 goles) o Póker (4+ goles)
        if (p.golesHijo == 3) {
          hitos.add(
            HitoDeportivo(
              id: 'hattrick_${p.id ?? i}',
              tipo: TipoHito.hatTrick,
              titulo: '🎩 ¡Hat-trick!',
              subtitulo: '3 goles vs ${p.rival}',
              descripcion: 'Actuación brillante con 3 goles en el partido',
              partido: p,
              fecha: fecha,
              emoji: '🎩',
              color: const Color(0xFF8B5CF6), // Violeta
              esDestacado: true,
            ),
          );
        } else if (p.golesHijo >= 4) {
          hitos.add(
            HitoDeportivo(
              id: 'poker_${p.id ?? i}',
              tipo: TipoHito.poker,
              titulo: '⚡ ¡Póker (${p.golesHijo} goles)!',
              subtitulo: '${p.golesHijo} goles vs ${p.rival}',
              descripcion: 'Jornada inolvidable anotando ${p.golesHijo} goles',
              partido: p,
              fecha: fecha,
              emoji: '⚡',
              color: const Color(0xFFEC4899), // Rosa intenso
              esDestacado: true,
            ),
          );
        }

        // Metas de goles acumulados
        final prevGoles = totalGoles;
        totalGoles += p.golesHijo;

        for (final meta in _golesClave) {
          if (prevGoles < meta && totalGoles >= meta) {
            hitos.add(
              HitoDeportivo(
                id: 'goles_$meta',
                tipo: TipoHito.golRedondo,
                titulo: '🔥 ¡Gol #$meta!',
                subtitulo: 'Alcanzó los $meta goles',
                descripcion: 'Superó la barrera de los $meta goles convertidos',
                partido: p,
                fecha: fecha,
                emoji: '🔥',
                color: const Color(0xFFEA580C), // Naranja fuego
                numero: meta,
                esDestacado: true,
              ),
            );
          }
        }
      }

      // 5. Campeonatos y Subcampeonatos
      if (p.esCampeon) {
        hitos.add(
          HitoDeportivo(
            id: 'campeon_${p.id ?? i}',
            tipo: TipoHito.campeon,
            titulo: '🏆 ¡Campeón!',
            subtitulo: p.copa.isNotEmpty ? '${p.torneo} • ${p.copa}' : p.torneo,
            descripcion: 'Ganó la final ${p.marcador} frente a ${p.rival}',
            partido: p,
            fecha: fecha,
            emoji: '🏆',
            color: const Color(0xFFEAB308), // Oro
            esDestacado: true,
          ),
        );
      } else if (p.esSubcampeon) {
        hitos.add(
          HitoDeportivo(
            id: 'subcampeon_${p.id ?? i}',
            tipo: TipoHito.subcampeon,
            titulo: '🥈 Subcampeón',
            subtitulo: p.torneo,
            descripcion: 'Final disputada frente a ${p.rival}',
            partido: p,
            fecha: fecha,
            emoji: '🥈',
            color: const Color(0xFF64748B), // Plata/Pizarra
            esDestacado: false,
          ),
        );
      }

      // 6. Figura del Partido (si no tuvo otro hito destacado en ese mismo juego)
      if (p.figuraPartido && p.golesHijo < 3 && !p.esCampeon) {
        hitos.add(
          HitoDeportivo(
            id: 'figura_${p.id ?? i}',
            tipo: TipoHito.figura,
            titulo: '⭐ Figura del Partido',
            subtitulo: 'vs ${p.rival}',
            descripcion: 'Elegido el jugador más valioso del encuentro',
            partido: p,
            fecha: fecha,
            emoji: '⭐',
            color: const Color(0xFFF59E0B),
            esDestacado: false,
          ),
        );
      }
    }

    // Retornar ordenados del más reciente al más antiguo para línea de tiempo
    hitos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return hitos;
  }

  /// Mapea los hitos hacia la clave única del partido correspondiente
  static Map<String, List<HitoDeportivo>> calcularHitosPorPartido(
    Iterable<Partido> partidos,
  ) {
    final todos = calcularHitos(partidos);
    final map = <String, List<HitoDeportivo>>{};

    for (final hito in todos) {
      final key = hito.matchKey;
      map.putIfAbsent(key, () => []).add(hito);
    }
    return map;
  }

  /// Detecta si algún partido fue jugado "un día como hoy" (mismo mes y día en años anteriores)
  static List<EfemerideDeportiva> detectarEfemerides(
    Iterable<Partido> partidos, {
    DateTime? fechaHoy,
  }) {
    final hoy = fechaHoy ?? DateTime.now();
    final efemerides = <EfemerideDeportiva>[];

    for (final p in partidos) {
      final fechaLocal = p.fechaPartido.toLocal();
      if (fechaLocal.month == hoy.month &&
          fechaLocal.day == hoy.day &&
          fechaLocal.year < hoy.year) {
        final diffAnos = hoy.year - fechaLocal.year;
        efemerides.add(
          EfemerideDeportiva(
            partido: p,
            anosAtras: diffAnos,
          ),
        );
      }
    }

    efemerides.sort((a, b) => b.partido.fechaPartido.compareTo(a.partido.fechaPartido));
    return efemerides;
  }
}
