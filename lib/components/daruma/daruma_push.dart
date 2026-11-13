import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/physics.dart';
import 'daruma_mesh.dart';

/// Angular impulse from an actual visible mesh contact, in radians/second.
class DarumaPushImpulse {
  final double rollVelocity, rockVelocity;
  const DarumaPushImpulse(this.rollVelocity, this.rockVelocity);

  static DarumaPushImpulse? pick(
      DarumaCamera camera, Size viewport, Offset tap) {
    if (!tap.dx.isFinite ||
        !tap.dy.isFinite ||
        !viewport.width.isFinite ||
        !viewport.height.isFinite ||
        viewport.width <= 0 ||
        viewport.height <= 0 ||
        !(Offset.zero & viewport).contains(tap)) return null;
    final mesh = DarumaMesh.standard;
    final points = [
      for (final v in mesh.vertices) camera.transform(v.position)
    ];
    final screen = [
      for (final p in points)
        DarumaCamera.viewportPosition(camera.projectTransformed(p), viewport)
    ];
    var closest = -double.infinity;
    DarumaPushImpulse? result;
    double cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;
    for (var triangle = 0; triangle < mesh.indices.length; triangle += 3) {
      final ia = mesh.indices[triangle],
          ib = mesh.indices[triangle + 1],
          ic = mesh.indices[triangle + 2];
      final a = screen[ia], b = screen[ib], c = screen[ic];
      final area = cross(b - a, c - a);
      if (area >= -0.00001) continue;
      var wa = cross(b - tap, c - tap) / area;
      var wb = cross(c - tap, a - tap) / area;
      var wc = 1 - wa - wb;
      if (wa < -0.00001 || wb < -0.00001 || wc < -0.00001) continue;
      // Correct screen-space barycentrics for perspective before sampling the
      // surface normal and original height above the weighted base.
      wa /= DarumaCamera.distance - points[ia].z;
      wb /= DarumaCamera.distance - points[ib].z;
      wc /= DarumaCamera.distance - points[ic].z;
      final total = wa + wb + wc;
      wa /= total;
      wb /= total;
      wc /= total;
      final depth = points[ia].z * wa + points[ib].z * wb + points[ic].z * wc;
      if (depth <= closest) continue;
      closest = depth;
      final na = camera.transform(mesh.vertices[ia].normal, direction: true);
      final nb = camera.transform(mesh.vertices[ib].normal, direction: true);
      final nc = camera.transform(mesh.vertices[ic].normal, direction: true);
      final normal = Point3(
              na.x * wa + nb.x * wb + nc.x * wc,
              na.y * wa + nb.y * wb + nc.y * wc,
              na.z * wa + nb.z * wb + nc.z * wc)
          .normalized;
      final height = (mesh.vertices[ia].position.y * wa +
              mesh.vertices[ib].position.y * wb +
              mesh.vertices[ic].position.y * wc -
              DarumaMesh.bottom) /
          DarumaMesh.height;
      final strength = 4.4 * (0.45 + 0.55 * height.clamp(0, 1));
      result = DarumaPushImpulse(
          normal.x * strength, -math.max(0.18, normal.z) * strength);
    }
    return result;
  }
}

/// Two damped axes sharing one elapsed-time controller. Repeated pushes retain
/// angular momentum; a combined energy budget prevents unbounded tap stacking.
class DarumaPushMotion extends Simulation {
  static const _mass = 1.15, _stiffness = 50.0, maxAngle = 0.62;
  static const _spring =
      SpringDescription(mass: _mass, stiffness: _stiffness, damping: 4.6);
  final SpringSimulation _roll, _rock;
  DarumaPushMotion._(this._roll, this._rock);

  factory DarumaPushMotion(
      {double roll = 0,
      double rock = 0,
      double rollVelocity = 0,
      double rockVelocity = 0,
      required DarumaPushImpulse impulse}) {
    double finite(double value) => value.isFinite ? value : 0;
    var a = finite(roll), b = finite(rock);
    final angle = math.sqrt(a * a + b * b);
    if (angle > maxAngle) {
      a *= maxAngle / angle;
      b *= maxAngle / angle;
    }
    var va = finite(rollVelocity) + finite(impulse.rollVelocity);
    var vb = finite(rockVelocity) + finite(impulse.rockVelocity);
    final speed = math.sqrt(va * va + vb * vb);
    final allowance = math.sqrt(
        _stiffness / _mass * math.max(0, maxAngle * maxAngle - a * a - b * b));
    if (speed > allowance && speed > 0) {
      va *= allowance / speed;
      vb *= allowance / speed;
    }
    return DarumaPushMotion._(SpringSimulation(_spring, a, 0, va),
        SpringSimulation(_spring, b, 0, vb));
  }

  double rollAt(double time) => _roll.x(time);
  double rockAt(double time) => _rock.x(time);
  double rollVelocityAt(double time) => _roll.dx(time);
  double rockVelocityAt(double time) => _rock.dx(time);
  @override
  double x(double time) => time;
  @override
  double dx(double time) => 1;
  @override
  bool isDone(double time) => _roll.isDone(time) && _rock.isDone(time);
}
