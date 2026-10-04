import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partidos_pro/widgets/common_widgets.dart';

void main() {
  testWidgets('SharedAxisTabSwitcher cambia de pestaña y mantiene estado', (tester) async {
    var currentIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SharedAxisTabSwitcher(
                currentIndex: currentIndex,
                children: const [
                  Text('Pantalla 0'),
                  Text('Pantalla 1'),
                  Text('Pantalla 2'),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (idx) {
                  setState(() => currentIndex = idx);
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'P0'),
                  NavigationDestination(icon: Icon(Icons.star), label: 'P1'),
                  NavigationDestination(icon: Icon(Icons.person), label: 'P2'),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Inicialmente Pantalla 0 visible
    expect(find.text('Pantalla 0'), findsOneWidget);

    // Tap en pestaña 1
    await tester.tap(find.text('P1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Ahora Pantalla 1 visible
    expect(find.text('Pantalla 1'), findsOneWidget);

    // Tap en pestaña 2
    await tester.tap(find.text('P2'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla 2'), findsOneWidget);

    // Tap de vuelta a pestaña 0 (movimiento a la izquierda)
    await tester.tap(find.text('P0'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla 0'), findsOneWidget);
  });
}
