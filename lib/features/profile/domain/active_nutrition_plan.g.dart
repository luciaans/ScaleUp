// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_nutrition_plan.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieBaselineRaw)
final calorieBaselineRawProvider = CalorieBaselineRawProvider._();

final class CalorieBaselineRawProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  CalorieBaselineRawProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieBaselineRawProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieBaselineRawHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return calorieBaselineRaw(ref);
  }
}

String _$calorieBaselineRawHash() =>
    r'4d78b640304f50e22a36f3948b5b897df45e9a22';

@ProviderFor(activeNutritionPlan)
final activeNutritionPlanProvider = ActiveNutritionPlanProvider._();

final class ActiveNutritionPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<ActiveNutritionPlan?>,
          AsyncValue<ActiveNutritionPlan?>,
          AsyncValue<ActiveNutritionPlan?>
        >
    with $Provider<AsyncValue<ActiveNutritionPlan?>> {
  ActiveNutritionPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeNutritionPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeNutritionPlanHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<ActiveNutritionPlan?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ActiveNutritionPlan?> create(Ref ref) {
    return activeNutritionPlan(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ActiveNutritionPlan?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ActiveNutritionPlan?>>(
        value,
      ),
    );
  }
}

String _$activeNutritionPlanHash() =>
    r'94515bb28b1bea01663770b4f4d0d85caf500c1c';
