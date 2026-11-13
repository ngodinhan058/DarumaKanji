import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/daruma_model.dart';

/// Painted papier-mâché Daruma inspired by Takasaki craftsmanship.
/// Ornament shares a 400 × 440 coordinate system at every display size.
class Daruma3dPainter extends CustomPainter {
  final DarumaModel daruma;
  final double tiltAngle;

  Daruma3dPainter({required this.daruma, required this.tiltAngle});

  static const _ink = Color(0xFF211B18);
  static const _ivory = Color(0xFFFFF5DC);
  static const _gold = Color(0xFFE7BD65);

  /// Transparent, unlit artwork for baking onto the real 3D surface.
  /// Coordinates match the legacy 400 × 440 front illustration.
  void paintDecoration(Canvas canvas) {
    _drawRobe(canvas);
    _drawFace(canvas);
    _drawBelly(canvas);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 400, size.height / 440);
    canvas.save();
    canvas.translate(
        (size.width - 400 * scale) / 2, (size.height - 440 * scale) / 2);
    canvas.scale(scale);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(200, 405), width: 230, height: 20),
      Paint()
        ..color = const Color(0xFF513327).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.translate(200 + tiltAngle * 12, 395);
    canvas.rotate(tiltAngle);
    canvas.translate(-200, -395);
    final body = Path()
      ..moveTo(200, 30)
      ..cubicTo(105, 27, 67, 89, 49, 177)
      ..cubicTo(31, 259, 40, 331, 91, 372)
      ..cubicTo(137, 410, 266, 410, 309, 372)
      ..cubicTo(361, 332, 369, 258, 351, 177)
      ..cubicTo(333, 90, 294, 27, 200, 30)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.45, -0.65),
            radius: 1.25,
            colors: [
              Color.lerp(daruma.primaryColor, const Color(0xFFFF6941), 0.32)!,
              daruma.primaryColor,
              daruma.darkColor,
            ],
            stops: const [0, 0.5, 1],
          ).createShader(const Rect.fromLTWH(38, 30, 324, 370)));
    canvas.save();
    canvas.clipPath(body);
    // Seeded speckling suggests handmade paper beneath the red lacquer.
    final random = math.Random(17);
    for (var i = 0; i < 1000; i++) {
      canvas.drawCircle(
        Offset(38 + random.nextDouble() * 324, 30 + random.nextDouble() * 370),
        0.25 + random.nextDouble() * 0.65,
        Paint()
          ..color = (i.isEven ? Colors.white : _ink).withValues(alpha: 0.035),
      );
    }
    _stroke(
        canvas,
        Path()
          ..moveTo(103, 80)
          ..cubicTo(74, 119, 62, 168, 59, 204),
        const Color(0xFFFFB38D).withValues(alpha: 0.32),
        3);
    _drawRobe(canvas);
    _drawFace(canvas);
    _drawBelly(canvas);
    canvas.restore();
    canvas.restore();
  }

  void _drawRobe(Canvas canvas) {
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(400, 0);
        canvas.scale(-1, 1);
      }
      for (var i = 0; i < 3; i++) {
        final x = 70.0 + i * 22;
        final top = 252.0 + i * 17;
        final band = Path()
          ..moveTo(x, top)
          ..cubicTo(x - 4, top + 28, x + 4, 337, x + 23, 364 + i * 7)
          ..lineTo(x + 30, 368 + i * 7)
          ..cubicTo(x + 12, 332, x + 5, top + 30, x + 6, top - 2)
          ..close();
        canvas.drawPath(band, Paint()..color = _gold);
        _stroke(
            canvas,
            Path()
              ..moveTo(x + 2, top + 8)
              ..quadraticBezierTo(x + 1, 320, x + 23, 359),
            const Color(0xFFFFE7A6).withValues(alpha: 0.7),
            1);
      }
      for (var i = 0; i < 3; i++) {
        final y = 157.0 + i * 25;
        _stroke(
            canvas,
            Path()
              ..moveTo(65, y)
              ..quadraticBezierTo(74, y - 8, 84, y - 10),
            _gold,
            4);
      }
      canvas.restore();
    }
  }

  void _drawFace(Canvas canvas) {
    final face = Path()
      ..moveTo(200, 75)
      ..cubicTo(148, 72, 110, 80, 93, 113)
      ..cubicTo(80, 143, 80, 203, 98, 227)
      ..cubicTo(118, 258, 162, 267, 200, 268)
      ..cubicTo(238, 267, 283, 258, 302, 227)
      ..cubicTo(320, 202, 320, 144, 307, 113)
      ..cubicTo(291, 80, 251, 72, 200, 75)
      ..close();
    canvas.drawPath(face.shift(const Offset(0, 3)),
        Paint()..color = daruma.darkColor.withValues(alpha: 0.7));
    canvas.drawPath(
        face,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCED), Color(0xFFF5E9CF), Color(0xFFE0C69E)],
            stops: [0, 0.65, 1],
          ).createShader(const Rect.fromLTWH(80, 75, 240, 193)));
    _stroke(canvas, face, const Color(0xFFBA712F), 2.2);
    // Anatomical left is on the viewer's right.
    _drawEye(canvas, const Offset(150, 150), daruma.hasRightEye);
    _drawEye(canvas, const Offset(250, 150), daruma.hasLeftEye);
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(400, 0);
        canvas.scale(-1, 1);
      }
      _drawCraneBrow(canvas);
      _drawTortoiseBeard(canvas);
      canvas.restore();
    }
    final nose = Path()
      ..moveTo(184, 179)
      ..cubicTo(184, 168, 192, 163, 200, 163)
      ..cubicTo(208, 163, 216, 168, 216, 179)
      ..cubicTo(207, 175, 206, 183, 200, 183)
      ..cubicTo(194, 183, 193, 175, 184, 179);
    _stroke(canvas, nose, const Color(0xFFAF382A), 3);
    _stroke(
        canvas,
        Path()
          ..moveTo(192, 185)
          ..quadraticBezierTo(200, 189, 208, 185),
        _ink,
        2);
    canvas.drawPath(
        Path()
          ..moveTo(184, 210)
          ..quadraticBezierTo(200, 204, 216, 210)
          ..quadraticBezierTo(200, 221, 184, 210),
        Paint()..color = const Color(0xFF9F3428));
    _stroke(
        canvas,
        Path()
          ..moveTo(188, 211)
          ..quadraticBezierTo(200, 212, 212, 211),
        _ink,
        1.8);
    for (var i = 0; i < 7; i++) {
      final x = 178.0 + i * 7;
      _stroke(
          canvas,
          Path()
            ..moveTo(x, 230)
            ..quadraticBezierTo(
                200 + (x - 200) * 0.7, 244, 200 + (x - 200) * 0.45, 252),
          _ink,
          i.isEven ? 2.4 : 1.3);
    }
  }

  void _drawEye(Canvas canvas, Offset center, bool filled) {
    canvas.drawCircle(center, 34, Paint()..color = _gold);
    canvas.drawCircle(center, 30.5, Paint()..color = const Color(0xFFA7442F));
    canvas.drawCircle(center, 27.5, Paint()..color = const Color(0xFFFFFDF3));
    if (filled) {
      canvas.drawOval(Rect.fromCenter(center: center, width: 34, height: 39),
          Paint()..color = _ink);
    }
    _stroke(
        canvas,
        Path()
          ..moveTo(center.dx - 28, center.dy + 19)
          ..quadraticBezierTo(
              center.dx, center.dy + 46, center.dx + 29, center.dy + 17),
        const Color(0xFFBB4B32),
        1.6);
  }

  void _drawCraneBrow(Canvas canvas) {
    canvas.drawPath(
        Path()
          ..moveTo(104, 126)
          ..cubicTo(111, 103, 137, 89, 162, 97)
          ..cubicTo(176, 101, 183, 112, 183, 129)
          ..cubicTo(169, 113, 151, 110, 137, 114)
          ..cubicTo(125, 118, 117, 124, 104, 126)
          ..close(),
        Paint()..color = _ink);
    for (var i = 0; i < 5; i++) {
      _stroke(
          canvas,
          Path()
            ..moveTo(109 + i * 6, 117 - i * 2)
            ..quadraticBezierTo(121 + i * 5, 97 - i * 2, 134 + i * 7, 91.0 + i),
          _ink,
          1.6);
    }
    _stroke(
        canvas,
        Path()
          ..moveTo(112, 116)
          ..quadraticBezierTo(137, 98, 161, 104),
        _ivory.withValues(alpha: 0.6),
        1.1);
  }

  void _drawTortoiseBeard(Canvas canvas) {
    canvas.drawPath(
        Path()
          ..moveTo(105, 176)
          ..cubicTo(107, 192, 128, 200, 146, 195)
          ..cubicTo(157, 190, 172, 185, 184, 193)
          ..cubicTo(169, 194, 159, 210, 141, 214)
          ..cubicTo(121, 218, 105, 200, 105, 176)
          ..close(),
        Paint()..color = _ink);
    for (var i = 0; i < 5; i++) {
      _stroke(
          canvas,
          Path()
            ..moveTo(99 + i * 3, 182 + i * 6)
            ..cubicTo(98 + i * 3, 211 + i * 5, 130 + i * 5, 239 + i * 3,
                164 + i * 4, 215 + i * 3),
          _ink,
          2.4 - i * 0.25);
    }
    _stroke(
        canvas,
        Path()
          ..moveTo(112, 190)
          ..quadraticBezierTo(131, 210, 159, 200),
        _ivory,
        1.5);
    _stroke(
        canvas,
        Path()
          ..moveTo(113, 220)
          ..quadraticBezierTo(137, 243, 165, 227),
        _ink,
        1.4);
  }

  void _drawBelly(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
          text: daruma.kanjiSymbol,
          style: const TextStyle(
            fontFamily: 'DarumaMincho',
            fontSize: 82,
            height: 1,
            fontWeight: FontWeight.w800,
            color: _ivory,
          )),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(200 - textPainter.width / 2, 287));
    textPainter.dispose();
  }

  void _stroke(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  // DarumaModel is mutable: a new painter must reflect updated eye flags.
  @override
  bool shouldRepaint(covariant Daruma3dPainter oldDelegate) => true;
}
