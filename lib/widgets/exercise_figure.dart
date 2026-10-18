import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Exercise demonstration from the bundled Gym visual media: the animation
/// with its required copyright line, or the still thumbnail when [animate]
/// is false (lists, where a screen of moving GIFs would be noise).
/// Exercises without media show an icon.
class ExerciseFigure extends StatelessWidget {
  const ExerciseFigure({
    super.key,
    required this.media,
    this.height = 140,
    this.animate = true,
  });

  final String? media;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final media = this.media;
    final theme = Theme.of(context);
    if (media == null) {
      return SizedBox(
        height: height,
        child: Icon(
          Icons.fitness_center,
          size: height / 2,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (!animate) {
      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/exercises/thumbs/$media.jpg'),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/exercises/$media.gif'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.mediaAttribution,
            style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
