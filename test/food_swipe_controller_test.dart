import 'package:flutter_test/flutter_test.dart';
import 'package:tinider/controllers/food_swipe_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Tipid filters food spots to meals costing at most ₱99', () async {
    final controller = FoodSwipeController(gate: '', budget: 'Tipid');
    addTearDown(controller.dispose);

    await controller.loadCards();

    expect(controller.cards, isNotEmpty);
    expect(
      controller.cards.every((spot) => spot.priceRangePhp.averageMeal <= 99),
      isTrue,
    );
  });

  test("Deserve 'Ko To filters food spots to meals costing at least ₱181", () async {
    final controller = FoodSwipeController(gate: '', budget: "Deserve 'Ko To");
    addTearDown(controller.dispose);

    await controller.loadCards();

    expect(controller.cards, isNotEmpty);
    expect(
      controller.cards.every((spot) => spot.priceRangePhp.averageMeal >= 181),
      isTrue,
    );
  });
}