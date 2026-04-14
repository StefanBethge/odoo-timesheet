import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class LocalSettingsStore implements SettingsStore {
  LocalSettingsStore({
    SharedPreferences? preferences,
    FlutterSecureStorage? secureStorage,
  })  : _preferences = preferences,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferences? _preferences;
  final FlutterSecureStorage _secureStorage;

  static const IOSOptions _iosSecretOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    synchronizable: false,
  );

  static const _plainKeys = [
    'url',
    'database',
    'username',
    'bundesland',
    'dailyLow',
    'dailyHigh',
    'weeklyLow',
    'weeklyHigh',
    'lockEnabled',
    'biometricUnlockEnabled',
    'darkMode',
  ];
  static const _secretKeys = ['apiKey', 'webPassword', 'totpSecret'];

  @override
  Future<AppSettings> load() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final plain = <String, String>{};
    for (final key in _plainKeys) {
      plain[key] = prefs.getString(key) ?? '';
    }

    final secrets = <String, String>{};
    for (final key in _secretKeys) {
      secrets[key] =
          await _secureStorage.read(key: key, iOptions: _iosSecretOptions) ??
              '';
    }

    return AppSettings.fromMaps(plain, secrets);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final plain = settings.nonSecretMap();
    for (final entry in plain.entries) {
      await prefs.setString(entry.key, entry.value);
    }

    final secrets = settings.secretMap();
    for (final entry in secrets.entries) {
      await _secureStorage.write(
        key: entry.key,
        value: entry.value,
        iOptions: _iosSecretOptions,
      );
    }
  }
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([AppSettings? initial])
      : _current = initial ?? AppSettings.empty();

  AppSettings _current;

  @override
  Future<AppSettings> load() async => _current;

  @override
  Future<void> save(AppSettings settings) async {
    _current = settings;
  }
}
