import 'package:flutter_test/flutter_test.dart';
import 'package:partidos_pro/models/deporte.dart';
import 'package:partidos_pro/models/hito.dart';
import 'package:partidos_pro/models/jugador.dart';
import 'package:partidos_pro/models/partido.dart';

void main() {
  group('SportConfig & Multi-Sport tests', () {
    test('SportConfig resuelve deportes conocidos y desconocidos', () {
      expect(SportConfig.fromId('futbol').id, 'futbol');
      expect(SportConfig.fromId('rugby').id, 'rugby');
      expect(SportConfig.fromId('hockey').id, 'hockey');
      expect(SportConfig.fromId('tenis').id, 'tenis');
      expect(SportConfig.fromId('padel').id, 'padel');
      expect(SportConfig.fromId('basquet').id, 'basquet');

      // Mayúsculas y espacios
      expect(SportConfig.fromId('  RUGBY  ').id, 'rugby');
      expect(SportConfig.fromId('Tenis').id, 'tenis');

      // Null o desconocido cae en fútbol por defecto
      expect(SportConfig.fromId(null).id, 'futbol');
      expect(SportConfig.fromId('curling').id, 'futbol');
    });

    test('las configuraciones de deporte tienen las reglas correctas', () {
      final futbol = SportConfig.futbol;
      expect(futbol.sistemaMarcador, SistemaMarcador.goles);
      expect(futbol.soportaPenales, isTrue);
      expect(futbol.soportaTarjetas, isTrue);
      expect(futbol.soportaSets, isFalse);
      expect(futbol.posicionesDisponibles, contains('Delantero'));

      final tenis = SportConfig.tenis;
      expect(tenis.sistemaMarcador, SistemaMarcador.sets);
      expect(tenis.soportaSets, isTrue);
      expect(tenis.soportaPenales, isFalse);
      expect(tenis.soportaTarjetas, isFalse);
      expect(tenis.labelPuntos, 'Sets');

      final rugby = SportConfig.rugby;
      expect(rugby.sistemaMarcador, SistemaMarcador.puntos);
      expect(rugby.labelAnotacionHijo, 'Tries');
      expect(rugby.posicionesDisponibles, contains('Apertura'));

      final basquet = SportConfig.basquet;
      expect(basquet.sistemaMarcador, SistemaMarcador.puntos);
      expect(basquet.labelAnotacionHijo, 'Puntos');
      expect(basquet.posicionesDisponibles, contains('Base'));
    });

    test('Jugador serializa deporte y mantiene retrocompatibilidad', () {
      final jugadorRugby = Jugador(
        id: 'j_rugby',
        nombre: 'Mateo',
        clubActual: 'CRAI',
        deporte: 'rugby',
        posicionHabitual: 'Apertura',
      );

      final map = jugadorRugby.toMap();
      expect(map['deporte'], 'rugby');

      final deserializado = Jugador.fromMap(map);
      expect(deserializado.deporte, 'rugby');
      expect(deserializado.sportConfig.id, 'rugby');
      expect(deserializado.sportConfig.emoji, '🏉');

      // Retrocompatibilidad: json previo sin campo 'deporte'
      final mapLegacy = {
        'id': 'legacy_1',
        'nombre': 'Salvador',
        'clubActual': 'Cosmos FC',
      };
      final jugadorLegacy = Jugador.fromMap(mapLegacy);
      expect(jugadorLegacy.deporte, 'futbol');
      expect(jugadorLegacy.sportConfig.id, 'futbol');
      expect(jugadorLegacy.sportConfig.emoji, '⚽');
    });

    test('Partido soporta deporte y scoreDetalle (sets)', () {
      final baseDate = DateTime.utc(2026, 4, 15);
      final partidoTenis = Partido(
        nombreJugador: 'Leo',
        temporada: '2026',
        tipoPartido: 'Torneo',
        torneo: 'Torneo Abierto Santa Fe',
        fase: 'Final',
        copa: 'Oro',
        equipo: 'Leo',
        rival: 'Martín',
        cancha: 'Jockey Club',
        fechaTexto: '15/04/2026',
        fechaPartido: baseDate,
        posicion: 'Singles',
        analisis: 'Gran partido en tie-break',
        scoreHijo: 2,
        scoreRival: 1,
        golesHijo: 2,
        asistencias: 0,
        minutosJugados: 90,
        tarjetasAmarillas: 0,
        tarjetasRojas: 0,
        figuraPartido: true,
        penales: false,
        scorePenalesEquipo: 0,
        scorePenalesRival: 0,
        penalHijo: 'No pateo',
        deporte: 'tenis',
        scoreDetalle: '6-4, 3-6, 7-6',
      );

      expect(partidoTenis.gano, isTrue);
      expect(partidoTenis.marcador, '2 - 1 (6-4, 3-6, 7-6)');
      expect(partidoTenis.sportConfig.id, 'tenis');
      expect(partidoTenis.sportConfig.soportaSets, isTrue);

      final map = partidoTenis.toMap(ownerUid: 'uid123');
      expect(map['deporte'], 'tenis');
      expect(map['score_detalle'], '6-4, 3-6, 7-6');
    });

    test('HitoDetector adapta primer gol/try/puntos al deporte del partido', () {
      final baseDate = DateTime.utc(2026, 3, 10);
      final partidoRugby = Partido(
        nombreJugador: 'Bautista',
        temporada: '2026',
        tipoPartido: 'Amistoso',
        torneo: 'Amistoso Apertura',
        fase: '',
        copa: 'Ninguna',
        equipo: 'Santa Fe Rugby',
        rival: 'Universitario',
        cancha: 'Sauce Viejo',
        fechaTexto: '10/03/2026',
        fechaPartido: baseDate,
        posicion: 'Wing',
        analisis: 'Debut con try',
        scoreHijo: 22,
        scoreRival: 15,
        golesHijo: 1,
        asistencias: 0,
        minutosJugados: 50,
        tarjetasAmarillas: 0,
        tarjetasRojas: 0,
        figuraPartido: true,
        penales: false,
        scorePenalesEquipo: 0,
        scorePenalesRival: 0,
        penalHijo: 'No pateo',
        deporte: 'rugby',
      );

      final hitos = HitoDetector.calcularHitos([partidoRugby]);
      final primerTry = hitos.firstWhere((h) => h.tipo == TipoHito.primerGol);
      expect(primerTry.titulo, '🏉 ¡Primer Try!');
      expect(primerTry.emoji, '🏉');
    });
  });
}
