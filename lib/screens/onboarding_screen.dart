import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models.dart';
import '../plan_generator.dart';
import '../widgets/page_body.dart';

/// Three-question quiz the trainer uses to build the weekly plan.
/// Shown at first launch and when the user asks for a new plan.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Goal _goal = Goal.buildMuscle;
  Level _level = Level.beginner;
  int _daysPerWeek = 3;

  Plan get _preview =>
      generatePlan(goal: _goal, level: _level, daysPerWeek: _daysPerWeek);

  Future<void> _buildPlan() async {
    final store = StoreScope.of(context);
    final navigator = Navigator.of(context);
    await store.setPlan(_preview);
    // When opened from the Plan tab this screen is pushed; at first launch it
    // is the root and the app root swaps to HomeScreen on its own.
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _preview;

    return Scaffold(
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 4),
                child: Text(
                  l10n.appTitle.toUpperCase(),
                  style: textTheme.displayMedium!.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            Text(l10n.onboardingIntro, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(l10n.goalQuestion, style: textTheme.titleLarge),
            const SizedBox(height: 10),
            _OptionCard(
              icon: Icons.fitness_center,
              title: l10n.goalBuildMuscle,
              subtitle: l10n.goalBuildMuscleDesc,
              selected: _goal == Goal.buildMuscle,
              onTap: () => setState(() => _goal = Goal.buildMuscle),
            ),
            _OptionCard(
              icon: Icons.local_fire_department,
              title: l10n.goalLoseWeight,
              subtitle: l10n.goalLoseWeightDesc,
              selected: _goal == Goal.loseWeight,
              onTap: () => setState(() => _goal = Goal.loseWeight),
            ),
            _OptionCard(
              icon: Icons.favorite,
              title: l10n.goalGetFit,
              subtitle: l10n.goalGetFitDesc,
              selected: _goal == Goal.getFit,
              onTap: () => setState(() => _goal = Goal.getFit),
            ),
            const SizedBox(height: 24),
            Text(l10n.levelQuestion, style: textTheme.titleLarge),
            const SizedBox(height: 10),
            _OptionCard(
              icon: Icons.flag,
              title: l10n.levelBeginner,
              subtitle: l10n.levelBeginnerDesc,
              selected: _level == Level.beginner,
              onTap: () => setState(() => _level = Level.beginner),
            ),
            _OptionCard(
              icon: Icons.trending_up,
              title: l10n.levelIntermediate,
              subtitle: l10n.levelIntermediateDesc,
              selected: _level == Level.intermediate,
              onTap: () => setState(() => _level = Level.intermediate),
            ),
            _OptionCard(
              icon: Icons.bolt,
              title: l10n.levelAdvanced,
              subtitle: l10n.levelAdvancedDesc,
              selected: _level == Level.advanced,
              onTap: () => setState(() => _level = Level.advanced),
            ),
            const SizedBox(height: 24),
            Text(l10n.daysQuestion, style: textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var days = 2; days <= 6; days++)
                  ChoiceChip(
                    label: Text('$days'),
                    labelStyle: textTheme.titleMedium,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    selected: _daysPerWeek == days,
                    onSelected: (_) => setState(() => _daysPerWeek = days),
                  ),
              ],
            ),
            // Advice, not a block: the choice stays the lifter's.
            if (isDemandingFrequency(_level, _daysPerWeek)) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.beginnerFrequencyNote,
                      style: textTheme.bodyMedium!.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PageBody(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.planPreview(
                    _daysPerWeek,
                    estimatedSessionMinutes(preview.days.first),
                  ),
                  style: textTheme.bodyMedium!.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _buildPlan,
                  child: Text(l10n.createPlanButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium!.copyWith(
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall!.copyWith(
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
