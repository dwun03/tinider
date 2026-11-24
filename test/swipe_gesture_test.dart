import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinider/models/foodspot.dart';
import 'package:tinider/screens/setup_screens.dart';
import 'package:tinider/screens/swipe_screens.dart';
import 'package:tinider/widgets/food_image_placeholder.dart';

void main() {
  testWidgets('budget choices show the revised labels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: WhereAtScreen()));

    expect(find.text('Tipid'), findsOneWidget);
    expect(find.text("Deserve 'Ko To"), findsOneWidget);
  });

  testWidgets('WalkCard shows the selected spot address and walking time', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const spot = FoodSpot(
      id: 'test',
      name: 'Test Spot',
      streetAddress: '123 Test Street',
      nearestGate: 'Dapitan',
      walkingTimeMinutes: 7,
      cuisineType: ['Test'],
      priceRangePhp: PriceRange(min: 100, max: 180, averageMeal: 140),
      popularItems: ['Test meal'],
      operatingHours: '8 AM-8 PM',
      tags: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WalkCardScreen(gate: 'Dapitan', spot: spot),
      ),
    );

    expect(find.text('123 Test Street · 7 min walk'), findsOneWidget);
  });

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
