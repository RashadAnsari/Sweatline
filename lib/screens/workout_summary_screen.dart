import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../exercise_library.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/page_body.dart';
import '../widgets/record_chip.dart';
import '../widgets/stat_tile.dart';

/// Post-workout celebration: duration, total volume, sets, and the best
/// set per exercise. Replaces the workout screen when a session is saved.
/// The whole card can be shared as an image via the platform share sheet.
class WorkoutSummaryScreen extends StatefulWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    required this.duration,
  });

  final WorkoutSession session;
  final Duration duration;

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  /// Marks the shareable content; the capture renders everything inside it,
  /// including parts scrolled out of view.
  final _boundaryKey = GlobalKey();

  /// A record when this session's best beats every session before it.
  /// First-ever attempts are not records: there is nothing to beat.
  bool _isRecord(AppStore store, ExerciseLog log) {
    if (log.sets.isEmpty) return false;
    final best = store.bestWeightFor(
      log.exerciseId,
      before: widget.session.date,
    );
    return best != null && log.bestWeight > best;
  }

  /// Renders the summary to a PNG and hands it to the platform share sheet.
  /// A capture failure must never crash the celebration screen.
  Future<void> _share() async {
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png'),
          ],
          fileNameOverrides: const ['sweatline-workout.png'],
        ),
      );
    } catch (error) {
      debugPrint('Sweatline: sharing the summary failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final unit = unitLabel(l10n, store.unit);
    final session = widget.session;

    final setCount = session.logs.fold(0, (sum, log) => sum + log.sets.length);
    final volumeKg = session.logs.fold(
      0.0,
      (sum, log) =>
          sum + log.sets.fold(0.0, (s, set) => s + set.weightKg * set.reps),
    );
    final minutes = widget.duration.inMinutes.clamp(1, 24 * 60);

    return Scaffold(
      body: PageBody(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 8),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 56,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.workoutCompleteTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall!.copyWith(
                              color: colorScheme.primary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayLabel(l10n, session.dayKey),
                            style: textTheme.titleMedium!.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatTile(
                            label: l10n.statDuration,
                            value: l10n.minutesValue(minutes),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatTile(
                            label: l10n.statVolume,
                            value: l10n.weightWithUnit(
                              formatKgIn(store.unit, volumeKg),
                              unit,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatTile(
                            label: l10n.statSetsLogged,
                            value: '$setCount',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final log in session.logs)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _isRecord(store, log)
                            ? Icons.emoji_events
                            : Icons.check_circle,
                        color: colorScheme.primary,
                      ),
                      title: _isRecord(store, log)
                          ? Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    exerciseById(log.exerciseId).name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const RecordChip(),
                              ],
                            )
                          : Text(exerciseById(log.exerciseId).name),
                      subtitle: Text(l10n.setsCount(log.sets.length)),
                      trailing: Text(
                        l10n.setResult(
                          formatKgIn(store.unit, log.bestWeight),
                          unit,
                          log.sets
                              .reduce(
                                (a, b) => a.weightKg >= b.weightKg ? a : b,
                              )
                              .reps,
                        ),
                        style: textTheme.titleLarge,
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Wordmark so a shared image says where it came from.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        l10n.appTitle.toUpperCase(),
                        style: textTheme.titleLarge!.copyWith(
                          fontSize: 16,
                          letterSpacing: 3,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PageBody(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _share,
                  icon: Icon(Icons.adaptive.share),
                  label: Text(l10n.shareButton),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.doneButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
