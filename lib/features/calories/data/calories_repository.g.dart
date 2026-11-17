// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calories_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(caloriesRepository)
final caloriesRepositoryProvider = CaloriesRepositoryProvider._();

final class CaloriesRepositoryProvider
    extends
        $FunctionalProvider<
          CaloriesRepository,
          CaloriesRepository,
          CaloriesRepository
        >
    with $Provider<CaloriesRepository> {
  CaloriesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'caloriesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$caloriesRepositoryHash();

  @$internal
  @override
  $ProviderElement<CaloriesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CaloriesRepository create(Ref ref) {
    return caloriesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaloriesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaloriesRepository>(value),
    );
  }
}

String _$caloriesRepositoryHash() =>
    r'436f8438b68f42f817a3c497d454d71a717ef691';

/// State tanggal aktif pada layar Kalori (default: hari ini).

@ProviderFor(SelectedCalorieDate)
final selectedCalorieDateProvider = SelectedCalorieDateProvider._();

/// State tanggal aktif pada layar Kalori (default: hari ini).
final class SelectedCalorieDateProvider
    extends $NotifierProvider<SelectedCalorieDate, DateTime> {
  /// State tanggal aktif pada layar Kalori (default: hari ini).
  SelectedCalorieDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCalorieDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCalorieDateHash();

  @$internal
  @override
  SelectedCalorieDate create() => SelectedCalorieDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedCalorieDateHash() =>
    r'976cb0be149241a1e30f19304368e8e3c4e1f010';

/// State tanggal aktif pada layar Kalori (default: hari ini).

abstract class _$SelectedCalorieDate extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(selectedDailyCalorieSummary)
final selectedDailyCalorieSummaryProvider =
    SelectedDailyCalorieSummaryProvider._();

final class SelectedDailyCalorieSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyCalorieSummary>,
          AsyncValue<DailyCalorieSummary>,
          AsyncValue<DailyCalorieSummary>
        >
    with $Provider<AsyncValue<DailyCalorieSummary>> {
  SelectedDailyCalorieSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDailyCalorieSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDailyCalorieSummaryHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<DailyCalorieSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<DailyCalorieSummary> create(Ref ref) {
    return selectedDailyCalorieSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DailyCalorieSummary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DailyCalorieSummary>>(
        value,
      ),
    );
  }
}

String _$selectedDailyCalorieSummaryHash() =>
    r'485faa24eaabf8fa56fae9d30c8d8b7cf562dae8';

@ProviderFor(todayCalorieSummary)
final todayCalorieSummaryProvider = TodayCalorieSummaryProvider._();

final class TodayCalorieSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyCalorieSummary>,
          AsyncValue<DailyCalorieSummary>,
          AsyncValue<DailyCalorieSummary>
        >
    with $Provider<AsyncValue<DailyCalorieSummary>> {
  TodayCalorieSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayCalorieSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayCalorieSummaryHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<DailyCalorieSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<DailyCalorieSummary> create(Ref ref) {
    return todayCalorieSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DailyCalorieSummary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DailyCalorieSummary>>(
        value,
      ),
    );
  }
}

String _$todayCalorieSummaryHash() =>
    r'727be2706e9336916691d069f4b8dd145803be3c';
