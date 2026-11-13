import 'dart:math' as math;

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
  final double yaw, pitch, zoom, roll;
  DarumaCamera(
      {double yaw = 0, double pitch = 0, double zoom = 1, double roll = 0})
      : yaw = yaw.isFinite ? (yaw + math.pi) % (2 * math.pi) - math.pi : 0,
        pitch = pitch.isFinite ? pitch.clamp(-0.65, 0.8) : 0,
        zoom = zoom.isFinite ? zoom.clamp(0.8, 1.35) : 1,
        roll = roll.isFinite ? roll.clamp(-0.3, 0.3) : 0;

  late final _cy = math.cos(yaw), _sy = math.sin(yaw);
  late final _cp = math.cos(pitch), _sp = math.sin(pitch);
  late final _cr = math.cos(roll), _sr = math.sin(roll);

  Point3 transform(Point3 p, {bool direction = false}) {
    final x = p.x * _cy + p.z * _sy;
    final z = -p.x * _sy + p.z * _cy;
    final y = p.y * _cp - z * _sp;
    final depth = p.y * _sp + z * _cp;
    final pivotY = direction ? 0 : DarumaMesh.bottom;
    return Point3(x * _cr - (y - pivotY) * _sr,
        x * _sr + (y - pivotY) * _cr + pivotY, depth);
  }

  Point3 project(Point3 p) => projectTransformed(transform(p));

  Point3 projectTransformed(Point3 p) {
    final perspective = 5.2 / (5.2 - p.z);
    return Point3(p.x * perspective * zoom, -p.y * perspective * zoom, p.z);
  }
}
