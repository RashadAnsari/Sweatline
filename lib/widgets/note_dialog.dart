import 'package:flutter/material.dart';

/// Text-input dialog in the app's stacked full-width button style.
///
/// Returns the entered text when saved (blank text means "remove"), or null
/// when cancelled or dismissed.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  required String initialText,
  required String hint,
  required String saveLabel,
  required String cancelLabel,
}) {
  final controller = TextEditingController(text: initialText);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(saveLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    ),
  );
}
