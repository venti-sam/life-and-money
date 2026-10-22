import 'package:flutter/material.dart';

import 'log_screen.dart';

const workoutTypes = ['Running', 'Gym', 'Tennis'];

Widget workoutsScreen() => LogScreen(
      title: 'Workouts',
      table: 'workouts',
      addLabel: 'Log workout',
      formBuilder: (context) => showDialog<Map<String, Object?>>(
        context: context,
        builder: (context) => const _WorkoutDialog(),
      ),
      describe: (row) {
        final notes = row['notes'] as String? ?? '';
        return (
          title: '${row['type']}, ${row['duration_minutes']} min',
          subtitle: notes.isEmpty ? '${row['logged_at']}' : '${row['logged_at']} · $notes',
        );
      },
    );

class _WorkoutDialog extends StatefulWidget {
  const _WorkoutDialog();

  @override
  State<_WorkoutDialog> createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<_WorkoutDialog> {
  String _type = workoutTypes.first;
  final _minutes = TextEditingController();
  final _notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log workout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: [
              for (final t in workoutTypes)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minutes'),
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
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
            final minutes = int.tryParse(_minutes.text.trim());
            if (minutes == null || minutes <= 0) return;
            Navigator.pop(context, {
              'logged_at': today(),
              'type': _type,
              'duration_minutes': minutes,
              'notes': _notes.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
