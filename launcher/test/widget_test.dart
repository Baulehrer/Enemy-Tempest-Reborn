import 'dart:io';

import 'package:enemy_tempest_reborn_launcher/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const app = TempestRebornLauncher(
    userDataPath: '/tmp/enemy-tempest-reborn-widget-tests',
  );

  setUp(() {
    final settings = File(
      '/tmp/enemy-tempest-reborn-widget-tests/settings.json',
    );
    if (settings.existsSync()) settings.deleteSync();
  });

  testWidgets('launcher keeps the primary path simple', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('ENEMY 1'), findsAtLeastNWidgets(1));
    expect(find.text('ENEMY 2'), findsOneWidget);
    expect(find.text('INTRO'), findsOneWidget);
    expect(find.text('SPIEL STARTEN'), findsOneWidget);
    expect(find.text('EINSTELLUNGEN'), findsOneWidget);
    expect(find.byTooltip('Levelkarten'), findsOneWidget);
    expect(find.byTooltip('Info'), findsOneWidget);

    final introTop = tester.getTopLeft(
      find.widgetWithText(OutlinedButton, 'INTRO'),
    );
    final enemyTwoTop = tester.getTopLeft(
      find.widgetWithText(OutlinedButton, 'ENEMY 2'),
    );
    expect(introTop.dy, lessThan(enemyTwoTop.dy));

    expect(find.text('crt-hyllian'), findsNothing);
    expect(find.text('scale4xhq'), findsNothing);
    expect(find.text('BILDSCHIRM').hitTestable(), findsNothing);
  });

  testWidgets('settings expand and use novice-friendly labels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('EINSTELLUNGEN'));
    await tester.pumpAndSettle();

    expect(find.text('BILDSCHIRM'), findsOneWidget);
    expect(find.text('BILDFORMAT'), findsOneWidget);
    expect(find.text('GRAFIK'), findsOneWidget);
    expect(find.text('STEUERUNG'), findsOneWidget);
    expect(find.text('Vollbild'), findsAtLeastNWidgets(1));
    expect(find.text('Pixelgenau'), findsOneWidget);
    expect(find.text('Verbessert'), findsOneWidget);
    expect(find.text('Tastatur'), findsAtLeastNWidgets(1));
  });

  testWidgets('language switch updates the complete primary interface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.byTooltip('Level maps'), findsOneWidget);
    expect(find.byTooltip('About'), findsOneWidget);
  });

  testWidgets('about remains available with release information', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Info'));
    await tester.pumpAndSettle();

    expect(find.text('ENEMY: TEMPEST REBORN'), findsAtLeastNWidgets(1));
    expect(find.text('V0.8'), findsOneWidget);
    expect(find.text('André Wüthrich'), findsOneWidget);
    expect(find.text('Stephan Kaufmann'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/launch-splash-boxart.jpeg' &&
            widget.fit == BoxFit.contain,
      ),
      findsOneWidget,
    );
  });

  for (final size in const [
    Size(1600, 900),
    Size(1024, 768),
    Size(720, 900),
    Size(480, 800),
  ]) {
    testWidgets(
      'layout has no overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        expect(find.text('ENEMY 1'), findsAtLeastNWidgets(1));
        expect(find.text('SPIEL STARTEN'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
