import 'dart:io';
import 'dart:ui' as ui;
import 'package:daruma_kanji/components/daruma/daruma_3d_painter.dart';
import 'package:daruma_kanji/components/daruma/daruma_wobble_view.dart';
import 'package:daruma_kanji/components/daruma/daruma_orbit_painter.dart';
import 'package:daruma_kanji/main.dart';
import 'package:daruma_kanji/models/daruma_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const capture = bool.fromEnvironment('CAPTURE_DARUMA_PREVIEWS');

Future<void> savePreview(WidgetTester tester, Key key, String name) async {
  if (!capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/design-preview')
      ..createSync(recursive: true);
    File('${directory.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final entry in {
      'DarumaSans': ['Roboto-Regular.ttf', 'Roboto-Bold.ttf'],
      'DarumaMincho': ['ShipporiMincho-ExtraBold.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
  });

  for (final scenario in [
    (size: const Size(320, 700), scale: 1.0),
    (size: const Size(375, 812), scale: 1.0),
    (size: const Size(430, 932), scale: 1.0),
    (size: const Size(320, 700), scale: 2.0),
    (size: const Size(375, 812), scale: 3.0),
    (size: const Size(812, 375), scale: 1.0),
    (size: const Size(1024, 768), scale: 1.0),
  ]) {
    testWidgets('Home fits ${scenario.size} at text scale ${scenario.scale}',
        (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const key = ValueKey('home-preview');
      await tester
          .pumpWidget(const RepaintBoundary(key: key, child: DarumaKanjiApp()));
      await tester.pumpAndSettle();
      expect(find.text("DARUMA'S VOW"), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (scenario.size.width == 375 && scenario.scale == 1) {
        await savePreview(tester, key, 'home-375');
      }
      await tester.ensureVisible(find.text('Ôn luyện Kanji'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Avatar owns vertical drags while the page scrolls from the gutter',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const DarumaKanjiApp());
    DarumaOrbitPainter? painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<DarumaOrbitPainter>()
        .firstOrNull;
    for (var i = 0; i < 100 && painter() == null; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(painter(), isNotNull);
    final before = painter()!.camera.pitch;
    final scrolling =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    final scrollBefore = scrolling.position.pixels;
    final drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('daruma-orbit-gesture'))));
    for (var i = 0; i < 12; i++) {
      await drag.moveBy(const Offset(0, -8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect((painter()!.camera.pitch - before).abs(), greaterThan(0.15));
    expect(scrolling.position.pixels, closeTo(scrollBefore, 0.001));
    await tester.dragFrom(const Offset(8, 400), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(scrolling.position.pixels, greaterThan(scrollBefore + 20));
  });

  testWidgets('Eye rituals render independently and repaint a mutable model',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    const key = ValueKey('doll-preview');
    Future<void> paintDoll(String name) async {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: RepaintBoundary(
        key: key,
        child: SizedBox(
            width: 400,
            height: 440,
            child: CustomPaint(
                painter: Daruma3dPainter(daruma: doll, tiltAngle: 0))),
      ))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await savePreview(tester, key, name);
    }

    Future<int> pupilPixel(double x) async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = (await image.toByteData())!;
        final red = data.getUint8((150 * image.width + x.toInt()) * 4);
        image.dispose();
        return red;
      }))!;
    }

    doll.hasLeftEye = false;
    await paintDoll('daruma-blank');
    expect(await pupilPixel(150), greaterThan(200));
    expect(await pupilPixel(250), greaterThan(200));
    doll.hasLeftEye = true;
    await paintDoll('daruma-vow');
    expect(await pupilPixel(150), greaterThan(200));
    expect(await pupilPixel(250), lessThan(60));
    doll.hasRightEye = true;
    await paintDoll('daruma-complete');
    expect(await pupilPixel(150), lessThan(60));
    expect(await pupilPixel(250), lessThan(60));
  });

  testWidgets('Reduced motion keeps Daruma still after a tap', (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: DarumaWobbleView(daruma: doll),
    )));
    await tester.tap(find.byType(DarumaWobbleView));
    await tester.pump(const Duration(milliseconds: 100));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<Daruma3dPainter>()
        .single;
    expect(painter.tiltAngle, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
