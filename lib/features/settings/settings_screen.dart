import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    this.isOnboarding = false,
  });

  final AppController controller;
  final bool isOnboarding;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _databaseController;
  late final TextEditingController _usernameController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _webPasswordController;
  late final TextEditingController _totpController;
  late final TextEditingController _dailyLowController;
  late final TextEditingController _dailyHighController;
  late final TextEditingController _weeklyLowController;
  late final TextEditingController _weeklyHighController;
  late String _bundesland;
  late bool _lockEnabled;
  late bool _biometricUnlockEnabled;

  String get _selectedBundesland =>
      AppSettings.normalizeBundesland(_bundesland);

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _urlController = TextEditingController(text: settings.url);
    _databaseController = TextEditingController(text: settings.database);
    _usernameController = TextEditingController(text: settings.username);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _webPasswordController = TextEditingController(text: settings.webPassword);
    _totpController = TextEditingController(text: settings.totpSecret);
    _dailyLowController =
        TextEditingController(text: settings.dailyLow.toString());
    _dailyHighController =
        TextEditingController(text: settings.dailyHigh.toString());
    _weeklyLowController =
        TextEditingController(text: settings.weeklyLow.toString());
    _weeklyHighController =
        TextEditingController(text: settings.weeklyHigh.toString());
    _bundesland = AppSettings.normalizeBundesland(settings.bundesland);
    _lockEnabled = settings.lockEnabled;
    _biometricUnlockEnabled = settings.biometricUnlockEnabled;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _apiKeyController.dispose();
    _webPasswordController.dispose();
    _totpController.dispose();
    _dailyLowController.dispose();
    _dailyHighController.dispose();
    _weeklyLowController.dispose();
    _weeklyHighController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'Einrichtung' : 'Einstellungen'),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EB), Color(0xFFE6EEF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (widget.isOnboarding)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Die App speichert Verbindung und Zugangsdaten lokal '
                      'und synchronisiert danach Timesheets und Attendance mit Odoo.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                _SectionCard(
                  title: 'Odoo Verbindung',
                  child: Column(
                    children: [
                      _buildField(
                        controller: _urlController,
                        label: 'URL',
                        hint: 'https://odoo.example.com',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _databaseController,
                        label: 'Datenbank',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _usernameController,
                        label: 'Benutzername',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Zugangsdaten',
                  child: Column(
                    children: [
                      _buildField(
                        controller: _apiKeyController,
                        label: 'API-Key',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _webPasswordController,
                        label: 'Web-Passwort',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _totpController,
                        label: 'TOTP Secret',
                        required: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Lokale Regeln',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedBundesland,
                        items: AppSettings.bundeslaender
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _bundesland = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Bundesland',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _dailyLowController,
                              label: 'Daily Low',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _dailyHighController,
                              label: 'Daily High',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _weeklyLowController,
                              label: 'Weekly Low',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _weeklyHighController,
                              label: 'Weekly High',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'App-Schutz',
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: _lockEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('App beim Oeffnen sperren'),
                        subtitle: const Text(
                          'Beim Start ist eine Entsperrung erforderlich.',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _lockEnabled = value;
                            if (!value) {
                              _biometricUnlockEnabled = false;
                            }
                          });
                        },
                      ),
                      SwitchListTile.adaptive(
                        value: _biometricUnlockEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Biometrie bevorzugen'),
                        subtitle: const Text(
                          'Falls nicht verfuegbar, wird das Odoo-Passwort abgefragt.',
                        ),
                        onChanged: !_lockEnabled
                            ? null
                            : (value) {
                                setState(() {
                                  _biometricUnlockEnabled = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: controller.isBusy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Speichern und weiter'),
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    bool required = true,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: required
          ? (value) {
              if ((value ?? '').trim().isEmpty) {
                return '$label ist erforderlich.';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final settings = AppSettings(
      url: _urlController.text.trim(),
      database: _databaseController.text.trim(),
      username: _usernameController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      webPassword: _webPasswordController.text.trim(),
      totpSecret: _totpController.text.trim(),
      bundesland: _selectedBundesland,
      dailyLow: double.parse(_dailyLowController.text.replaceAll(',', '.')),
      dailyHigh: double.parse(_dailyHighController.text.replaceAll(',', '.')),
      weeklyLow: double.parse(_weeklyLowController.text.replaceAll(',', '.')),
      weeklyHigh: double.parse(_weeklyHighController.text.replaceAll(',', '.')),
      lockEnabled: _lockEnabled,
      biometricUnlockEnabled: _biometricUnlockEnabled,
    );

    await widget.controller.saveSettings(settings);
    if (!mounted || widget.isOnboarding) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
