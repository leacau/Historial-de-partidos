import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partidos_pro/models/partido.dart';
import 'package:partidos_pro/views/data_management_view.dart';
import 'package:partidos_pro/main.dart';

void main() {
  final testPartidos = [
    Partido(
      id: '1',
      documentName: 'doc_1',
      nombreJugador: 'Salvador',
      temporada: '2026',
      tipoPartido: 'Torneo',
      torneo: 'Torneo Apertura Err',
      fase: 'Fecha 1',
      copa: 'Ninguna',
      equipo: 'Cosmos FC',
      rival: 'Union SF',
      cancha: 'Predio Los Molinos',
      fechaTexto: '01/05/2026 10:00',
      fechaPartido: DateTime.utc(2026, 5, 1, 10),
      posicion: 'Delantero',
      analisis: '',
      scoreHijo: 2,
      scoreRival: 1,
      golesHijo: 1,
      asistencias: 0,
      minutosJugados: 40,
      tarjetasAmarillas: 0,
      tarjetasRojas: 0,
      figuraPartido: false,
      penales: false,
      scorePenalesEquipo: 0,
      scorePenalesRival: 0,
      penalHijo: 'No pateo',
    ),
    Partido(
      id: '2',
      documentName: 'doc_2',
      nombreJugador: 'Salvador',
      temporada: '2026',
      tipoPartido: 'Torneo',
      torneo: 'Torneo Apertura',
      fase: 'Fecha 2',
      copa: 'Ninguna',
      equipo: 'Cosmos FC',
      rival: 'Colon',
      cancha: 'Predio Los Molinos',
      fechaTexto: '08/05/2026 10:00',
      fechaPartido: DateTime.utc(2026, 5, 8, 10),
      posicion: 'Delantero',
      analisis: '',
      scoreHijo: 1,
      scoreRival: 1,
      golesHijo: 0,
      asistencias: 1,
      minutosJugados: 40,
      tarjetasAmarillas: 0,
      tarjetasRojas: 0,
      figuraPartido: false,
      penales: false,
      scorePenalesEquipo: 0,
      scorePenalesRival: 0,
      penalHijo: 'No pateo',
    ),
    Partido(
      id: '3',
      documentName: 'doc_3',
      nombreJugador: 'Salvador',
      temporada: '2026',
      tipoPartido: 'Liga',
      torneo: 'Liga Santafesina',
      fase: 'Fecha 3',
      copa: 'Ninguna',
      equipo: 'Cosmos FC',
      rival: 'Union Santa Fe',
      cancha: 'Cancha Cosmos',
      canchaLat: -31.6,
      canchaLng: -60.7,
      fechaTexto: '15/05/2026 10:00',
      fechaPartido: DateTime.utc(2026, 5, 15, 10),
      posicion: 'Delantero',
      analisis: '',
      scoreHijo: 3,
      scoreRival: 0,
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
    ),
  ];

  group('Data Normalization Logic', () {
    test('Renombrar torneo actualiza los partidos correspondientes', () {
      const currentTorneo = 'Torneo Apertura Err';
      const targetTorneo = 'Torneo Apertura Oficial';

      final matching = testPartidos.where((p) => p.torneo == currentTorneo).toList();
      expect(matching.length, 1);

      final updated = matching.map((p) => p.copyWith(torneo: targetTorneo)).toList();
      expect(updated.first.torneo, targetTorneo);
      expect(updated.first.id, '1');
    });

    test('Unificar torneos actualiza partidos al torneo destino', () {
      const sourceTorneo = 'Torneo Apertura Err';
      const destinationTorneo = 'Torneo Apertura';

      final matching = testPartidos.where((p) => p.torneo == sourceTorneo).toList();
      final updated = matching.map((p) => p.copyWith(torneo: destinationTorneo)).toList();

      expect(updated.length, 1);
      expect(updated.first.torneo, 'Torneo Apertura');
    });

    test('Asignar coordenadas a un predio actualiza lat y lng en lote', () {
      const targetCancha = 'Predio Los Molinos';
      final matching = testPartidos.where((p) => p.cancha == targetCancha).toList();
      expect(matching.length, 2);

      const newLat = -31.5542;
      const newLng = -60.6891;

      final updated = matching.map((p) => p.copyWith(canchaLat: newLat, canchaLng: newLng)).toList();

      for (final p in updated) {
        expect(p.canchaLat, newLat);
        expect(p.canchaLng, newLng);
      }
    });

    test('Quitar coordenadas con clearLocation limpia lat y lng', () {
      final pWithLocation = testPartidos.firstWhere((p) => p.canchaLat != null);
      expect(pWithLocation.canchaLat, isNotNull);

      final cleared = pWithLocation.copyWith(clearLocation: true);
      expect(cleared.canchaLat, isNull);
      expect(cleared.canchaLng, isNull);
    });

    test('Unificar rivales actualiza el rival preservando el resto de los datos', () {
      const sourceRival = 'Union Santa Fe';
      const destRival = 'Union SF';

      final matching = testPartidos.where((p) => p.rival == sourceRival).toList();
      final updated = matching.map((p) => p.copyWith(rival: destRival)).toList();

      expect(updated.first.rival, destRival);
      expect(updated.first.golesHijo, 2);
    });
  });

  group('DataManagementView Widget Tests', () {
    testWidgets('Muestra pestañas de Torneos, Predios y Rivales', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataManagementView(
            partidos: List.from(testPartidos),
            onUpdatePartidos: (updated, message) async {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gestión y Depuración de Datos'), findsOneWidget);
      expect(find.textContaining('Torneos'), findsOneWidget);
      expect(find.textContaining('Predios'), findsOneWidget);
      expect(find.textContaining('Rivales'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Buscador

      // En la pestaña Torneos debe listar los torneos del mock
      expect(find.text('Torneo Apertura Err'), findsOneWidget);
      expect(find.text('Torneo Apertura'), findsOneWidget);
      expect(find.text('Liga Santafesina'), findsOneWidget);

      // Cambiar a la pestaña Predios
      await tester.tap(find.textContaining('Predios'));
      await tester.pumpAndSettle();

      expect(find.text('Predio Los Molinos'), findsOneWidget);
      expect(find.text('Cancha Cosmos'), findsOneWidget);

      // Cambiar a la pestaña Rivales
      await tester.tap(find.textContaining('Rivales'));
      await tester.pumpAndSettle();

      expect(find.text('Union SF'), findsOneWidget);
      expect(find.text('Colon'), findsOneWidget);
      expect(find.text('Union Santa Fe'), findsOneWidget);
    });

    testWidgets('SuggestField filtra correctamente al escribir "Complej" y no trunca arbitrariamente', (tester) async {
      final controller = TextEditingController();
      final options = [
        'Campo de Deportes 1',
        'Campo de Deportes 2',
        'Cancha La Tatenguita',
        'Club Argentino',
        'Club Ateneo',
        'Complejo Los Molinos',
        'Complejo San Jerónimo',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestField(
              label: 'Cancha / Predio',
              controller: controller,
              options: options,
              showAllOnTap: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Al escribir "Complej" en el campo
      await tester.enterText(find.byType(TextField), 'Complej');
      await tester.pumpAndSettle();

      // Debe mostrar las canchas que coinciden con "Complej"
      expect(find.text('Complejo Los Molinos'), findsOneWidget);
      expect(find.text('Complejo San Jerónimo'), findsOneWidget);

      // Y NO debe mostrar las que no coinciden
      expect(find.text('Campo de Deportes 1'), findsNothing);
      expect(find.text('Club Ateneo'), findsNothing);
    });
  });
}
