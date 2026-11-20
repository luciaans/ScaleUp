import 'package:material_ui/material_ui.dart';

import '../../features/onboarding/domain/user_enums.dart';

/// A compact crop of the app's cat artwork for the gender choices.
class GenderCatFace extends StatelessWidget {
  const GenderCatFace({
    super.key,
    required this.gender,
    required this.color,
    this.size = 24,
  });

  final Gender gender;
  final Color color;
  final double size;

  String get _assetPath => switch (gender) {
    Gender.male => 'assets/cats/cat_smudge.png',
    Gender.female => 'assets/cats/cat_thumbsup.png',
  };

  @override
  Widget build(BuildContext context) => Image.asset(
    _assetPath,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) =>
        Icon(Icons.pets_rounded, size: size * 0.72, color: color),
  );
}
