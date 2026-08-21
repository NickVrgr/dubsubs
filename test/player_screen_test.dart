import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:dubsubs/models/subtitle_document.dart';
import 'package:dubsubs/screens/player_screen.dart';
import 'package:dubsubs/services/settings_controller.dart';
import 'package:dubsubs/services/storage_service.dart';

void main() {
  late Directory hiveDir;
  late StorageService storage;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('dubsubs_test_hive');
    Hive.init(hiveDir.path);
    storage = StorageService();
    await storage.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
  });

  final doc = SubtitleDocument(
    id: 'test-doc',
    name: 'Test Movie',
    importedAt: DateTime(2024, 1, 1),
    rawSrtText: '''
1
00:00:01,000 --> 00:00:04,000
Bienvenido al cine.

2
00:00:05,000 --> 00:00:08,000
This is a test subtitle line.

3
00:00:09,000 --> 00:00:12,000
DubSubs is working offline.
''',
  );

  Future<void> pumpPlayer(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsController(storage),
        child: MaterialApp(home: PlayerScreen(document: doc)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows transport controls and no active line before playback starts',
      (tester) async {
    await pumpPlayer(tester);

    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    expect(find.byIcon(Icons.replay_10), findsOneWidget);
    expect(find.byIcon(Icons.forward_10), findsOneWidget);
    expect(find.text('Tap line to sync'), findsOneWidget);
    expect(find.text('Sync assist off'), findsOneWidget);

    // Position starts at zero, before the first cue (which starts at 1s).
    expect(find.text('Bienvenido al cine.'), findsNothing);
  });

  testWidgets('tap-to-sync snaps the subtitle display to the chosen line', (tester) async {
    await pumpPlayer(tester);

    await tester.tap(find.text('Tap line to sync'));
    await tester.pumpAndSettle();

    expect(find.text('This is a test subtitle line.'), findsOneWidget);

    await tester.tap(find.text('This is a test subtitle line.'));
    await tester.pumpAndSettle();

    expect(find.text('This is a test subtitle line.'), findsOneWidget);
    expect(find.text('Bienvenido al cine.'), findsNothing);
  });

  testWidgets('play/pause toggles the transport icon', (tester) async {
    await pumpPlayer(tester);

    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pump();

    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_circle_filled));
    await tester.pump();
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
  });

  testWidgets('an unparseable file shows an error instead of crashing', (tester) async {
    final badDoc = SubtitleDocument(
      id: 'bad-doc',
      name: 'Broken',
      importedAt: DateTime(2024, 1, 1),
      rawSrtText: 'not a subtitle file',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsController(storage),
        child: MaterialApp(home: PlayerScreen(document: badDoc)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not read this subtitle file'), findsOneWidget);
  });
}
