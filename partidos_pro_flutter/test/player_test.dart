import 'package:flutter_test/flutter_test.dart';
import 'package:partidos_pro/models/jugador.dart';
import 'package:partidos_pro/models/partido.dart';

void main() {
  group('Jugador Model & Multi-Player tests', () {
    test('serializa y deserializa Jugador correctamente', () {
      final jugador = Jugador(
        id: 'j123',
        nombre: 'Mateo Cau',
        apodo: 'Mati',
        clubActual: 'Cosmos FC',
        categoria: 'Cat. 2014',
        dorsal: '10',
        posicionHabitual: 'Delantero',
        colorHex: 0xFF087C63,
      );

      final map = jugador.toMap();
      final fromMap = Jugador.fromMap(map);

      expect(fromMap.id, 'j123');
      expect(fromMap.nombre, 'Mateo Cau');
      expect(fromMap.apodo, 'Mati');
      expect(fromMap.clubActual, 'Cosmos FC');
      expect(fromMap.categoria, 'Cat. 2014');
      expect(fromMap.dorsal, '10');
      expect(fromMap.posicionHabitual, 'Delantero');
      expect(fromMap.colorHex, 0xFF087C63);
      expect(fromMap.iniciales, 'MC');
      expect(fromMap.nombreDisplay, 'Mateo Cau "Mati"');
      expect(fromMap.subtituloDisplay, 'Cosmos FC • #10 • Cat. 2014');

      final jsonStr = jugador.toJson();
      final fromJson = Jugador.fromJson(jsonStr);
      expect(fromJson.nombre, 'Mateo Cau');
      expect(fromJson.dorsal, '10');
    });

    test('las estadísticas de múltiples jugadores no se mezclan', () {
      final jugador1 = Jugador(
        id: '1',
        nombre: 'Mateo',
        clubActual: 'Cosmos FC',
        dorsal: '10',
      );
      final jugador2 = Jugador(
        id: '2',
        nombre: 'Benjamín',
        clubActual: 'Club Colón',
        dorsal: '5',
      );

      final baseDate = DateTime.utc(2025, 9, 10);

      final partidoMateo1 = Partido(
        nombreJugador: jugador1.nombre,
        temporada: '2025',
        tipoPartido: 'Torneo',
        torneo: 'Torneo Valesanito',
        fase: 'Final',
        copa: 'Oro',
        equipo: jugador1.clubActual,
        rival: 'Boca Juniors',
        cancha: 'Esperanza',
        fechaTexto: '10/09/2025',
        fechaPartido: baseDate,
        posicion: 'Delantero',
        analisis: 'Excelente',
        scoreHijo: 3,
        scoreRival: 1,
        golesHijo: 2,
        asistencias: 1,
        minutosJugados: 40,
        tarjetasAmarillas: 0,
        tarjetasRojas: 0,
        figuraPartido: true,
        penales: false,
        scorePenalesEquipo: 0,
        scorePenalesRival: 0,
        penalHijo: 'No pateo',
      );

      final partidoBenja1 = Partido(
        nombreJugador: jugador2.nombre,
        temporada: '2025',
        tipoPartido: 'Torneo',
        torneo: 'Torneo San Jerónimo',
        fase: 'Final',
        copa: 'Oro',
        equipo: jugador2.clubActual,
        rival: 'River Plate',
        cancha: 'San Jerónimo',
        fechaTexto: '12/09/2025',
        fechaPartido: baseDate.add(const Duration(days: 2)),
        posicion: 'Mediocampista',
        analisis: 'Muy buen partido',
        scoreHijo: 0,
        scoreRival: 1,
        golesHijo: 0,
        asistencias: 0,
        minutosJugados: 35,
        tarjetasAmarillas: 1,
        tarjetasRojas: 0,
        figuraPartido: false,
        penales: false,
        scorePenalesEquipo: 0,
        scorePenalesRival: 0,
        penalHijo: 'No pateo',
      );

      final todosPartidos = [partidoMateo1, partidoBenja1];

      // Particionado estricto por jugador
      final partidosMateo = todosPartidos
          .where((p) => p.nombreJugador == jugador1.nombre)
          .toList();
      final statsMateo = Stats.fromPartidos(partidosMateo);

      final partidosBenja = todosPartidos
          .where((p) => p.nombreJugador == jugador2.nombre)
          .toList();
      final statsBenja = Stats.fromPartidos(partidosBenja);

      // Verificación de Mateo: 1 PJ, 1 PG, 2 goles, 1 asistencia, 1 Campeón 🏆, 0 Subcampeón
      expect(statsMateo.pj, 1);
      expect(statsMateo.pg, 1);
      expect(statsMateo.gp, 2);
      expect(statsMateo.asistencias, 1);
      expect(statsMateo.figuras, 1);
      expect(statsMateo.campeonatos, 1);
      expect(statsMateo.subcampeonatos, 0);

      // Verificación de Benjamín: 1 PJ, 1 PP, 0 goles, 0 asistencias, 0 Campeón, 1 Subcampeón 🥈
      expect(statsBenja.pj, 1);
      expect(statsBenja.pp, 1);
      expect(statsBenja.gp, 0);
      expect(statsBenja.asistencias, 0);
      expect(statsBenja.figuras, 0);
      expect(statsBenja.campeonatos, 0);
      expect(statsBenja.subcampeonatos, 1);

      // Se comprueba que no hay contaminación entre ambos perfiles
      expect(statsMateo.gp, isNot(equals(statsBenja.gp)));
      expect(statsMateo.campeonatos, isNot(equals(statsBenja.campeonatos)));
    });
  });
}
