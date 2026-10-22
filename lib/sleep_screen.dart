import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_screen.dart';

final _hoursPattern = RegExp(r'^\d{0,2}([.,]\d{0,2})?$');

Widget sleepScreen() => LogScreen(
      title: 'Sleep',
      table: 'sleep',
      addLabel: 'Log sleep',
      formBuilder: _sleepForm,
      describe: (row) {
        final notes = row['notes'] as String? ?? '';
        return LogRow(
          title: '${row['hours']} hours',
          subtitle: notes.isEmpty
              ? 'Night of ${row['night']}'
              : 'Night of ${row['night']} · $notes',
        );
      },
    );

Future<Map<String, Object?>?> _sleepForm(BuildContext context) {
  final hoursController = TextEditingController();
  final notesController = TextEditingController();
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log sleep'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: hoursController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Up to 2 digits before and 2 after the decimal point (7.25).
            inputFormatters: [
              TextInputFormatter.withFunction((old, value) =>
                  _hoursPattern.hasMatch(value.text) ? value : old),
            ],
            decoration: const InputDecoration(
              labelText: 'Hours slept',
              hintText: 'e.g. 7.25',
            ),
          ),
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. woke up twice, felt rested',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final hours = double.tryParse(
                hoursController.text.trim().replaceAll(',', '.'));
            if (hours == null || hours <= 0 || hours > 24) return;
            Navigator.pop(context, {
              'night': today(),
              'hours': double.parse(hours.toStringAsFixed(2)),
              'notes': notesController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
