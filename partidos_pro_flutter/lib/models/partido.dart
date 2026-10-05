import 'package:cloud_firestore/cloud_firestore.dart' as fb_firestore;
import 'package:intl/intl.dart';
import 'deporte.dart';

class Partido {
  Partido({
    this.documentName,
    this.id,
    required this.nombreJugador,
    required this.temporada,
    required this.tipoPartido,
    required this.torneo,
    required this.fase,
    required this.copa,
    required this.equipo,
    required this.rival,
    required this.cancha,
    this.canchaLat,
    this.canchaLng,
    required this.fechaTexto,
    required this.fechaPartido,
    required this.posicion,
    required this.analisis,
    required this.scoreHijo,
    required this.scoreRival,
    required this.golesHijo,
    required this.asistencias,
    required this.minutosJugados,
    required this.tarjetasAmarillas,
    required this.tarjetasRojas,
    required this.figuraPartido,
    required this.penales,
    required this.scorePenalesEquipo,
    required this.scorePenalesRival,
    required this.penalHijo,
    this.foto,
    this.fotoPath,
    this.creadoEn,
    this.deporte = 'futbol',
    this.scoreDetalle,
  });

  final String? documentName;
  final String? id;
  final String nombreJugador;
  final String temporada;
  final String tipoPartido;
  final String torneo;
  final String fase;
  final String copa;
  final String equipo;
  final String rival;
  final String cancha;
  final double? canchaLat;
  final double? canchaLng;
  final String fechaTexto;
  final DateTime fechaPartido;
  final String posicion;
  final String analisis;
  final int scoreHijo;
  final int scoreRival;
  final int golesHijo;
  final int asistencias;
  final int minutosJugados;
  final int tarjetasAmarillas;
  final int tarjetasRojas;
  final bool figuraPartido;
  final bool penales;
  final int scorePenalesEquipo;
  final int scorePenalesRival;
  final String penalHijo;
  final String? foto;
  final String? fotoPath;
  final DateTime? creadoEn;
  final String deporte;
  final String? scoreDetalle;

  SportConfig get sportConfig => SportConfig.fromId(deporte);

  bool get gano =>
      scoreHijo > scoreRival ||
      (penales && scorePenalesEquipo > scorePenalesRival);

  bool get empato => scoreHijo == scoreRival && !penales;

  String get resultadoTexto {
    if (gano) return 'Ganó';
    if (empato) return 'Empató';
    return 'Perdió';
  }

  bool get esFinal =>
      tipoPartido.trim().toLowerCase() == 'torneo' &&
      fase.trim().toLowerCase() == 'final';

  bool get esCampeon => esFinal && gano;

  bool get esSubcampeon => esFinal && !gano;

  String get marcador {
    if (scoreDetalle != null && scoreDetalle!.trim().isNotEmpty) {
      return '$scoreHijo - $scoreRival ($scoreDetalle)';
    }
    if (!penales) return '$scoreHijo - $scoreRival';
    return '$scoreHijo ($scorePenalesEquipo) - ($scorePenalesRival) $scoreRival';
  }

  Partido copyWith({
    String? documentName,
    String? id,
    String? nombreJugador,
    String? temporada,
    String? tipoPartido,
    String? torneo,
    String? fase,
    String? copa,
    String? equipo,
    String? rival,
    String? cancha,
    double? canchaLat,
    double? canchaLng,
    bool clearLocation = false,
    String? fechaTexto,
    DateTime? fechaPartido,
    String? posicion,
    String? analisis,
    int? scoreHijo,
    int? scoreRival,
    int? golesHijo,
    int? asistencias,
    int? minutosJugados,
    int? tarjetasAmarillas,
    int? tarjetasRojas,
    bool? figuraPartido,
    bool? penales,
    int? scorePenalesEquipo,
    int? scorePenalesRival,
    String? penalHijo,
    String? foto,
    String? fotoPath,
    bool clearPhoto = false,
    DateTime? creadoEn,
    String? deporte,
    String? scoreDetalle,
    bool clearScoreDetalle = false,
  }) {
    return Partido(
      documentName: documentName ?? this.documentName,
      id: id ?? this.id,
      nombreJugador: nombreJugador ?? this.nombreJugador,
      temporada: temporada ?? this.temporada,
      tipoPartido: tipoPartido ?? this.tipoPartido,
      torneo: torneo ?? this.torneo,
      fase: fase ?? this.fase,
      copa: copa ?? this.copa,
      equipo: equipo ?? this.equipo,
      rival: rival ?? this.rival,
      cancha: cancha ?? this.cancha,
      canchaLat: clearLocation ? null : (canchaLat ?? this.canchaLat),
      canchaLng: clearLocation ? null : (canchaLng ?? this.canchaLng),
      fechaTexto: fechaTexto ?? this.fechaTexto,
      fechaPartido: fechaPartido ?? this.fechaPartido,
      posicion: posicion ?? this.posicion,
      analisis: analisis ?? this.analisis,
      scoreHijo: scoreHijo ?? this.scoreHijo,
      scoreRival: scoreRival ?? this.scoreRival,
      golesHijo: golesHijo ?? this.golesHijo,
      asistencias: asistencias ?? this.asistencias,
      minutosJugados: minutosJugados ?? this.minutosJugados,
      tarjetasAmarillas: tarjetasAmarillas ?? this.tarjetasAmarillas,
      tarjetasRojas: tarjetasRojas ?? this.tarjetasRojas,
      figuraPartido: figuraPartido ?? this.figuraPartido,
      penales: penales ?? this.penales,
      scorePenalesEquipo: scorePenalesEquipo ?? this.scorePenalesEquipo,
      scorePenalesRival: scorePenalesRival ?? this.scorePenalesRival,
      penalHijo: penalHijo ?? this.penalHijo,
      foto: clearPhoto ? null : (foto ?? this.foto),
      fotoPath: clearPhoto ? null : (fotoPath ?? this.fotoPath),
      creadoEn: creadoEn ?? this.creadoEn,
      deporte: deporte ?? this.deporte,
      scoreDetalle: clearScoreDetalle ? null : (scoreDetalle ?? this.scoreDetalle),
    );
  }

  static Partido fromSnapshot(
    fb_firestore.DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final fechaTexto = _str(data['fecha']);
    final fechaPartido =
        _date(data['fecha_partido']) ??
        _parseDateText(fechaTexto) ??
        _date(data['timestamp']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return Partido(
      documentName: doc.reference.path,
      id: doc.id,
      nombreJugador: _str(data['nombre_jugador'], 'Mi Hijo'),
      temporada: _str(data['temporada'], '${fechaPartido.toLocal().year}'),
      tipoPartido: _str(data['tipo_partido'], 'Liga'),
      torneo: _str(data['torneo'], 'Sin torneo'),
      fase: _str(data['fase'], 'Fase de Grupos'),
      copa: _str(data['copa'], 'Ninguna'),
      equipo: _firstStr(data, [
        'equipo',
        'equipo_hijo',
        'equipo_jugador',
        'mi_equipo',
      ], 'Cosmos FC'),
      rival: _str(data['rival'], 'Rival'),
      cancha: _str(data['cancha']),
      canchaLat: _double(data['cancha_lat']) ?? _double(data['lat']),
      canchaLng: _double(data['cancha_lng']) ?? _double(data['lng']),
      fechaTexto: fechaTexto,
      fechaPartido: fechaPartido,
      posicion: _str(data['posicion'], 'Delantero'),
      analisis: _str(data['analisis']),
      scoreHijo: _int(data['score_hijo']),
      scoreRival: _int(data['score_rival']),
      golesHijo: _int(data['goles_hijo'], _int(data['goles'])),
      asistencias: _int(data['asistencias']),
      minutosJugados: _int(data['minutos_jugados']),
      tarjetasAmarillas: _int(data['tarjetas_amarillas']),
      tarjetasRojas: _int(data['tarjetas_rojas']),
      figuraPartido: _bool(data['figura_partido']),
      penales: _bool(data['penales']),
      scorePenalesEquipo: _int(data['score_penales_equipo']),
      scorePenalesRival: _int(data['score_penales_rival']),
      penalHijo: _str(data['penal_hijo'], 'No pateo'),
      foto: _str(data['foto']).isEmpty ? null : _str(data['foto']),
      fotoPath: _str(data['foto_path']).isEmpty
          ? null
          : _str(data['foto_path']),
      creadoEn: _date(data['creado_en']),
      deporte: _str(data['deporte'], 'futbol'),
      scoreDetalle: _str(data['score_detalle']).isEmpty
          ? null
          : _str(data['score_detalle']),
    );
  }

  Map<String, dynamic> toMap({
    required String ownerUid,
    bool includeCreated = false,
  }) {
    final now = DateTime.now().toUtc();
    final fields = <String, dynamic>{
      'ownerUid': ownerUid,
      'nombre_jugador': nombreJugador,
      'temporada': temporada,
      'tipo_partido': tipoPartido,
      'torneo': torneo,
      'fase': tipoPartido == 'Torneo' ? fase : '',
      'copa': tipoPartido == 'Torneo' ? copa : 'Ninguna',
      'equipo': equipo,
      'equipo_hijo': equipo,
      'equipo_jugador': equipo,
      'rival': rival,
      'cancha': cancha,
      'cancha_lat': canchaLat,
      'cancha_lng': canchaLng,
      'fecha': fechaTexto,
      'fecha_partido': fb_firestore.Timestamp.fromDate(fechaPartido),
      'timestamp': fb_firestore.Timestamp.fromDate(fechaPartido),
      'actualizado_en': fb_firestore.Timestamp.fromDate(now),
      'posicion': posicion,
      'analisis': analisis,
      'score_hijo': scoreHijo,
      'score_rival': scoreRival,
      'goles_hijo': golesHijo,
      'asistencias': asistencias,
      'minutos_jugados': minutosJugados,
      'tarjetas_amarillas': tarjetasAmarillas,
      'tarjetas_rojas': tarjetasRojas,
      'figura_partido': figuraPartido,
      'penales': penales,
      'score_penales_equipo': penales ? scorePenalesEquipo : 0,
      'score_penales_rival': penales ? scorePenalesRival : 0,
      'penal_hijo': penales ? penalHijo : 'No pateo',
      'foto': foto ?? '',
      'foto_path': fotoPath ?? '',
      'deporte': deporte,
      'score_detalle': scoreDetalle ?? '',
    };
    if (includeCreated) {
      fields['creado_en'] = fb_firestore.Timestamp.fromDate(now);
    }
    return fields;
  }
}

class TorneoLogro {
  const TorneoLogro({
    required this.torneo,
    required this.temporada,
    required this.copa,
    required this.campeon,
    required this.finalMatch,
  });

  final String torneo;
  final String temporada;
  final String copa;
  final bool campeon;
  final Partido finalMatch;

  String get tituloDisplay {
    final copaTxt = (copa.isNotEmpty && copa.toLowerCase() != 'ninguna')
        ? ' (Copa $copa)'
        : '';
    final tempTxt = temporada.isNotEmpty ? ' $temporada' : '';
    return '$torneo$copaTxt$tempTxt';
  }
}

class Stats {
  Stats();

  int pj = 0;
  int pg = 0;
  int pe = 0;
  int pp = 0;
  int gf = 0;
  int gc = 0;
  int gp = 0;
  int asistencias = 0;
  int figuras = 0;
  int minutos = 0;
  int amarillas = 0;
  int rojas = 0;
  int campeonatos = 0;
  int subcampeonatos = 0;
  final List<TorneoLogro> logros = [];

  int get dg => gf - gc;

  void add(Partido p) {
    pj++;
    gf += p.scoreHijo;
    gc += p.scoreRival;
    gp += p.golesHijo;
    asistencias += p.asistencias;
    figuras += p.figuraPartido ? 1 : 0;
    minutos += p.minutosJugados;
    amarillas += p.tarjetasAmarillas;
    rojas += p.tarjetasRojas;
    if (p.gano) {
      pg++;
    } else if (p.empato) {
      pe++;
    } else {
      pp++;
    }
  }

  static ({int campeonatos, int subcampeonatos, List<TorneoLogro> logros})
  calcularLogros(Iterable<Partido> partidos) {
    final finalMatchesByTorneo = <String, List<Partido>>{};
    for (final p in partidos) {
      if (p.esFinal) {
        final key =
            '${p.torneo.trim().toLowerCase()}__${p.temporada.trim()}__${p.copa.trim().toLowerCase()}';
        finalMatchesByTorneo.putIfAbsent(key, () => []).add(p);
      }
    }

    var camps = 0;
    var subcamps = 0;
    final listaLogros = <TorneoLogro>[];

    for (final matches in finalMatchesByTorneo.values) {
      matches.sort((a, b) => b.fechaPartido.compareTo(a.fechaPartido));
      final finalMatch = matches.first;
      final esCamp = finalMatch.gano;
      if (esCamp) {
        camps++;
      } else {
        subcamps++;
      }
      listaLogros.add(
        TorneoLogro(
          torneo: finalMatch.torneo,
          temporada: finalMatch.temporada,
          copa: finalMatch.copa,
          campeon: esCamp,
          finalMatch: finalMatch,
        ),
      );
    }

    listaLogros.sort(
      (a, b) => b.finalMatch.fechaPartido.compareTo(a.finalMatch.fechaPartido),
    );
    return (
      campeonatos: camps,
      subcampeonatos: subcamps,
      logros: listaLogros,
    );
  }

  static Stats fromPartidos(Iterable<Partido> partidos) {
    final stats = Stats();
    for (final p in partidos) {
      stats.add(p);
    }
    final calc = calcularLogros(partidos);
    stats.campeonatos = calc.campeonatos;
    stats.subcampeonatos = calc.subcampeonatos;
    stats.logros.addAll(calc.logros);
    return stats;
  }
}

// Helpers de parseo que estaban sueltos en main.dart
String _str(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String _firstStr(
  Map<String, dynamic> data,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = _str(data[key]).trim();
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double? _double(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

DateTime? _date(dynamic value) {
  if (value is fb_firestore.Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

DateTime? _parseDateText(String raw) {
  if (raw.trim().isEmpty) return null;
  for (final format in ['dd/MM/yyyy HH:mm', 'dd/MM/yyyy']) {
    try {
      return DateFormat(format).parse(raw).toUtc();
    } catch (_) {
      continue;
    }
  }
  return null;
}
