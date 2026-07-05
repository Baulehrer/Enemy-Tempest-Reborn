import 'dart:io';
import 'dart:ui' show Size;

import 'package:enemy_tempest_reborn_launcher/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show Image;

void main() {
  setUp(() {
    final settings = File(
      '${Platform.environment['HOME']}/.local/share/enemy-tempest-reborn/settings.json',
    );
    if (settings.existsSync()) settings.deleteSync();
  });

  testWidgets('launcher renders game choices', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(const TempestRebornLauncher());

    expect(find.text('ENEMY 1'), findsAtLeastNWidgets(1));
    expect(find.text('ENEMY: TEMPEST REBORN'), findsOneWidget);
    expect(find.text('CARTOGRAPHER'), findsAtLeastNWidgets(1));
    expect(find.text('Enemy 1'), findsNothing);
    expect(find.text('ENEMY 2'), findsAtLeastNWidgets(1));
    expect(find.text('INTRO'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('SPIEL STARTEN'), findsOneWidget);
    expect(find.text('KNOWN GOOD'), findsNothing);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Retro'), findsOneWidget);
    expect(find.text('Retro Plus'), findsOneWidget);
    expect(find.text('Enhanced'), findsOneWidget);
    expect(find.text('Enhanced Plus'), findsOneWidget);
    expect(find.text('crt-hyllian'), findsOneWidget);
    expect(find.text('crt-lottes'), findsOneWidget);
    expect(find.text('scalefx'), findsOneWidget);
    expect(find.text('scale4xhq'), findsOneWidget);

    await tester.tap(find.text('ABOUT'));
    await tester.pumpAndSettle();

    expect(find.text('INFO'), findsOneWidget);
    expect(find.text('Enemy: Tempest Reborn'), findsOneWidget);
    expect(find.text('0.7.1'), findsOneWidget);
    expect(find.byType(Image), findsAtLeastNWidgets(1));
  });
}
