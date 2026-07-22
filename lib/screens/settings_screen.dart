import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../reminders.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/page_body.dart';

/// Units, appearance, daily reminder, backup/restore, and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _defaultReminderTime = TimeOfDay(hour: 18, minute: 0);

  Future<void> _scheduleReminder(AppLocalizations l10n, TimeOfDay time) =>
      ReminderService.instance.scheduleDaily(
        time,
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBody,
        channelName: l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
      );

  Future<void> _toggleReminder(BuildContext context, bool on) async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!on) {
      await ReminderService.instance.cancel();
      await store.setReminderTime(null);
      return;
    }
    final granted = await ReminderService.instance.requestPermission();
    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.reminderPermissionDenied)),
      );
      return;
    }
    await store.setReminderTime(_defaultReminderTime);
    await _scheduleReminder(l10n, _defaultReminderTime);
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: store.reminderTime ?? _defaultReminderTime,
    );
    if (picked == null) return;
    await store.setReminderTime(picked);
    await _scheduleReminder(l10n, picked);
  }

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: StoreScope.of(context).exportData()),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.exportDone)));
  }

  /// Hands the backup to the platform share sheet as a JSON file, so it can
  /// be saved to Files, a drive, or sent to another device.
  Future<void> _shareBackupFile(BuildContext context) async {
    final backup = StoreScope.of(context).exportData();
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(utf8.encode(backup), mimeType: 'application/json'),
        ],
        fileNameOverrides: const ['sweatline-backup.json'],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.importConfirmTitle,
      body: l10n.importConfirmBody,
      primaryLabel: l10n.restore,
      secondaryLabel: l10n.cancel,
    );
    if (!confirmed) return;
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
            Text(l10n.settingsReminder, style: textTheme.titleMedium),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reminderSwitchLabel),
              subtitle: Text(l10n.reminderSwitchHint),
              value: store.reminderTime != null,
              onChanged: (on) => _toggleReminder(context, on),
            ),
            if (store.reminderTime != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(l10n.reminderTimeLabel),
                trailing: Text(
                  store.reminderTime!.format(context),
                  style: textTheme.titleLarge,
                ),
                onTap: () => _pickReminderTime(context),
              ),
            const SizedBox(height: 24),
            Text(l10n.settingsBackup, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _shareBackupFile(context),
              icon: Icon(Icons.adaptive.share),
              label: Text(l10n.exportFileButton),
            ),
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
            const SizedBox(height: 4),
            Text(l10n.healthDisclaimer, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
