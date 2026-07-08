import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/page_body.dart';

/// Units, appearance, backup/restore, and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: StoreScope.of(context).exportData()),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.exportDone)));
  }

  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    try {
      await store.importData(clipboard?.text ?? '');
      messenger.showSnackBar(SnackBar(content: Text(l10n.importDone)));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.settingsUnits, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<WeightUnit>(
              segments: [
                for (final unit in WeightUnit.values)
                  ButtonSegment(
                    value: unit,
                    label: Text(unitLabel(l10n, unit)),
                  ),
              ],
              selected: {store.unit},
              onSelectionChanged: (selection) => store.setUnit(selection.first),
            ),
            const SizedBox(height: 24),
            Text(l10n.settingsAppearance, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {store.themeMode},
              onSelectionChanged: (selection) =>
                  store.setThemeMode(selection.first),
            ),
            const SizedBox(height: 24),
            Text(l10n.settingsBackup, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _export(context),
              icon: const Icon(Icons.copy),
              label: Text(l10n.exportButton),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _import(context),
              icon: const Icon(Icons.download),
              label: Text(l10n.importButton),
            ),
            const SizedBox(height: 24),
            Text(l10n.settingsAbout, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) => Text(
                l10n.versionLabel(snapshot.data?.version ?? '…'),
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.privacyNote, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
