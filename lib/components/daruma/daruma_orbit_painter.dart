import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'daruma_mesh.dart';
import 'daruma_surface.dart';

/// Real mesh projection, hidden-surface culling and smooth vertex lighting.
/// The doll is convex: front-face culling removes all occluded triangles,
/// allowing a single textured draw without a general-purpose depth buffer.
class DarumaOrbitPainter extends CustomPainter {
  final DarumaSurface surface;
  final DarumaCamera camera;
  DarumaOrbitPainter({required this.surface, required this.camera});

  static final _light = const Point3(-0.45, 0.7, 1).normalized;
  static final _halfLight = (_light + const Point3(0, 0, 1)).normalized;
  static final _mesh = DarumaMesh.standard;
  static final _uvs = Float32List.fromList([
    for (final vertex in _mesh.vertices) ...[vertex.u * 1024, vertex.v * 1024]
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height / 1.1) * 0.37;
    final positions = Float32List(_mesh.vertices.length * 2);
    final colors = Int32List(_mesh.vertices.length);
    final highlights = Int32List(_mesh.vertices.length);
    for (var i = 0; i < _mesh.vertices.length; i++) {
      final vertex = _mesh.vertices[i];
      final p = camera.project(vertex.position);
      positions[i * 2] = size.width / 2 + p.x * scale;
      positions[i * 2 + 1] = size.height * 0.48 + p.y * scale;
      final n = camera.transform(vertex.normal, direction: true);
      final diffuse = 0.62 + 0.38 * math.max(0, n.dot(_light));
      final value = (255 * diffuse).round().clamp(0, 255);
      colors[i] = Color.fromARGB(255, value, value, value).toARGB32();
      final shine = math.pow(math.max(0, n.dot(_halfLight)), 42) * 0.24;
      highlights[i] =
          Color.fromARGB((255 * shine).round(), 255, 250, 230).toARGB32();
    }
    final visible = <int>[];
    for (var i = 0; i < _mesh.indices.length; i += 3) {
      final a = _mesh.indices[i],
          b = _mesh.indices[i + 1],
          c = _mesh.indices[i + 2];
      final area = (positions[b * 2] - positions[a * 2]) *
              (positions[c * 2 + 1] - positions[a * 2 + 1]) -
          (positions[b * 2 + 1] - positions[a * 2 + 1]) *
              (positions[c * 2] - positions[a * 2]);
      if (area < -0.00001) visible.addAll([a, b, c]);
    }
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.88),
            width: size.width * 0.56 * camera.zoom,
            height: size.height * 0.035),
        Paint()
          ..color = const Color(0xFF483426).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    final indices = Uint16List.fromList(visible);
    final body = ui.Vertices.raw(ui.VertexMode.triangles, positions,
        textureCoordinates: _uvs, colors: colors, indices: indices);
    canvas.drawVertices(
        body,
        BlendMode.modulate,
        Paint()
          ..shader = surface.shader
          ..filterQuality = FilterQuality.low);
    body.dispose();
    final gloss = ui.Vertices.raw(ui.VertexMode.triangles, positions,
        colors: highlights, indices: indices);
    canvas.drawVertices(gloss, BlendMode.dst, Paint());
    gloss.dispose();
  }

  @override
  bool shouldRepaint(covariant DarumaOrbitPainter oldDelegate) =>
      oldDelegate.surface != surface || oldDelegate.camera != camera;
}
