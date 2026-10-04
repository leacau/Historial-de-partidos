import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpansionTile with unique PageStorageKey inside ListView does NOT crash', (tester) async {
    final bucket = PageStorageBucket();

    // 1. Pump ListView with PageStorageKey('tab_form_view')
    await tester.pumpWidget(
      MaterialApp(
        home: PageStorage(
          bucket: bucket,
          child: Scaffold(
            body: ListView(
              key: const PageStorageKey('tab_form_view'),
              children: [
                const SizedBox(height: 500, child: Text('Item 1')),
                const SizedBox(height: 500, child: Text('Item 2')),
                const SizedBox(height: 500, child: Text('Item 3')),
              ],
            ),
          ),
        ),
      ),
    );

    // Scroll so scroll offset is not 0 (writes double into PageStorage under tab_form_view)
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    // 2. Switch tab away (destroy ListView, saving scroll offset double into PageStorageBucket)
    await tester.pumpWidget(
      MaterialApp(
        home: PageStorage(
          bucket: bucket,
          child: const Scaffold(
            body: Text('Other Tab'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 3. Switch back to tab_form_view where ExpansionTile has its own unique PageStorageKey
    await tester.pumpWidget(
      MaterialApp(
        home: PageStorage(
          bucket: bucket,
          child: Scaffold(
            body: ListView(
              key: const PageStorageKey('tab_form_view'),
              children: [
                const SizedBox(height: 50, child: Text('Item 1')),
                PageStorage(
                  bucket: PageStorageBucket(),
                  child: ExpansionTile(
                    title: const Text('Más detalles'),
                    children: const [Text('Contenido')],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify it rendered without crashing
    expect(find.text('Más detalles'), findsOneWidget);
  });

  testWidgets('ListView.builder inside ExpansionTile optionsViewBuilder does NOT crash with type cast error', (tester) async {
    final bucket = PageStorageBucket();

    await tester.pumpWidget(
      MaterialApp(
        home: PageStorage(
          bucket: bucket,
          child: Scaffold(
            body: ListView(
              key: const PageStorageKey('tab_form_view'),
              children: [
                PageStorage(
                  bucket: PageStorageBucket(),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text('Más detalles'),
                    children: [
                    RawAutocomplete<String>(
                      optionsBuilder: (text) => ['Opción 1', 'Opción 2'],
                      optionsViewBuilder: (context, onSelected, options) {
                        return PageStorage(
                          bucket: PageStorageBucket(),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) => Text(options.elementAt(index)),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Toggle expansion so writeState is called!
    await tester.tap(find.text('Más detalles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Más detalles'));
    await tester.pumpAndSettle();

    // 2. Focus the TextField to show optionsViewBuilder
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
  });
}


