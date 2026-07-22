import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/theme.dart';
import 'package:sweatline/widgets/stat_tile.dart';

void main() {
  testWidgets('stat tiles in a stretched row all get the same height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sweatlineDark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(
                    child: StatTile(label: 'Short', value: '3'),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: 'A label long enough to wrap onto two lines',
                      value: '12',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatTile(label: 'Weeks in a row', value: '2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final heights = tester
        .widgetList(find.byType(StatTile))
        .map((widget) => tester.getSize(find.byWidget(widget)).height)
        .toSet();
    expect(heights, hasLength(1));
  });
}
