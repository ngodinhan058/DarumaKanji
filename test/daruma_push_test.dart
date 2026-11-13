import 'dart:math' as math;
import 'dart:ui';
import 'package:daruma_kanji/components/daruma/daruma_mesh.dart';
import 'package:daruma_kanji/components/daruma/daruma_push.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewport = Size(300, 330);
  Offset contact(double x, double y) =>
      Offset(viewport.width * x, viewport.height * y);

  test('Contact picking ignores empty background and respects zoom and orbit',
      () {
    final camera = DarumaCamera(pitch: 0.1);
    expect(
        DarumaPushImpulse.pick(camera, viewport, const Offset(2, 2)), isNull);
    expect(
        DarumaPushImpulse.pick(camera, viewport, const Offset(double.nan, 100)),
        isNull);
    for (final yaw in [0.0, math.pi / 2, math.pi]) {
      for (final zoom in [0.8, 1.35]) {
        final pose = DarumaCamera(yaw: yaw, pitch: 0.3, zoom: zoom);
        final impulse =
            DarumaPushImpulse.pick(pose, viewport, contact(0.5, 0.43));
        expect(impulse, isNotNull);
        expect(impulse!.rockVelocity, lessThan(-0.5));
      }
    }
  });

  test('Left and right flanks push away, front center rocks backward', () {
    final camera = DarumaCamera(pitch: 0.1);
    final left = DarumaPushImpulse.pick(camera, viewport, contact(0.28, 0.42))!;
    final right =
        DarumaPushImpulse.pick(camera, viewport, contact(0.72, 0.42))!;
    final center =
        DarumaPushImpulse.pick(camera, viewport, contact(0.5, 0.42))!;
    expect(left.rollVelocity, lessThan(-1));
    expect(right.rollVelocity, greaterThan(1));
    expect(center.rollVelocity.abs(), lessThan(0.05));
    expect(center.rockVelocity, lessThan(-1));
  });

  test('Higher front contact has more leverage than a tap near the base', () {
    final camera = DarumaCamera();
    final high = DarumaPushImpulse.pick(camera, viewport, contact(0.5, 0.32))!;
    final low = DarumaPushImpulse.pick(camera, viewport, contact(0.5, 0.73))!;
    expect(high.rockVelocity.abs(), greaterThan(low.rockVelocity.abs()));
  });

  test(
      'Repeated pushes preserve momentum while keeping angles bounded and settling',
      () {
    var motion = DarumaPushMotion(impulse: const DarumaPushImpulse(3, -2));
    for (var tap = 0; tap < 60; tap++) {
      const elapsed = 0.07;
      motion = DarumaPushMotion(
        roll: motion.rollAt(elapsed),
        rock: motion.rockAt(elapsed),
        rollVelocity: motion.rollVelocityAt(elapsed),
        rockVelocity: motion.rockVelocityAt(elapsed),
        impulse: DarumaPushImpulse(tap.isEven ? 3 : -3, -2),
      );
      for (var i = 0; i <= 60; i++) {
        final t = i / 60;
        final roll = motion.rollAt(t), rock = motion.rockAt(t);
        expect(roll.isFinite && rock.isFinite, isTrue);
        expect(math.sqrt(roll * roll + rock * rock), lessThanOrEqualTo(0.621));
      }
    }
    expect(motion.isDone(5), isTrue);
    expect(motion.rollAt(5).abs() + motion.rockAt(5).abs(), lessThan(0.002));
    final first = DarumaPushMotion(impulse: const DarumaPushImpulse(1, 0));
    final second = DarumaPushMotion(
        roll: first.rollAt(0.05),
        rollVelocity: first.rollVelocityAt(0.05),
        impulse: const DarumaPushImpulse(1, 0));
    expect(second.rollVelocityAt(0), greaterThan(first.rollVelocityAt(0.05)));
    expect(second.rollAt(0), closeTo(first.rollAt(0.05), 0.000001));
  });

  test(
      'Physical depth wobble leaves the orbit camera intact and stays above the floor',
      () {
    final camera = DarumaCamera(yaw: 0.6, rock: -0.4, roll: 0.3);
    expect(camera.yaw, closeTo(0.6, 0.00001));
    expect(camera.pitch, 0);
    final lowest = DarumaMesh.standard.vertices
        .map((v) => camera.transform(v.position).y)
        .reduce(math.min);
    expect(lowest, greaterThanOrEqualTo(DarumaMesh.bottom - 0.0001));
    expect(lowest, lessThan(DarumaMesh.bottom + 0.01));
  });
}
