import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Tests', () {
    // Test básico que verifica que el framework funciona
    testWidgets('Flutter test framework is working',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Test'))),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('Counter increments smoke test', (WidgetTester tester) async {
      // Test simple de contador sin Firebase
      await tester.pumpWidget(
        MaterialApp(
          home: _TestCounterWidget(),
        ),
      );

      // Verificar que el contador comienza en 0
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Tap en el botón +
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verificar que el contador se incrementó a 1
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });
  });
}

// Widget de test simple con contador
class _TestCounterWidget extends StatefulWidget {
  @override
  _TestCounterWidgetState createState() => _TestCounterWidgetState();
}

class _TestCounterWidgetState extends State<_TestCounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
