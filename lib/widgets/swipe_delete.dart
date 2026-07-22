import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'confirm_dialog.dart';

/// Swipe-to-delete for history rows: swipe end-to-start, confirm in the
/// app's standard destructive dialog, then [onDelete] runs. Keeps rows free
/// of per-row delete buttons.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    super.key,
    required this.dismissibleKey,
    required this.confirmTitle,
    required this.confirmBody,
    required this.onDelete,
    required this.child,
  });

  final Key dismissibleKey;
  final String confirmTitle;
  final String confirmBody;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: dismissibleKey,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onError),
      ),
      confirmDismiss: (_) => showConfirmDialog(
        context,
        title: confirmTitle,
        body: confirmBody,
        primaryLabel: l10n.delete,
        secondaryLabel: l10n.cancel,
        destructive: true,
      ),
      onDismissed: (_) => onDelete(),
      child: child,
    );
  }
}
