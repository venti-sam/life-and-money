import 'package:flutter/material.dart';

import 'log_screen.dart';

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
        decoration: const InputDecoration(hintText: 'e.g. 7.5'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final hours = double.tryParse(controller.text.trim());
            if (hours == null || hours <= 0 || hours > 24) return;
            Navigator.pop(context, {'night': today(), 'hours': hours});
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
