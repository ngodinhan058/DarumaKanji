import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

class Point3 {
  final double x, y, z;
  const Point3(this.x, this.y, this.z);
  Point3 operator +(Point3 b) => Point3(x + b.x, y + b.y, z + b.z);
  Point3 operator -(Point3 b) => Point3(x - b.x, y - b.y, z - b.z);
  double dot(Point3 b) => x * b.x + y * b.y + z * b.z;
  Point3 cross(Point3 b) =>
      Point3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  double get length => math.sqrt(dot(this));
  Point3 get normalized {
    final magnitude = length;
    return magnitude > 0.000001
        ? Point3(x / magnitude, y / magnitude, z / magnitude)
        : const Point3(0, 1, 0);
  }
}

class DarumaVertex {
  final Point3 position, normal;
  final double u, v;
  const DarumaVertex(this.position, this.normal, this.u, this.v);
}

/// A convex, watertight surface of revolution with a weighted flat base.
class DarumaMesh {
  final List<DarumaVertex> vertices;
  final List<int> indices;
  const DarumaMesh._(this.vertices, this.indices);

  static const top = 1.1;
  static const rings = 28;
  static const segments = 48;
  static const maxPolar = 2.60;
  static final bottom = top * math.cos(maxPolar);
  static final height = top - bottom;
  static final standard = DarumaMesh.build();

  factory DarumaMesh.build() {
    final vertices = <DarumaVertex>[];
    final indices = <int>[];
    for (var row = 0; row <= rings; row++) {
      final polar = maxPolar * row / rings;
      final sin = math.sin(polar), cos = math.cos(polar);
      final radius = sin * (1 - 0.16 * cos);
      final derivative = cos * (1 - 0.16 * cos) + 0.16 * sin * sin;
      for (var col = 0; col <= segments; col++) {
        final u = col / segments;
        final angle = (u - 0.5) * 2 * math.pi;
        final sx = math.sin(angle), sz = math.cos(angle);
        vertices.add(DarumaVertex(
          Point3(radius * sx, top * cos, radius * sz),
          Point3(top * sin * sx, derivative, top * sin * sz).normalized,
          u,
          (top - top * cos) / height,
        ));
      }
    }
    for (var row = 0; row < rings; row++) {
      for (var col = 0; col < segments; col++) {
        final a = row * (segments + 1) + col;
        final b = a + 1, c = a + segments + 1, d = c + 1;
        if (row > 0) indices.addAll([a, c, b]);
        indices.addAll([b, c, d]);
      }
    }
    final center = vertices.length;
    vertices.add(
        DarumaVertex(Point3(0, bottom, 0), const Point3(0, -1, 0), 0.5, 1));
    for (var col = 0; col < segments; col++) {
      final edge = rings * (segments + 1) + col;
      indices.addAll([edge, center, edge + 1]);
    }
    return DarumaMesh._(
        List.unmodifiable(vertices), List.unmodifiable(indices));
  }
}

/// CPU camera transforms only; Flutter rasterizes the textured triangles.
class DarumaCamera {
  final double yaw, pitch, zoom, roll, rock;
  static const distance = 5.2;
  DarumaCamera(
      {double yaw = 0,
      double pitch = 0,
      double zoom = 1,
      double roll = 0,
      double rock = 0})
      : yaw = yaw.isFinite ? (yaw + math.pi) % (2 * math.pi) - math.pi : 0,
        pitch = pitch.isFinite ? pitch.clamp(-0.65, 0.8) : 0,
        zoom = zoom.isFinite ? zoom.clamp(0.8, 1.35) : 1,
        roll = roll.isFinite ? roll.clamp(-0.65, 0.65) : 0,
        rock = rock.isFinite ? rock.clamp(-0.65, 0.65) : 0;

  late final _cy = math.cos(yaw), _sy = math.sin(yaw);
  late final _cp = math.cos(pitch), _sp = math.sin(pitch);
  late final _cr = math.cos(roll), _sr = math.sin(roll);
  late final _ck = math.cos(rock), _sk = math.sin(rock);

  // Lift the tilted convex body just enough for its rounded base to keep
  // touching the floor. Axisymmetry lets us check only the 29 profile rings.
  late final double _lift = _floorLift();
  double _floorLift() {
    if (roll == 0 && rock == 0) return 0;
    final vertical = _cr * _ck;
    final horizontal = math.sqrt(math.max(0, 1 - vertical * vertical));
    var lowest = DarumaMesh.bottom;
    for (var row = 0; row <= DarumaMesh.rings; row++) {
      final p = DarumaMesh
          .standard.vertices[row * (DarumaMesh.segments + 1)].position;
      lowest = math.min(
          lowest,
          DarumaMesh.bottom +
              (p.y - DarumaMesh.bottom) * vertical -
              p.z.abs() * horizontal);
    }
    return DarumaMesh.bottom - lowest;
  }

  Point3 transform(Point3 p, {bool direction = false}) {
    final x = p.x * _cy + p.z * _sy;
    final z = -p.x * _sy + p.z * _cy;
    final pivotY = direction ? 0 : DarumaMesh.bottom;
    final rolledX = x * _cr - (p.y - pivotY) * _sr;
    final rolledY = x * _sr + (p.y - pivotY) * _cr;
    final y = rolledY * _ck - z * _sk + pivotY + (direction ? 0 : _lift);
    final depth = rolledY * _sk + z * _ck;
    return Point3(rolledX, y * _cp - depth * _sp, y * _sp + depth * _cp);
  }

  Point3 project(Point3 p) => projectTransformed(transform(p));

  Point3 projectTransformed(Point3 p) {
    final perspective = distance / (distance - p.z);
    return Point3(p.x * perspective * zoom, -p.y * perspective * zoom, p.z);
  }

  static Offset viewportPosition(Point3 projected, Size viewport) {
    final scale = math.min(viewport.width, viewport.height / 1.1) * 0.37;
    return Offset(viewport.width / 2 + projected.x * scale,
        viewport.height * 0.48 + projected.y * scale);
  }
}
