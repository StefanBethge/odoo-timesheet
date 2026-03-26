import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/utils/formatters.dart';

Future<EntryDraft?> showEntryEditorDialog(
  BuildContext context, {
  required String title,
  required String initialDescription,
  required String initialHours,
}) {
  return showDialog<EntryDraft>(
    context: context,
    builder: (context) => _EntryEditorDialog(
      title: title,
      initialDescription: initialDescription,
      initialHours: initialHours,
    ),
  );
}

class _EntryEditorDialog extends StatefulWidget {
  const _EntryEditorDialog({
    required this.title,
    required this.initialDescription,
    required this.initialHours,
  });

  final String title;
  final String initialDescription;
  final String initialHours;

  @override
  State<_EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<_EntryEditorDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _hoursController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _hoursController = TextEditingController(text: widget.initialHours);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _hoursController,
            decoration: const InputDecoration(
              labelText: 'Stunden',
              hintText: '1.5 oder 1:30',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Beschreibung'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _submit() {
    try {
      final description = _descriptionController.text.trim();
      if (description.isEmpty) {
        throw const FormatException('Beschreibung ist erforderlich.');
      }
      final hours = parseHours(_hoursController.text);
      Navigator.of(context).pop(
        EntryDraft(description: description, hours: hours),
      );
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }
}
