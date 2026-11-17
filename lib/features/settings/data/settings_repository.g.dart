// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'3438db64b0bb6a4eaff60fcdb439987e740734c8';

@ProviderFor(appThemeMode)
final appThemeModeProvider = AppThemeModeProvider._();

final class AppThemeModeProvider
    extends
        $FunctionalProvider<AsyncValue<ThemeMode>, ThemeMode, Stream<ThemeMode>>
    with $FutureModifier<ThemeMode>, $StreamProvider<ThemeMode> {
  AppThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  $StreamProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ThemeMode> create(Ref ref) {
    return appThemeMode(ref);
  }
}

String _$appThemeModeHash() => r'89c2a13735503d06c6dd745f7be61944eb65b692';

@ProviderFor(appWeightUnit)
final appWeightUnitProvider = AppWeightUnitProvider._();

final class AppWeightUnitProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeightUnit>,
          WeightUnit,
          Stream<WeightUnit>
        >
    with $FutureModifier<WeightUnit>, $StreamProvider<WeightUnit> {
  AppWeightUnitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appWeightUnitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appWeightUnitHash();

  @$internal
  @override
  $StreamProviderElement<WeightUnit> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<WeightUnit> create(Ref ref) {
    return appWeightUnit(ref);
  }
}

String _$appWeightUnitHash() => r'9475e92a55f1fb4574dc9f9cfe7399c3e40bd7a7';

@ProviderFor(onboardingCompleted)
final onboardingCompletedProvider = OnboardingCompletedProvider._();

final class OnboardingCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  OnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompletedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return onboardingCompleted(ref);
  }
}

String _$onboardingCompletedHash() =>
    r'21a803f0b2e545730e0307c7e85940e0348a5c23';

@ProviderFor(reminderPreferences)
final reminderPreferencesProvider = ReminderPreferencesProvider._();

final class ReminderPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReminderPreferences>,
          ReminderPreferences,
          Stream<ReminderPreferences>
        >
    with
        $FutureModifier<ReminderPreferences>,
        $StreamProvider<ReminderPreferences> {
  ReminderPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderPreferencesHash();

  @$internal
  @override
  $StreamProviderElement<ReminderPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReminderPreferences> create(Ref ref) {
    return reminderPreferences(ref);
  }
}

String _$reminderPreferencesHash() =>
    r'21aa360c90eeef468511c77cd857c282ab06f0f6';

@ProviderFor(celebratedMilestones)
final celebratedMilestonesProvider = CelebratedMilestonesProvider._();

final class CelebratedMilestonesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  CelebratedMilestonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'celebratedMilestonesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$celebratedMilestonesHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return celebratedMilestones(ref);
  }
}

String _$celebratedMilestonesHash() =>
    r'8c60d7dc2a2b9a58f1f04c642d04ec1aa983d6d2';
