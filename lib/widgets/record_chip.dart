import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Loud volt pill marking a personal record. Full-strength primary is
/// reserved for exactly this moment, so it reads as the app's biggest
/// celebration wherever it appears.
class RecordChip extends StatelessWidget {
  const RecordChip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 13, color: scheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            l10n.newRecord.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
