import 'package:flutter_test/flutter_test.dart';
import 'package:partidos_pro/models/familia.dart';
import 'package:partidos_pro/models/jugador.dart';
import 'package:partidos_pro/models/partido.dart';

void main() {
  group('GrupoFamiliar Model Tests', () {
    test('Serialización y deserialización a Map de GrupoFamiliar', () {
      final jugador = Jugador(
        id: 'j1',
        nombre: 'Salvador',
        clubActual: 'Cosmos FC',
        dorsal: '10',
        posicionHabitual: 'Delantero',
      );

      final grupo = GrupoFamiliar(
        id: 'fam_123',
        codigo: 'SALVI7',
        ownerUid: 'uid_admin_1',
        nombreFamilia: 'Familia de Salvador',
        miembros: ['uid_admin_1', 'uid_abuelo_2'],
        jugadores: [jugador],
        creadoEn: DateTime(2026, 10, 5),
      );

      expect(grupo.isOwner('uid_admin_1'), isTrue);
      expect(grupo.isOwner('uid_abuelo_2'), isFalse);
      expect(grupo.totalMiembros, equals(2));

      final map = grupo.toMap();
      expect(map['codigo'], equals('SALVI7'));
      expect(map['ownerUid'], equals('uid_admin_1'));
      expect(map['nombreFamilia'], equals('Familia de Salvador'));
      expect(map['miembros'], contains('uid_abuelo_2'));

      final reconstructed = GrupoFamiliar.fromMap('fam_123', {
        'codigo': 'SALVI7',
        'ownerUid': 'uid_admin_1',
        'nombreFamilia': 'Familia de Salvador',
        'miembros': ['uid_admin_1', 'uid_abuelo_2'],
        'jugadores': [jugador.toMap()],
      });

      expect(reconstructed.id, equals('fam_123'));
      expect(reconstructed.codigo, equals('SALVI7'));
      expect(reconstructed.nombreFamilia, equals('Familia de Salvador'));
      expect(reconstructed.jugadores.length, equals(1));
      expect(reconstructed.jugadores.first.nombre, equals('Salvador'));
    });
  });

  group('Partido resultadoTexto tests', () {
    test('resultadoTexto devuelve Ganó, Empató y Perdió correctamente', () {
      final pGanado = Partido(
        nombreJugador: 'Salvador',
        temporada: '2026',
        tipoPartido: 'Torneo',
        torneo: 'Liga',
        fase: 'Fase Regular',
        copa: 'Oro',
        equipo: 'Cosmos FC',
        rival: 'Rival FC',
        cancha: 'Cancha 1',
        fechaTexto: '05/10/2026',
        fechaPartido: DateTime.now(),
        posicion: 'Delantero',
        analisis: '',
        scoreHijo: 3,
        scoreRival: 1,
        golesHijo: 2,
        asistencias: 1,
        minutosJugados: 50,
        tarjetasAmarillas: 0,
        tarjetasRojas: 0,
        figuraPartido: true,
        penales: false,
        scorePenalesEquipo: 0,
        scorePenalesRival: 0,
        penalHijo: '',
      );

      expect(pGanado.gano, isTrue);
      expect(pGanado.resultadoTexto, equals('Ganó'));

      final pEmpatado = pGanado.copyWith(scoreHijo: 2, scoreRival: 2);
      expect(pEmpatado.empato, isTrue);
      expect(pEmpatado.resultadoTexto, equals('Empató'));

      final pPerdido = pGanado.copyWith(scoreHijo: 0, scoreRival: 2);
      expect(pPerdido.gano, isFalse);
      expect(pPerdido.empato, isFalse);
      expect(pPerdido.resultadoTexto, equals('Perdió'));
    });
  });
}
