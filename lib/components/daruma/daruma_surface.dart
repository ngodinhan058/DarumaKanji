import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/daruma_model.dart';
import 'daruma_3d_painter.dart';
import 'daruma_mesh.dart';

/// One owned 1024² texture. The view disposes it when its appearance changes.
class DarumaSurface {
  final ui.Image image;
  final String appearance;
  bool _disposed = false;
  late final shader = ui.ImageShader(
      image,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));

  DarumaSurface._(this.image, this.appearance);

  static String keyOf(DarumaModel model) =>
      '${model.primaryColor.toARGB32()}/${model.kanjiSymbol}/${model.hasLeftEye}/${model.hasRightEye}';

  bool matches(DarumaModel model) => !_disposed && appearance == keyOf(model);

  static Future<DarumaSurface> create(DarumaModel model) async {
    final key = keyOf(model);
    final bodyColor = model.primaryColor;
    const pixels = 1024;
    const artScale = 2.0;
    final artRecorder = ui.PictureRecorder();
    final artCanvas = Canvas(artRecorder)..scale(artScale);
    Daruma3dPainter(daruma: model, tiltAngle: 0).paintDecoration(artCanvas);
    final artPicture = artRecorder.endRecording();
    late final ui.Image art;
    try {
      art = await artPicture.toImage(800, 880);
    } finally {
      artPicture.dispose();
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    try {
      canvas.drawColor(bodyColor, BlendMode.src);
      final random = math.Random(37);
      for (var i = 0; i < 3500; i++) {
        canvas.drawCircle(
            Offset(random.nextDouble() * pixels, random.nextDouble() * pixels),
            0.3 + random.nextDouble() * 0.8,
            Paint()
              ..color = (i.isEven ? Colors.white : Colors.black)
                  .withValues(alpha: 0.035));
      }
      final gold = Paint()
        ..color = const Color(0xFFE7BD65)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final u in [0.04, 0.10, 0.17, 0.23, 0.77, 0.83, 0.90, 0.96]) {
        gold.strokeWidth = u < 0.1 || u > 0.9 ? 6 : 9;
        canvas.drawPath(
            Path()
              ..moveTo(u * pixels, pixels * 0.58)
              ..quadraticBezierTo(
                  u * pixels + 8, pixels * 0.76, u * pixels + 4, pixels * 0.93),
            gold);
      }
      // The back is the seam (u = 0 = 1), so repeat the same centered inscription.
      for (final center in [0.0, pixels.toDouble()]) {
        var y = pixels * 0.18;
        for (final character in '七転八起'.split('')) {
          final text = TextPainter(
              text: TextSpan(
                  text: character,
                  style: const TextStyle(
                      fontFamily: 'DarumaMincho',
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFE0A0))),
              textDirection: TextDirection.ltr)
            ..layout();
          canvas.save();
          canvas.translate(center, y);
          canvas.scale(0.45, 1);
          text.paint(canvas, Offset(-text.width / 2, 0));
          canvas.restore();
          y += 74;
          text.dispose();
        }
      }
      // Inverse-bake the approved front artwork into the curved surface's UVs.
      final mesh = DarumaMesh.standard;
      final positions = <Offset>[], coordinates = <Offset>[];
      for (var i = 0; i < mesh.indices.length; i += 3) {
        final triangle = [
          mesh.vertices[mesh.indices[i]],
          mesh.vertices[mesh.indices[i + 1]],
          mesh.vertices[mesh.indices[i + 2]]
        ];
        if (triangle.any((vertex) => vertex.position.z < -0.00001)) continue;
        for (final vertex in triangle) {
          positions.add(Offset(vertex.u * pixels, vertex.v * pixels));
          coordinates.add(Offset((200 + vertex.position.x * 160) * artScale,
              (30 + vertex.v * 370) * artScale));
        }
      }
      final vertices = ui.Vertices(ui.VertexMode.triangles, positions,
          textureCoordinates: coordinates);
      final artShader = ui.ImageShader(
          art,
          ui.TileMode.clamp,
          ui.TileMode.clamp,
          Float64List.fromList(
              [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
      canvas.drawVertices(
          vertices,
          BlendMode.src,
          Paint()
            ..shader = artShader
            ..filterQuality = FilterQuality.low);
      final picture = recorder.endRecording();
      try {
        final image = await picture.toImage(pixels, pixels);
        return DarumaSurface._(image, key);
      } finally {
        picture.dispose();
        vertices.dispose();
        artShader.dispose();
      }
    } finally {
      art.dispose();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    shader.dispose();
    image.dispose();
  }
}
