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
}
