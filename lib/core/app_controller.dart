import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/services/app_unlock_service.dart';
import 'package:odoo_timesheet/core/services/odoo_gateway.dart';
import 'package:odoo_timesheet/core/services/settings_store.dart';
import 'package:odoo_timesheet/core/utils/formatters.dart';

class AppController extends ChangeNotifier {
  AppController({
    required SettingsStore settingsStore,
    required OdooGateway gateway,
    AppUnlockService? unlockService,
  })  : _settingsStore = settingsStore,
        _gateway = gateway,
        _unlockService = unlockService ?? LocalAuthUnlockService();

  final SettingsStore _settingsStore;
  final OdooGateway _gateway;
  final AppUnlockService _unlockService;

  AppSettings _settings = AppSettings.empty();
  DateTime _selectedMonday = mondayFor(DateTime.now());
  WeekSnapshot? _week;
  AttendanceStatus? _attendance;
  bool _isBootstrapped = false;
  bool _isUnlocked = false;
  bool _isBiometricAvailable = false;
  bool _isBusy = false;
  String? _errorMessage;

  AppSettings get settings => _settings;
  DateTime get selectedMonday => _selectedMonday;
  WeekSnapshot? get week => _week;
  AttendanceStatus? get attendance => _attendance;
  bool get isBootstrapped => _isBootstrapped;
  bool get isUnlocked => _isUnlocked;
  bool get canUseBiometric =>
      _settings.lockEnabled &&
      _settings.biometricUnlockEnabled &&
      _isBiometricAvailable;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    if (_isBootstrapped) {
      return;
    }
    _settings = await _settingsStore.load();
    _isBiometricAvailable = await _resolveBiometricAvailability(_settings);
    _isUnlocked = !_settings.lockEnabled;
    _isBootstrapped = true;
    notifyListeners();
    if (_settings.isConfigured && _isUnlocked) {
      await refresh();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _runBusy(() async {
      await _gateway.validateConnection(settings);
      await _settingsStore.save(settings);
      _settings = settings;
      _isBiometricAvailable = await _resolveBiometricAvailability(settings);
      _isUnlocked = true;
      _selectedMonday = mondayFor(DateTime.now());
      await _reloadData();
    });
  }

  Future<bool> unlockWithBiometrics() async {
    if (!canUseBiometric) {
      return false;
    }
    final unlocked = await _unlockService.authenticateWithBiometrics();
    if (!unlocked) {
      return false;
    }
    await _completeUnlock();
    return true;
  }

  Future<bool> unlockWithPassword(String password) async {
    if (password != _settings.webPassword) {
      return false;
    }
    await _completeUnlock();
    return true;
  }

  void lock() {
    if (!_settings.lockEnabled) {
      return;
    }
    _isUnlocked = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _runBusy(_reloadData);
  }

  Future<void> goToPreviousWeek() async {
    _selectedMonday = _selectedMonday.subtract(const Duration(days: 7));
    notifyListeners();
    await refresh();
  }

  Future<void> goToNextWeek() async {
    _selectedMonday = _selectedMonday.add(const Duration(days: 7));
    notifyListeners();
    await refresh();
  }

  Future<void> addSearchItem(SearchItem item) async {
    await _runBusy(() async {
      _week = await _gateway.addRow(
        settings: _settings,
        monday: _selectedMonday,
        item: item,
      );
      _attendance ??= await _gateway.loadAttendance(settings: _settings);
    });
  }

  Future<void> createEntry({
    required DateTime monday,
    required String rowKey,
    required int dayIndex,
    required EntryDraft draft,
  }) async {
    await _runBusy(() async {
      _week = await _gateway.createEntry(
        settings: _settings,
        monday: monday,
        rowKey: rowKey,
        dayIndex: dayIndex,
        draft: draft,
      );
    });
  }

  Future<void> updateEntry({
    required DateTime monday,
    required String rowKey,
    required int entryId,
    required EntryDraft draft,
  }) async {
    await _runBusy(() async {
      _week = await _gateway.updateEntry(
        settings: _settings,
        monday: monday,
        rowKey: rowKey,
        entryId: entryId,
        draft: draft,
      );
    });
  }

  Future<void> deleteEntry({
    required DateTime monday,
    required String rowKey,
    required int entryId,
  }) async {
    await _runBusy(() async {
      _week = await _gateway.deleteEntry(
        settings: _settings,
        monday: monday,
        rowKey: rowKey,
        entryId: entryId,
      );
    });
  }

  Future<List<SearchItem>> searchItems({
    required bool filtered,
    required String query,
  }) {
    return _gateway.searchItems(
      settings: _settings,
      filtered: filtered,
      query: query,
    );
  }

  Future<void> toggleAttendance() async {
    await _runBusy(() async {
      _attendance = await _gateway.toggleAttendance(settings: _settings);
    });
  }

  Future<void> _reloadData() async {
    _week = await _gateway.loadWeek(
      settings: _settings,
      monday: _selectedMonday,
    );
    _attendance = await _gateway.loadAttendance(settings: _settings);
  }

  Future<void> _completeUnlock() async {
    _isUnlocked = true;
    notifyListeners();
    if (_settings.isConfigured) {
      await refresh();
    }
  }

  Future<bool> _resolveBiometricAvailability(AppSettings settings) async {
    if (!settings.biometricUnlockEnabled) {
      return false;
    }
    return _unlockService.isBiometricAvailable();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
