import 'package:flutter/material.dart';
import 'package:odoo_timesheet/app/app_theme.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/features/auth/unlock_screen.dart';
import 'package:odoo_timesheet/features/home/home_screen.dart';
import 'package:odoo_timesheet/features/settings/settings_screen.dart';

class OdooTimesheetApp extends StatefulWidget {
  const OdooTimesheetApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<OdooTimesheetApp> createState() => _OdooTimesheetAppState();
}

class _OdooTimesheetAppState extends State<OdooTimesheetApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Odoo Timesheet',
          theme: buildAppTheme(),
          debugShowCheckedModeBanner: false,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    final controller = widget.controller;
    if (!controller.isBootstrapped) {
      return const _SplashScreen();
    }
    if (!controller.settings.isConfigured) {
      return SettingsScreen(
        controller: controller,
        isOnboarding: true,
      );
    }
    if (!controller.isUnlocked) {
      return UnlockScreen(controller: controller);
    }
    return HomeScreen(controller: controller);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Odoo Timesheet',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Konfiguration wird geladen',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
