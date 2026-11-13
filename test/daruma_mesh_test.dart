import 'dart:math' as math;
import 'package:daruma_kanji/components/daruma/daruma_mesh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Daruma is a bounded closed mesh with outward-facing triangles', () {
    final mesh = DarumaMesh.build();
    expect(mesh.indices.length ~/ 3, lessThanOrEqualTo(3000));
    final edges = <String, int>{};
    String pointKey(int index) {
      final p = mesh.vertices[index].position;
      return '${(p.x * 100000).round()},${(p.y * 100000).round()},${(p.z * 100000).round()}';
    }

    for (var i = 0; i < mesh.indices.length; i += 3) {
      final a = mesh.vertices[mesh.indices[i]];
      final b = mesh.vertices[mesh.indices[i + 1]];
      final c = mesh.vertices[mesh.indices[i + 2]];
      final normal = (b.position - a.position).cross(c.position - a.position);
      expect(normal.length, greaterThan(0.000001));
      expect(normal.dot(a.normal + b.normal + c.normal), greaterThan(0));
      for (var j = 0; j < 3; j++) {
        final keys = [
          pointKey(mesh.indices[i + j]),
          pointKey(mesh.indices[i + (j + 1) % 3])
        ]..sort();
        edges.update(keys.join('|'), (count) => count + 1, ifAbsent: () => 1);
      }
    }
    expect(edges.values.every((count) => count == 2), isTrue,
        reason:
            'Every physical edge, including seam and poles, must have two faces');
  });

  test('Full orbit returns identical perspective and a half turn reveals back',
      () {
    final front = DarumaCamera(yaw: 0);
    final full = DarumaCamera(yaw: math.pi * 2);
    final back = DarumaCamera(yaw: math.pi);
    const point = Point3(0.3, 0.6, 0.8);
    final a = front.project(point);
    final b = full.project(point);
    expect(a.x, closeTo(b.x, 0.000001));
    expect(a.y, closeTo(b.y, 0.000001));
    expect(back.transform(point).z, closeTo(-0.8, 0.000001));
  });

  test('Camera normalizes repeated turns and rejects invalid gesture values',
      () {
    final camera =
        DarumaCamera(yaw: 2000 * math.pi + 0.2, pitch: 10, zoom: 100);
    expect(camera.yaw, closeTo(0.2, 0.000001));
    expect(camera.pitch, lessThanOrEqualTo(0.8));
    expect(camera.zoom, lessThanOrEqualTo(1.35));
    final invalid =
        DarumaCamera(yaw: double.nan, pitch: double.infinity, zoom: 0);
    final p = invalid.project(const Point3(0, 1, 0));
    expect(p.x.isFinite && p.y.isFinite, isTrue);
    expect(invalid.zoom, greaterThan(0));
  });
}
