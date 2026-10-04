import 'package:flutter_test/flutter_test.dart';
import 'package:partidos_pro/models/hito.dart';
import 'package:partidos_pro/models/partido.dart';

Partido _crearPartido({
  required String id,
  required DateTime fecha,
  required String equipo,
  required String rival,
  String torneo = 'Torneo Apertura',
  String tipoPartido = 'Torneo',
  String fase = 'Fase de Grupos',
  String copa = '',
  int scoreHijo = 2,
  int scoreRival = 1,
  int golesHijo = 0,
  int asistencias = 0,
  bool figuraPartido = false,
  bool penales = false,
}) {
  return Partido(
    id: id,
    nombreJugador: 'Salvador',
    temporada: '${fecha.year}',
    tipoPartido: tipoPartido,
    torneo: torneo,
    fase: fase,
    copa: copa,
    equipo: equipo,
    rival: rival,
    cancha: 'Cancha Central',
    fechaTexto: '${fecha.day}/${fecha.month}/${fecha.year} 10:00',
    fechaPartido: fecha,
    posicion: 'Delantero',
    analisis: 'Gran partido',
    scoreHijo: scoreHijo,
    scoreRival: scoreRival,
    golesHijo: golesHijo,
    asistencias: asistencias,
    minutosJugados: 50,
    tarjetasAmarillas: 0,
    tarjetasRojas: 0,
    figuraPartido: figuraPartido,
    penales: penales,
    scorePenalesEquipo: 0,
    scorePenalesRival: 0,
    penalHijo: 'No pateó',
  );
}

void main() {
  group('HitoDetector Tests', () {
    test('detecta Debut Oficial y Debut en nuevo Club', () {
      final p1 = _crearPartido(
        id: 'p1',
        fecha: DateTime(2025, 3, 1),
        equipo: 'Cosmos FC',
        rival: 'Rival 1',
      );
      final p2 = _crearPartido(
        id: 'p2',
        fecha: DateTime(2025, 3, 8),
        equipo: 'Cosmos FC',
        rival: 'Rival 2',
      );
      final p3 = _crearPartido(
        id: 'p3',
        fecha: DateTime(2025, 4, 1),
        equipo: 'River Plate',
        rival: 'Boca Juniors',
      );

      final hitos = HitoDetector.calcularHitos([p1, p2, p3]);

      // Debut oficial
      final debutOficial = hitos.firstWhere((h) => h.tipo == TipoHito.debut);
      expect(debutOficial.partido.id, 'p1');
      expect(debutOficial.titulo, contains('Debut Oficial'));

      // Debut en River Plate
      final debutRiver = hitos.firstWhere((h) => h.tipo == TipoHito.debutClub);
      expect(debutRiver.partido.id, 'p3');
      expect(debutRiver.titulo, contains('Debut en River Plate'));
    });

    test('detecta Primer Gol, Hat-trick y Póker', () {
      final p1 = _crearPartido(
        id: 'p1',
        fecha: DateTime(2025, 3, 1),
        equipo: 'Cosmos FC',
        rival: 'Rival 1',
        golesHijo: 0,
      );
      final p2 = _crearPartido(
        id: 'p2',
        fecha: DateTime(2025, 3, 8),
        equipo: 'Cosmos FC',
        rival: 'Rival 2',
        golesHijo: 1, // Primer gol
      );
      final p3 = _crearPartido(
        id: 'p3',
        fecha: DateTime(2025, 3, 15),
        equipo: 'Cosmos FC',
        rival: 'Rival 3',
        golesHijo: 3, // Hat-trick
      );
      final p4 = _crearPartido(
        id: 'p4',
        fecha: DateTime(2025, 3, 22),
        equipo: 'Cosmos FC',
        rival: 'Rival 4',
        golesHijo: 4, // Póker
      );

      final hitos = HitoDetector.calcularHitos([p1, p2, p3, p4]);

      expect(hitos.any((h) => h.tipo == TipoHito.primerGol && h.partido.id == 'p2'), isTrue);
      expect(hitos.any((h) => h.tipo == TipoHito.hatTrick && h.partido.id == 'p3'), isTrue);
      expect(hitos.any((h) => h.tipo == TipoHito.poker && h.partido.id == 'p4'), isTrue);
    });

    test('detecta Partidos Redondos (#10, #25)', () {
      final matches = List.generate(25, (i) {
        return _crearPartido(
          id: 'p_${i + 1}',
          fecha: DateTime(2025, 1, 1).add(Duration(days: i * 7)),
          equipo: 'Cosmos FC',
          rival: 'Rival $i',
        );
      });

      final hitos = HitoDetector.calcularHitos(matches);

      final hito10 = hitos.firstWhere((h) => h.tipo == TipoHito.partidoRedondo && h.numero == 10);
      expect(hito10.partido.id, 'p_10');
      expect(hito10.titulo, contains('10'));

      final hito25 = hitos.firstWhere((h) => h.tipo == TipoHito.partidoRedondo && h.numero == 25);
      expect(hito25.partido.id, 'p_25');
      expect(hito25.titulo, contains('25'));
    });

    test('detecta Campeón y Subcampeón', () {
      final finalGanada = _crearPartido(
        id: 'final_1',
        fecha: DateTime(2025, 6, 1),
        equipo: 'Cosmos FC',
        rival: 'Los Halcones',
        tipoPartido: 'Torneo',
        fase: 'Final',
        scoreHijo: 3,
        scoreRival: 1,
      );
      final finalPerdida = _crearPartido(
        id: 'final_2',
        fecha: DateTime(2025, 11, 1),
        equipo: 'Cosmos FC',
        rival: 'Deportivo Sur',
        tipoPartido: 'Torneo',
        fase: 'Final',
        scoreHijo: 1,
        scoreRival: 2,
      );

      final hitos = HitoDetector.calcularHitos([finalGanada, finalPerdida]);

      expect(hitos.any((h) => h.tipo == TipoHito.campeon && h.partido.id == 'final_1'), isTrue);
      expect(hitos.any((h) => h.tipo == TipoHito.subcampeon && h.partido.id == 'final_2'), isTrue);
    });

    test('detecta Efemérides (Un día como hoy)', () {
      final hoy = DateTime(2026, 9, 18);
      final matchHaceUnAno = _crearPartido(
        id: 'hace_1_ano',
        fecha: DateTime(2025, 9, 18, 14, 0),
        equipo: 'Cosmos FC',
        rival: 'Leones FC',
      );
      final matchOtroDia = _crearPartido(
        id: 'otro_dia',
        fecha: DateTime(2025, 9, 15, 14, 0),
        equipo: 'Cosmos FC',
        rival: 'Tigres',
      );

      final efemerides = HitoDetector.detectarEfemerides(
        [matchHaceUnAno, matchOtroDia],
        fechaHoy: hoy,
      );

      expect(efemerides.length, 1);
      expect(efemerides.first.partido.id, 'hace_1_ano');
      expect(efemerides.first.anosAtras, 1);
      expect(efemerides.first.textoAnos, 'hace 1 año');
    });
  });
}
