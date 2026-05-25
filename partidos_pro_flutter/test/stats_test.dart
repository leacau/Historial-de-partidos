import 'package:flutter_test/flutter_test.dart';
import 'package:partidos_pro/main.dart';

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
}
