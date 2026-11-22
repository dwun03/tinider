import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinider/screens/swipe_screens.dart';
import 'package:tinider/widgets/food_image_placeholder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    expect(find.byType(FoodImagePlaceholder), findsOneWidget);

    await tester.drag(find.byType(FoodImagePlaceholder), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('2/'), findsOneWidget);

    await tester.drag(find.byType(FoodImagePlaceholder), const Offset(180, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('3/'), findsOneWidget);
  });
}
