# Privacy Policy

Last updated: 22 July 2026

Sweatline is a personal training app for iPhone and Android. This policy explains
what the app does with your information. The short version: it does not send
anything anywhere.

## What we collect

Nothing. Sweatline has no account system, no analytics, no advertising, no
crash reporting, and no backend server. The developer cannot see your data and
receives no information about you or your device.

## What stays on your device

Everything you enter or generate in the app is stored in a local SQLite
database inside the app's private storage:

- Your training plan and the answers you gave to the setup questions
  (goal, experience level, days per week).
- Your workout history: exercises, sets, reps, and weights.
- Body weight entries you log, and the notes you write on an exercise.
- An auto-saved draft of any workout in progress.
- Your settings: weight unit (kg or lb), theme choice, and the time of your
  daily reminder if you turned one on.

This data never leaves the device. The app requests no network permission in
its release build, so it cannot transmit data even if it tried.

## Sharing

Two screens can hand something to your device's share sheet: the workout
summary as an image, and your backup as a file. Nothing is shared until you ask
for it, and Sweatline plays no part in where it goes. The app you pick in the
share sheet, including Photos if you choose "Save Image", receives the file
under its own privacy policy.

## Backup and restore

Settings contains an "Export" action that copies your data to the device
clipboard as text, a "Share backup" action that hands the same data to the
share sheet as a JSON file, and an "Import" action that reads the clipboard
copy back. What you do with the exported data is entirely up to you. Sweatline
does not upload it.

Your device's operating system may include the app's data in the backups it
already makes (Google One backup on Android, iCloud or encrypted local backup
on iOS). Those backups are handled by Google and Apple under their own privacy
policies, not by Sweatline.

## Permissions

Sweatline keeps the screen awake while a workout is running and uses haptic
feedback for the rest timer.

If you switch on the daily reminder, the app asks for permission to send
notifications and reads your device's time zone so the reminder fires at the
hour you picked. The reminder is scheduled by the operating system on the
device; no server is involved, and no reminder or time zone information leaves
the phone. Turning the reminder off cancels it.

On iOS the app declares permission to add an image to your photo library, which
the system requires because "Save Image" is one of the options in the share
sheet. Sweatline never reads your photos.

Beyond that it requests no runtime permissions, no location, no camera, no
contacts, no health data, and no internet access.

## Children

Sweatline is not directed at children under 13. It collects no data from anyone
of any age.

## Deleting your data

Uninstalling the app removes its database and every trace of your data from the
device. There is nothing else to delete, because nothing is stored anywhere
else.

## Changes to this policy

If this policy changes, the updated version will be published at this address
and the "Last updated" date above will change.
