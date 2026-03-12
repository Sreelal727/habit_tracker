import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_settings.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final result = await (select(userSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setValue(String key, String value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final val = await getValue(key);
    if (val == null) return defaultValue;
    return val == 'true';
  }

  Future<void> setBool(String key, bool value) {
    return setValue(key, value.toString());
  }
}
