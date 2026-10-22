import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'log_screen.dart';

Widget dietScreen() => LogScreen(
      title: 'Diet',
      table: 'meals',
      addLabel: 'Log meal',
      formBuilder: (context) => showDialog<Map<String, Object?>>(
        context: context,
        builder: (context) => const _MealDialog(),
      ),
      describe: (row) {
        final description = row['description'] as String? ?? '';
        final calories = row['calories'];
        final photo = row['photo'] as String?;
        return LogRow(
          title: description.isEmpty ? 'Meal photo' : description,
          subtitle: calories == null
              ? '${row['logged_at']}'
              : '${row['logged_at']} · $calories kcal',
          leading: photo == null
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(photo),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
        );
      },
    );

class _MealDialog extends StatefulWidget {
  const _MealDialog();

  @override
  State<_MealDialog> createState() => _MealDialogState();
}

class _MealDialogState extends State<_MealDialog> {
  final _description = TextEditingController();
  final _calories = TextEditingController();
  Uint8List? _photo;

  Future<void> _pick(ImageSource source) async {
    // Small, compressed photos so they fit comfortably in browser storage.
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 60,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photo = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _description,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What did you eat?',
                hintText: 'e.g. chicken rice, no soup',
                alignLabelWithHint: true,
              ),
            ),
            TextField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Calories (optional)'),
            ),
            const SizedBox(height: 12),
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_photo!, height: 120, fit: BoxFit.cover),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Take photo'),
                ),
                TextButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose photo'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final description = _description.text.trim();
            if (description.isEmpty && _photo == null) return;
            final calories = int.tryParse(_calories.text.trim());
            Navigator.pop(context, {
              'logged_at': today(),
              'description': description,
              'calories': calories,
              'photo': _photo == null ? null : base64Encode(_photo!),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
