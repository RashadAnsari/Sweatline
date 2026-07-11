import 'package:flutter/material.dart';

/// A confirmation dialog with stacked, full-width actions: [primaryLabel] is the
/// emphasized button on top and [secondaryLabel] the outlined button below.
///
/// Returns true when the primary action is chosen and false when the secondary
/// action is chosen or the dialog is dismissed, so [primaryLabel] must always
/// be the action the user is opting into (dismissing stays safe). Set
/// [destructive] to tint the primary button with the error color.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String primaryLabel,
  required String secondaryLabel,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(body),
            const SizedBox(height: 24),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(primaryLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(secondaryLabel),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
