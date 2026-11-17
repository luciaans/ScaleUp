import 'package:drift/drift.dart';

import '../../core/utils/date_utils_ext.dart';

/// Konverter tanggal kalender `DateTime` <-> `YYYY-MM-DD` (TEXT di SQLite).
/// Menjamin constraint UNIQUE per hari kalender dan pengurutan kronologis yang konsisten.
class IsoDateConverter extends TypeConverter<DateTime, String> {
  const IsoDateConverter();

  @override
  DateTime fromSql(String fromDb) => AppDateUtils.fromIsoDateKey(fromDb);

  @override
  String toSql(DateTime value) => AppDateUtils.toIsoDateKey(value);
}

@DataClassName('UserProfile')
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get gender => text()(); // 'male' | 'female'
  TextColumn get birthDate => text().map(const IsoDateConverter())();
  RealColumn get heightCm => real()();
  TextColumn get activityLevel => text()();
}

@TableIndex(name: 'idx_goals_start_date', columns: {#startDate})
@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'lose' | 'gain' | 'maintain'
  RealColumn get startWeight => real()();
  RealColumn get targetWeight => real()();
  RealColumn get weeklyRate => real()();
  TextColumn get startDate => text().map(const IsoDateConverter())();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@TableIndex(name: 'idx_weight_entries_date', columns: {#date})
@DataClassName('WeightEntry')
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text().unique().map(const IsoDateConverter())();
  RealColumn get weightKg => real()();
  TextColumn get note => text().nullable()();
}

@TableIndex(name: 'idx_food_items_name', columns: {#name})
@DataClassName('FoodItem')
class FoodItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get servingDesc => text()();
  RealColumn get calories => real()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fat => real()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}

@TableIndex(name: 'idx_food_logs_date', columns: {#date})
@DataClassName('FoodLog')
class FoodLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text().map(const IsoDateConverter())();
  TextColumn get mealType => text()(); // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  IntColumn get foodItemId =>
      integer().references(FoodItems, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
}

@DataClassName('SettingEntry')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
