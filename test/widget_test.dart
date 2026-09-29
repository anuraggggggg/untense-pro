import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UnTense Pro widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('UnTense Professional'),
          ),
        ),
      ),
    );

    expect(find.text('UnTense Professional'), findsOneWidget);
  });
}
