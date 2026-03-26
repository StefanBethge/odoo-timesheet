import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/app_controller.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  late final TextEditingController _passwordController;
  String? _error;
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricUnlock());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF7F3EB),
              Color(0xFFE9F0F8),
              Color(0xFFDCE7F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'App entsperren',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Zum Fortfahren die App entsperren.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.controller.canUseBiometric) ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: widget.controller.isBusy
                            ? null
                            : _tryBiometricUnlock,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Mit Biometrie entsperren'),
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Odoo-Passwort',
                      ),
                      onSubmitted: (_) => _unlockWithPassword(),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed:
                          widget.controller.isBusy ? null : _unlockWithPassword,
                      child: const Text('Mit Passwort entsperren'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _tryBiometricUnlock() async {
    if (_biometricAttempted || !widget.controller.canUseBiometric) {
      return;
    }
    _biometricAttempted = true;
    final unlocked = await widget.controller.unlockWithBiometrics();
    if (!mounted || unlocked) {
      return;
    }
    setState(() {
      _error =
          'Biometrische Entsperrung nicht moeglich. Bitte Odoo-Passwort eingeben.';
    });
  }

  Future<void> _unlockWithPassword() async {
    final unlocked = await widget.controller.unlockWithPassword(
      _passwordController.text,
    );
    if (!mounted || unlocked) {
      return;
    }
    setState(() {
      _error = 'Das eingegebene Odoo-Passwort ist nicht korrekt.';
    });
  }
}
