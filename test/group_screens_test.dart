import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinider/screens/group_screens.dart';

void main() {
  testWidgets('room code keypad accepts zero and erases the last digit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomCodeScreen(gate: 'P. Noval', budget: 'Regular'),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('erase'), findsOneWidget);

    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));

    await tester.tap(find.text('erase'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('online room creator can select a four-player room', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomCodeScreen(gate: 'P. Noval', budget: 'Regular'),
      ),
    );

    await tester.tap(find.text('Create a new room instead'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('2')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: dialog, matching: find.byIcon(Icons.add)),
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: dialog, matching: find.byIcon(Icons.add)),
    );
    await tester.pump();

    expect(
      find.descendant(of: dialog, matching: find.text('4')),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
