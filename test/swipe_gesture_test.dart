import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinider/screens/swipe_screens.dart';
import 'package:tinider/widgets/food_image_placeholder.dart';

void main() {
  testWidgets('left and right drags record the matching swipe directions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: FoodSwipeScreen(gate: '', budget: 'All'),
      ),
    );
    for (var index = 0; index < 20; index++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.drag(find.byType(FoodImagePlaceholder), const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(FoodImagePlaceholder), const Offset(180, 0));
    await tester.pumpAndSettle();

    for (
      var index = 0;
      index < 30 && find.byType(MatchScreen).evaluate().isEmpty;
      index++
    ) {
      await tester.tap(find.text('Pass'));
      await tester.pumpAndSettle();
    }

    expect(find.byType(MatchScreen), findsOneWidget);
    final matchScreen = tester.widget<MatchScreen>(find.byType(MatchScreen));
    expect(matchScreen.spot.name, 'Dimsum Treats (Juaning)');
  });
}
