import 'dart:io';
import 'dart:ui';

import 'package:enemy_tempest_reborn_launcher/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    final settings = File('../work/launcher-runtime/settings.json');
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

    await tester.tap(find.text('ABOUT'));
    await tester.pumpAndSettle();

    expect(find.text('INFO'), findsOneWidget);
    expect(find.text('Enemy: Tempest Reborn'), findsOneWidget);
    expect(find.text('0.2.0-dev'), findsOneWidget);
  });
}
