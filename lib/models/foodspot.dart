class PriceRange {
  final int min;
  final int max;
  final int averageMeal;

  const PriceRange({
    required this.min,
    required this.max,
    required this.averageMeal,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: json['min'] as int,
      max: json['max'] as int,
      averageMeal: json['average_meal'] as int,
    );
  }
}

class FoodSpot {
  final String id;
  final String name;
  final String streetAddress;
  final String nearestGate;
  final int walkingTimeMinutes;
  final List<String> cuisineType;
  final PriceRange priceRangePhp;
  final List<String> popularItems;
  final String operatingHours;
  final List<String> tags;

  const FoodSpot({
    required this.id,
    required this.name,
    required this.streetAddress,
    required this.nearestGate,
    required this.walkingTimeMinutes,
    required this.cuisineType,
    required this.priceRangePhp,
    required this.popularItems,
    required this.operatingHours,
    required this.tags,
  });

  factory FoodSpot.fromJson(Map<String, dynamic> json) {
    return FoodSpot(
      id: json['id'] as String,
      name: json['name'] as String,
      streetAddress: json['street_address'] as String,
      nearestGate: json['nearest_gate'] as String,
      walkingTimeMinutes: json['walking_time_minutes'] as int,
      cuisineType: List<String>.from(json['cuisine_type'] as List),
      priceRangePhp: PriceRange.fromJson(
        json['price_range_php'] as Map<String, dynamic>,
      ),
      popularItems: List<String>.from(json['popular_items'] as List),
      operatingHours: json['operating_hours'] as String,
      tags: List<String>.from(json['tags'] as List),
    );
  }
}
