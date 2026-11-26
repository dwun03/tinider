import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/foodspot.dart';
import '../theme/tinider_theme.dart';

class FoodImagePlaceholder extends StatelessWidget {
  final FoodSpot spot;

  const FoodImagePlaceholder({super.key, required this.spot});

  static const _foodspotsDirectory = 'assets/images/Foodspots/';
  static final Future<Map<String, String>> _imagePaths =
      AssetManifest.loadFromAssetBundle(rootBundle).then((manifest) {
        return {
          for (final assetPath in manifest.listAssets())
            if (assetPath.startsWith(_foodspotsDirectory))
              assetPath.substring(_foodspotsDirectory.length).split('_').first:
                  assetPath,
        };
      });

  static const _backgrounds = [
    TiniderColors.yellow,
    TiniderColors.mint,
    TiniderColors.green,
    TiniderColors.pink,
  ];

  Color get _backgroundColor {
    final hash = spot.id.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return _backgrounds[hash % _backgrounds.length];
  }

  IconData get _cuisineIcon {
    final cuisines = spot.cuisineType.join(' ').toLowerCase();
    if (cuisines.contains('dimsum') ||
        cuisines.contains('chinese') ||
        cuisines.contains('noodle')) {
      return Icons.ramen_dining;
    }
    if (cuisines.contains('coffee') || cuisines.contains('dessert')) {
      return Icons.local_cafe;
    }
    if (cuisines.contains('chicken') || cuisines.contains('wings')) {
      return Icons.fastfood;
    }
    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imagePaths.then((paths) => paths[spot.id.toLowerCase()]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }

        final imagePath = snapshot.data;
        if (imagePath != null) {
          return SizedBox.expand(
            child: Image.asset(imagePath, fit: BoxFit.cover),
          );
        }

        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: _backgroundColor,
      padding: const EdgeInsets.all(16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: TiniderColors.cream.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: TiniderColors.cream,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _cuisineIcon,
                      size: 60,
                      color: TiniderColors.brown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      spot.name.replaceAll(RegExp(r' \(.+\)$'), ''),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: TiniderColors.brown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Photo coming soon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TiniderColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}