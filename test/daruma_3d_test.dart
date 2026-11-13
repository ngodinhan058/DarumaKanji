import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:daruma_kanji/components/daruma/daruma_mesh.dart';
import 'package:daruma_kanji/components/daruma/daruma_orbit_painter.dart';
import 'package:daruma_kanji/components/daruma/daruma_orbit_view.dart';
import 'package:daruma_kanji/components/daruma/daruma_surface.dart';
import 'package:daruma_kanji/components/daruma/daruma_push.dart';
import 'package:daruma_kanji/models/daruma_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const capture = bool.fromEnvironment('CAPTURE_DARUMA_PREVIEWS');

Future<Uint8List> render(DarumaSurface surface, double yaw,
    {String? name, bool opaqueBackground = false}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (opaqueBackground) {
    canvas.drawColor(const Color(0xFFF9F6F0), BlendMode.src);
  }
  DarumaOrbitPainter(
          surface: surface, camera: DarumaCamera(yaw: yaw, pitch: 0.12))
      .paint(canvas, const Size(400, 440));
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 440);
  picture.dispose();
  final pixels = (await image.toByteData())!.buffer.asUint8List();
  if (capture && name != null) {
    final folder = Directory('build/design-preview/3d')
      ..createSync(recursive: true);
    File('${folder.path}/$name.png').writeAsBytesSync(
        (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List());
  }
  image.dispose();
  return pixels;
}

Future<void> captureTurntable(DarumaSurface surface) async {
  // Desktop command-recording diagnostics only: excludes device GPU/compositing.
  final durations = <double>[];
  for (var frame = 0; frame < 68; frame++) {
    final recorder = ui.PictureRecorder();
    final watch = Stopwatch()..start();
    DarumaOrbitPainter(
            surface: surface,
            camera: DarumaCamera(yaw: frame * math.pi / 30, pitch: 0.12))
        .paint(Canvas(recorder), const Size(400, 440));
    final picture = recorder.endRecording();
    watch.stop();
    picture.dispose();
    if (frame >= 8) durations.add(watch.elapsedMicroseconds / 1000);
  }
  durations.sort();
  final diagnostics = {
    'environment':
        'Windows Flutter debug test; CPU projection and command recording only',
    'not_measured':
        'iPhone 8, Android device, GPU time, compositor, real-time FPS',
    'vertices': DarumaMesh.standard.vertices.length,
    'triangles': DarumaMesh.standard.indices.length ~/ 3,
    'texture_rgba_bytes': surface.image.width * surface.image.height * 4,
    'samples': durations.length,
    'cpu_mean_ms': durations.reduce((a, b) => a + b) / durations.length,
    'cpu_p95_ms': durations[(durations.length * 0.95).floor()],
  };
  final folder = Directory('build/design-preview/3d')
    ..createSync(recursive: true);
  File('${folder.path}/diagnostics.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(diagnostics));
  for (var frame = 0; frame < 32; frame++) {
    await render(surface, frame * math.pi * 2 / 32,
        name: 'frame-${frame.toString().padLeft(2, '0')}',
        opaqueBackground: true);
  }
}

Future<void> capturePushes(DarumaSurface surface) async {
  final folder = Directory('build/design-preview/push')
    ..createSync(recursive: true);
  const viewport = Size(400, 440);
  final rest = DarumaCamera(pitch: 0.10);
  final scenarios = [
    (label: 'Đẩy bên trái', point: const Offset(112, 185)),
    (label: 'Đẩy bên phải', point: const Offset(288, 185)),
    (label: 'Đẩy giữa mặt', point: const Offset(200, 155)),
  ];
  for (var scenario = 0; scenario < scenarios.length; scenario++) {
    final contact = scenarios[scenario];
    final impulse = DarumaPushImpulse.pick(rest, viewport, contact.point)!;
    final motion = DarumaPushMotion(impulse: impulse);
    for (var frame = 0; frame < 36; frame++) {
      final elapsed = frame / 12;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(const Color(0xFFF9F6F0), BlendMode.src);
      DarumaOrbitPainter(
              surface: surface,
              camera: DarumaCamera(
                  pitch: rest.pitch,
                  roll: motion.rollAt(elapsed),
                  rock: motion.rockAt(elapsed)))
          .paint(canvas, viewport);
      if (frame < 4) {
        canvas.drawCircle(
            contact.point,
            11,
            Paint()
              ..color = const Color(0xFFC7241D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        canvas.drawCircle(
            contact.point, 4, Paint()..color = const Color(0xFFC7241D));
      }
      final label = TextPainter(
          text: TextSpan(
              text: contact.label,
              style: const TextStyle(
                  fontFamily: 'DarumaSans',
                  fontSize: 18,
                  color: Color(0xFF750B0A))),
          textDirection: TextDirection.ltr)
        ..layout();
      label.paint(canvas, Offset((viewport.width - label.width) / 2, 404));
      label.dispose();
      final picture = recorder.endRecording();
      final image = await picture.toImage(400, 440);
      picture.dispose();
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      image.dispose();
      File('${folder.path}/frame-${(scenario * 36 + frame).toString().padLeft(3, '0')}.png')
          .writeAsBytesSync(png);
      if (frame == 3)
        File('${folder.path}/push-$scenario.png').writeAsBytesSync(png);
    }
  }
}

int difference(Uint8List a, Uint8List b) {
  var changed = 0;
  for (var i = 0; i < a.length; i += 4) {
    if ((a[i] - b[i]).abs() +
            (a[i + 1] - b[i + 1]).abs() +
            (a[i + 2] - b[i + 2]).abs() >
        60) {
      changed++;
    }
  }
  return changed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'DarumaSans': 'assets/fonts/Roboto-Regular.ttf',
      'DarumaMincho': 'assets/fonts/ShipporiMincho-ExtraBold.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });

  test('A full 3D orbit exposes different painted front, sides, and back',
      () async {
    final surface =
        await DarumaSurface.create(DarumaModel.defaultLevels().first);
    addTearDown(surface.dispose);
    expect(surface.image.width, 1024);
    final front = await render(surface, 0, name: 'front');
    final side = await render(surface, math.pi / 2, name: 'side');
    final back = await render(surface, math.pi, name: 'back');
    final full = await render(surface, math.pi * 2);
    expect(difference(front, side), greaterThan(2000));
    expect(difference(front, back), greaterThan(2000));
    expect(difference(front, full), lessThan(10));
    for (final pixels in [front, side, back]) {
      var opaque = 0;
      for (var i = 3; i < pixels.length; i += 4) {
        if (pixels[i] > 200) opaque++;
      }
      expect(opaque, greaterThan(20000),
          reason: 'No culling holes or vanished body');
    }
    if (capture) {
      await captureTurntable(surface);
      await capturePushes(surface);
    }
  });

  test('3D surface retains eye rituals and invalidates a mutated model',
      () async {
    final doll = DarumaModel.defaultLevels().first..hasLeftEye = false;
    final blank = await DarumaSurface.create(doll);
    addTearDown(blank.dispose);
    final a = await render(blank, 0);
    doll.hasLeftEye = true;
    expect(blank.matches(doll), isFalse);
    final vow = await DarumaSurface.create(doll);
    addTearDown(vow.dispose);
    final b = await render(vow, 0);
    doll.hasRightEye = true;
    final complete = await DarumaSurface.create(doll);
    addTearDown(complete.dispose);
    final c = await render(complete, 0, name: 'complete');
    expect(difference(a, b), greaterThan(100));
    expect(difference(b, c), greaterThan(100));
    expect(complete.matches(doll), isTrue);
    for (final level in DarumaModel.defaultLevels().skip(1)) {
      expect(complete.matches(level), isFalse);
    }
  });

  DarumaCamera cameraOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<DarumaOrbitPainter>()
      .single
      .camera;

  testWidgets('Dragging changes 3D orientation and reset restores the front',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    final surface = (await tester.runAsync(() => DarumaSurface.create(doll)))!;
    addTearDown(surface.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child:
                DarumaOrbitView(daruma: doll, size: 300, surface: surface))));
    await tester.drag(find.byKey(const ValueKey('daruma-orbit-gesture')),
        const Offset(100, 30));
    await tester.pumpAndSettle();
    expect(cameraOf(tester).yaw.abs(), greaterThan(0.5));
    await tester.tap(find.byTooltip('Mặt trước'));
    await tester.pumpAndSettle();
    expect(cameraOf(tester).yaw, closeTo(0, 0.0001));
    expect(cameraOf(tester).zoom, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
      'Opposite flank taps lean away from the finger with a stronger wobble',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    final surface = (await tester.runAsync(() => DarumaSurface.create(doll)))!;
    addTearDown(surface.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child:
                DarumaOrbitView(daruma: doll, size: 300, surface: surface))));
    final region =
        tester.getRect(find.byKey(const ValueKey('daruma-orbit-gesture')));
    await tester.tapAt(Offset(
        region.left + region.width * 0.28, region.top + region.height * 0.42));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    final leftPush = cameraOf(tester).roll;
    await tester.tap(find.byTooltip('Mặt trước'));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(
        region.left + region.width * 0.72, region.top + region.height * 0.42));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    final rightPush = cameraOf(tester).roll;
    expect(leftPush, lessThan(-0.12),
        reason: 'Left push must tilt right, beyond the old 0.09 rad');
    expect(rightPush, greaterThan(0.12), reason: 'Right push must tilt left');
    await tester.pumpAndSettle();
    expect(cameraOf(tester).roll, closeTo(0, 0.001));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('A center push rocks in depth without changing the chosen orbit',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    final surface = (await tester.runAsync(() => DarumaSurface.create(doll)))!;
    addTearDown(surface.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child:
                DarumaOrbitView(daruma: doll, size: 300, surface: surface))));
    final region = find.byKey(const ValueKey('daruma-orbit-gesture'));
    await tester.drag(region, const Offset(70, 20));
    await tester.pumpAndSettle();
    final before = cameraOf(tester);
    await tester.tapAt(tester.getRect(region).topLeft + const Offset(150, 140));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(cameraOf(tester).rock, lessThan(-0.15));
    expect(cameraOf(tester).yaw, closeTo(before.yaw, 0.000001));
    expect(cameraOf(tester).pitch, closeTo(before.pitch, 0.000001));
    await tester.pumpAndSettle();
    expect(cameraOf(tester).rock, 0);
    expect(cameraOf(tester).roll, 0);
    expect(cameraOf(tester).yaw, closeTo(before.yaw, 0.000001));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
      'Background taps do not push and dragging does not trigger a tap spring',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    final surface = (await tester.runAsync(() => DarumaSurface.create(doll)))!;
    addTearDown(surface.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child:
                DarumaOrbitView(daruma: doll, size: 300, surface: surface))));
    final region = find.byKey(const ValueKey('daruma-orbit-gesture'));
    await tester.tapAt(tester.getRect(region).topLeft + const Offset(3, 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
    expect(cameraOf(tester).roll, 0);
    expect(cameraOf(tester).rock, 0);
    await tester.drag(region, const Offset(80, 20));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cameraOf(tester).yaw.abs(), greaterThan(0.5));
    expect(cameraOf(tester).roll, 0);
    expect(cameraOf(tester).rock, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Reduced motion permits deliberate orbit but skips tap wobble',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    final surface = (await tester.runAsync(() => DarumaSurface.create(doll)))!;
    addTearDown(surface.dispose);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child:
                DarumaOrbitView(daruma: doll, size: 300, surface: surface))));
    await tester.tap(find.byKey(const ValueKey('daruma-orbit-gesture')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cameraOf(tester).roll, 0);
    expect(cameraOf(tester).rock, 0);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.drag(find.byKey(const ValueKey('daruma-orbit-gesture')),
        const Offset(80, 0));
    await tester.pump();
    expect(cameraOf(tester).yaw.abs(), greaterThan(0.4));
  });

  testWidgets('Pinching clamps zoom and a following vertical drag clamps tilt',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    final surface = (await tester.runAsync(() => DarumaSurface.create(doll)))!;
    addTearDown(surface.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child:
                DarumaOrbitView(daruma: doll, size: 300, surface: surface))));
    final center =
        tester.getCenter(find.byKey(const ValueKey('daruma-orbit-gesture')));
    final left =
        await tester.startGesture(center - const Offset(30, 0), pointer: 1);
    final right =
        await tester.startGesture(center + const Offset(30, 0), pointer: 2);
    for (var i = 1; i <= 5; i++) {
      await left.moveTo(center - Offset(30 + i * 15, 0));
      await right.moveTo(center + Offset(30 + i * 15, 0));
      await tester.pump();
    }
    expect(cameraOf(tester).zoom, closeTo(1.35, 0.001));
    expect(cameraOf(tester).yaw.abs(), lessThan(0.1));
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    await tester.dragFrom(center, const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(cameraOf(tester).pitch, closeTo(0.8, 0.001));
  });

  testWidgets(
      'Mutating eye flags and quickly switching levels replaces stale textures',
      (tester) async {
    final levels = DarumaModel.defaultLevels();
    var doll = levels.first;
    Future<void> show() => tester.pumpWidget(
        MaterialApp(home: DarumaOrbitView(daruma: doll, size: 300)));
    DarumaOrbitPainter? current() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<DarumaOrbitPainter>()
        .firstOrNull;
    Future<void> waitForSurface() async {
      for (var attempt = 0; attempt < 100 && current() == null; attempt++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(current(), isNotNull);
      expect(current()!.surface.matches(doll), isTrue);
    }

    await show();
    await waitForSurface();
    final firstSurface = current()!.surface;
    doll.hasRightEye = true;
    await show();
    await waitForSurface();
    expect(current()!.surface, isNot(same(firstSurface)));
    for (final level in levels.skip(1)) {
      doll = level;
      await show();
    }
    await waitForSurface();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(current()!.surface.matches(levels.last), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Backgrounding the app stops a tap spring without restarting it',
      (tester) async {
    final doll = DarumaModel.defaultLevels().first;
    final surface = (await tester.runAsync(() => DarumaSurface.create(doll)))!;
    addTearDown(surface.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child:
                DarumaOrbitView(daruma: doll, size: 300, surface: surface))));
    await tester.tap(find.byKey(const ValueKey('daruma-orbit-gesture')));
    await tester.pump(const Duration(milliseconds: 32));
    expect(tester.hasRunningAnimations, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(cameraOf(tester).roll, 0);
    expect(cameraOf(tester).rock, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('A late texture completion after navigation is discarded safely',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: DarumaOrbitView(daruma: DarumaModel.defaultLevels().first)));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
