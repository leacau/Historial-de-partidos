import 'package:flutter_test/flutter_test.dart';
// Cambiamos la importación para que apunte al nuevo archivo de modelos
import 'package:partidos_pro/models/partido.dart';

void main() {
  test('calcula estadisticas basicas', () {
    final stats = Stats();
    stats.add(
      Partido(
        nombreJugador: 'Salvador',
        temporada: '2026',
        tipoPartido: 'Liga',
        torneo: 'Liga',
        fase: '',
        copa: 'Ninguna',
        equipo: 'Cosmos FC',
        rival: 'Rival',
        cancha: 'Cancha',
        fechaTexto: '06/05/2026 11:00',
        fechaPartido: DateTime.utc(2026, 5, 6, 11),
        posicion: 'Delantero',
        analisis: '',
        scoreHijo: 3,
        scoreRival: 1,
        golesHijo: 2,
        asistencias: 1,
        minutosJugados: 50,
        tarjetasAmarillas: 1,
        tarjetasRojas: 0,
        figuraPartido: true,
        penales: false,
        scorePenalesEquipo: 0,
        scorePenalesRival: 0,
        penalHijo: 'No pateo',
      ),
    );

    expect(stats.pj, 1);
    expect(stats.pg, 1);
    expect(stats.gf, 3);
    expect(stats.gp, 2);
    expect(stats.asistencias, 1);
    expect(stats.figuras, 1);
  });

  test('calcula campeon y subcampeon de torneo correctamente', () {
    final finalGanada = Partido(
      nombreJugador: 'Salvador',
      temporada: '2026',
      tipoPartido: 'Torneo',
      torneo: 'Torneo San Jeronimo',
      fase: 'Final',
      copa: 'Oro',
      equipo: 'Cosmos FC',
      rival: 'Union',
      cancha: 'San Jeronimo',
      fechaTexto: '10/08/2026 15:00',
      fechaPartido: DateTime.utc(2026, 8, 10, 15),
      posicion: 'Delantero',
      analisis: '',
      scoreHijo: 2,
      scoreRival: 1,
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
    );

    final finalPerdida = Partido(
      nombreJugador: 'Salvador',
      temporada: '2026',
      tipoPartido: 'Torneo',
      torneo: 'Torneo Valesanito',
      fase: 'Final',
      copa: 'Ninguna',
      equipo: 'Cosmos FC',
      rival: 'Colon',
      cancha: 'San Jeronimo',
      fechaTexto: '15/09/2026 17:00',
      fechaPartido: DateTime.utc(2026, 9, 15, 17),
      posicion: 'Delantero',
      analisis: '',
      scoreHijo: 0,
      scoreRival: 1,
      golesHijo: 0,
      asistencias: 0,
      minutosJugados: 50,
      tarjetasAmarillas: 0,
      tarjetasRojas: 0,
      figuraPartido: false,
      penales: false,
      scorePenalesEquipo: 0,
      scorePenalesRival: 0,
      penalHijo: 'No pateo',
    );

    expect(finalGanada.esFinal, isTrue);
    expect(finalGanada.esCampeon, isTrue);
    expect(finalGanada.esSubcampeon, isFalse);

    expect(finalPerdida.esFinal, isTrue);
    expect(finalPerdida.esCampeon, isFalse);
    expect(finalPerdida.esSubcampeon, isTrue);

    final stats = Stats.fromPartidos([finalGanada, finalPerdida]);
    expect(stats.campeonatos, 1);
    expect(stats.subcampeonatos, 1);
    expect(stats.logros.length, 2);
    expect(stats.logros.any((l) => l.torneo == 'Torneo San Jeronimo' && l.campeon), isTrue);
    expect(stats.logros.any((l) => l.torneo == 'Torneo Valesanito' && !l.campeon), isTrue);
  });
}
