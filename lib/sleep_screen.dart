import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_screen.dart';

final _hoursPattern = RegExp(r'^\d{0,2}([.,]\d{0,2})?$');

Widget sleepScreen() => LogScreen(
      title: 'Sleep',
      table: 'sleep',
      addLabel: 'Log sleep',
      formBuilder: _sleepForm,
      describe: (row) => (
        title: '${row['hours']} hours',
        subtitle: 'Night of ${row['night']}',
      ),
    );

Future<Map<String, Object?>?> _sleepForm(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hours slept'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        // Up to 2 digits before and 2 after the decimal point (7.25).
        inputFormatters: [
          TextInputFormatter.withFunction((old, value) =>
              _hoursPattern.hasMatch(value.text) ? value : old),
        ],
        decoration: const InputDecoration(hintText: 'e.g. 7.25'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final hours =
                double.tryParse(controller.text.trim().replaceAll(',', '.'));
            if (hours == null || hours <= 0 || hours > 24) return;
            Navigator.pop(context, {'night': today(), 'hours': double.parse(hours.toStringAsFixed(2))});
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
