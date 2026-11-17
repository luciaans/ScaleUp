// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_export_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(csvExportService)
final csvExportServiceProvider = CsvExportServiceProvider._();

final class CsvExportServiceProvider
    extends
        $FunctionalProvider<
          CsvExportService,
          CsvExportService,
          CsvExportService
        >
    with $Provider<CsvExportService> {
  CsvExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvExportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$csvExportServiceHash();

  @$internal
  @override
  $ProviderElement<CsvExportService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CsvExportService create(Ref ref) {
    return csvExportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CsvExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CsvExportService>(value),
    );
  }
}

String _$csvExportServiceHash() => r'fc888bb14f523d497d4780598c5908c20babdfa6';
