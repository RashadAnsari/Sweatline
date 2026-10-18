"""Generates lib/exercise_data.dart and assets/exercises/ from a checkout of
https://github.com/hasaneyldrm/exercises-dataset.

Usage: python3 tools/import_exercises.py <path-to-exercises-dataset>

The dataset text is MIT licensed. The media is (c) Gym visual and is bundled
under Sweatline's own license from Gym visual, so it must keep its
attribution (the mediaAttribution ARB string). Dataset values are mapped
onto the app's stable keys here; an unknown value fails the run instead of
leaking a raw key into the UI.
"""

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

GROUPS = {
    'chest': 'chest',
    'back': 'back',
    'neck': 'back',
    'shoulders': 'shoulders',
    'upper arms': 'arms',
    'lower arms': 'arms',
    'upper legs': 'legs',
    'lower legs': 'legs',
    'waist': 'core',
    'cardio': 'cardio',
}

EQUIPMENT = {
    'barbell': 'barbell',
    'olympic barbell': 'barbell',
    'trap bar': 'barbell',
    'ez barbell': 'ezBar',
    'smith machine': 'smithMachine',
    'dumbbell': 'dumbbell',
    'kettlebell': 'kettlebell',
    'cable': 'cable',
    'band': 'band',
    'resistance band': 'band',
    'body weight': 'bodyweight',
    'weighted': 'bodyweight',
    'assisted': 'bodyweight',
    'leverage machine': 'machine',
    'sled machine': 'machine',
    'stationary bike': 'machine',
    'elliptical machine': 'machine',
    'stepmill machine': 'machine',
    'skierg machine': 'machine',
    'upper body ergometer': 'machine',
    'stability ball': 'ball',
    'medicine ball': 'ball',
    'bosu ball': 'ball',
    'rope': 'other',
    'roller': 'other',
    'wheel roller': 'other',
    'hammer': 'other',
    'tire': 'other',
}

# Dataset muscle names onto the muscle diagram keys. None means the diagram
# has no region for it, so it is dropped.
MUSCLES = {
    'abs': 'abs',
    'abdominals': 'abs',
    'lower abs': 'abs',
    'core': 'abs',
    'obliques': 'obliques',
    'pectorals': 'chest',
    'chest': 'chest',
    'upper chest': 'chest',
    'serratus anterior': 'chest',
    'delts': 'shoulders',
    'deltoids': 'shoulders',
    'rear deltoids': 'shoulders',
    'shoulders': 'shoulders',
    'rotator cuff': 'shoulders',
    'biceps': 'biceps',
    'brachialis': 'biceps',
    'triceps': 'triceps',
    'forearms': 'forearms',
    'wrists': 'forearms',
    'wrist flexors': 'forearms',
    'wrist extensors': 'forearms',
    'grip muscles': 'forearms',
    'hands': 'forearms',
    'lats': 'lats',
    'latissimus dorsi': 'lats',
    'upper back': 'upperBack',
    'back': 'upperBack',
    'rhomboids': 'upperBack',
    'spine': 'lowerBack',
    'lower back': 'lowerBack',
    'traps': 'traps',
    'trapezius': 'traps',
    'levator scapulae': 'traps',
    'sternocleidomastoid': 'traps',
    'quads': 'quads',
    'quadriceps': 'quads',
    'adductors': 'quads',
    'inner thighs': 'quads',
    'groin': 'quads',
    'hamstrings': 'hamstrings',
    'glutes': 'glutes',
    'abductors': 'glutes',
    'calves': 'calves',
    'soleus': 'calves',
    'cardiovascular system': None,
    'hip flexors': None,
    'ankles': None,
    'ankle stabilizers': None,
    'feet': None,
    'shins': None,
}

COMPOUND = re.compile(
    r'press|squat|deadlift|\brow\b|pull-?up|chin-?up|pulldown|\bdips?\b|lunge|'
    r'clean|snatch|thruster|push-?up|push up|step-?up|burpee|good morning|'
    r'swing|jerk|muscle up|glute bridge|hip thrust'
)
ISOLATION = re.compile(
    r'curl|raise|fly|extension|kickback|crunch|shrug|stretch|calf|upright row|'
    r'straight arm|rear delt'
)
TIMED = re.compile(r'stretch|plank|\bhold\b|\bpose\b|isometric|wall sit')

WORD_CASE = {'ez': 'EZ', 'jm': 'JM', 'v.': 'v.'}


def title(name):
    name = name.replace('в°', '°')
    words = []
    for word in name.split(' '):
        if word in WORD_CASE:
            words.append(WORD_CASE[word])
        else:
            # Capitalize each hyphen part and after an opening bracket.
            words.append(
                '-'.join(p[:1].upper() + p[1:] for p in word.split('-'))
                if not word.startswith('(')
                else '(' + word[1:2].upper() + word[2:]
            )
    return ' '.join(words)


def muscles(names, source_id):
    keys = []
    for name in names:
        if name not in MUSCLES:
            sys.exit(f'{source_id}: unknown muscle "{name}", add it to MUSCLES')
        key = MUSCLES[name]
        if key and key not in keys:
            keys.append(key)
    return keys


def dart_string(text):
    # JSON string escaping is valid Dart once `$` is escaped too. Dashes are
    # banned from copy (AGENTS.md), so they become commas.
    text = re.sub(r'\s*[–—]\s*', ', ', text)
    return json.dumps(text, ensure_ascii=False).replace('$', r'\$')


def dart_list(items):
    return '[' + ', '.join(dart_string(i) for i in items) + ']'


def convert(record):
    rid = record['id']
    name = record['name']
    group = GROUPS[record['body_part']]
    primary = muscles([record['target']], rid)
    secondary = [m for m in muscles(record['secondary_muscles'], rid) if m not in primary]
    if not primary:
        # Cardio targets the heart, which the diagram cannot show, so the
        # working muscles become the primary ones.
        primary, secondary = secondary, []
    if not primary:
        sys.exit(f'{rid}: no muscle maps onto the diagram')
    steps = [
        s for s in record['instruction_steps']['en']
        if not s.startswith('Repeat for the desired number')
    ]
    timed = bool(TIMED.search(name)) or (group == 'cardio' and 'burpee' not in name)
    compound = (
        not timed and bool(COMPOUND.search(name)) and not ISOLATION.search(name)
    )
    fields = [
        f"id: '{rid}'",
        f'name: {dart_string(title(name))}',
        f"group: '{group}'",
        f"equipment: '{EQUIPMENT[record['equipment']]}'",
        f"media: '{rid}'",
        f'primaryMuscles: {dart_list(primary)}',
    ]
    if secondary:
        fields.append(f'secondaryMuscles: {dart_list(secondary)}')
    fields.append(f'steps: {dart_list(steps)}')
    if compound:
        fields.append('isCompound: true')
    if timed:
        fields.append('isTimed: true')
    return '  Exercise(' + ', '.join(fields) + ',),'


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    dataset = Path(sys.argv[1])
    records = json.loads((dataset / 'data' / 'exercises.json').read_text())

    body = '\n'.join(convert(r) for r in records)
    (ROOT / 'lib' / 'exercise_data.dart').write_text(
        '// GENERATED by tools/import_exercises.py from\n'
        '// https://github.com/hasaneyldrm/exercises-dataset. Do not edit.\n'
        '// Exercise text: MIT, Copyright (c) 2026 Hasan Emir Yildirim.\n\n'
        "import 'models.dart';\n\n"
        f'const List<Exercise> datasetExercises = [\n{body}\n];\n'
    )

    subprocess.run(['dart', 'format', 'lib/exercise_data.dart'], cwd=ROOT, check=True)

    gifs = ROOT / 'assets' / 'exercises'
    thumbs = gifs / 'thumbs'
    shutil.rmtree(gifs, ignore_errors=True)
    thumbs.mkdir(parents=True)
    for r in records:
        shutil.copy(dataset / r['gif_url'], gifs / f"{r['id']}.gif")
        shutil.copy(dataset / r['image'], thumbs / f"{r['id']}.jpg")
    print(f'{len(records)} exercises written')


if __name__ == '__main__':
    main()
