import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../../models/daruma_model.dart';
import 'daruma_3d_painter.dart';

class DarumaWobbleView extends StatefulWidget {
  final DarumaModel daruma;
  final double size;
  final VoidCallback? onTap;

  const DarumaWobbleView({
    Key? key,
    required this.daruma,
    this.size = 280,
    this.onTap,
  }) : super(key: key);

  @override
  State<DarumaWobbleView> createState() => _DarumaWobbleViewState();
}

class _DarumaWobbleViewState extends State<DarumaWobbleView>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  double _currentAngle = 0.0;
  double _dragStartX = 0.0;
  double _dragStartAngle = 0.0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    // Native Flutter spring; Anime.js targets JavaScript rather than Flutter.
    _springController = AnimationController.unbounded(vsync: this);
    _springController.addListener(() {
      setState(() {
        _currentAngle = _springController.value;
      });
    });

    // Nếu bỏ quên ngày học (chao đảo streak)
    if (widget.daruma.isWobblyStreak) {
      _currentAngle = 0.28;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _springController.stop();
      _currentAngle = 0;
    }
  }

  @override
  void didUpdateWidget(covariant DarumaWobbleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reduceMotion) _triggerSpringRestoration();
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _springController.stop();
    _dragStartX = details.localPosition.dx;
    _dragStartAngle = _currentAngle;
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_reduceMotion) return;
    final deltaX = details.localPosition.dx - _dragStartX;
    // Giới hạn biên độ kéo nghiêng +- 45 độ (0.8 rad)
    setState(() {
      _currentAngle =
          (_dragStartAngle + deltaX / widget.size * 0.9).clamp(-0.35, 0.35);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _triggerSpringRestoration();
    HapticFeedback.mediumImpact();
  }

  /// Restore the weighted doll using Flutter's native spring simulation.
  void _triggerSpringRestoration([double impulseVelocity = 0.0]) {
    if (_reduceMotion) return;
    const spring = SpringDescription(
      mass: 1.2, // Khối lượng đáy nặng giúp lật đật đứng vững
      stiffness: 110.0, // Độ căng lò xo đàn hồi
      damping: 10.0,
    );

    final targetAngle = widget.daruma.isWobblyStreak ? 0.25 : 0.0;
    final initialVelocity =
        impulseVelocity != 0.0 ? impulseVelocity : -_currentAngle * 2.8;

    final simulation = SpringSimulation(
      spring,
      _currentAngle,
      targetAngle,
      initialVelocity,
    );

    _springController.animateWith(simulation);
  }

  void _onTapDoll() {
    HapticFeedback.lightImpact();
    // Gõ vào thân thì lắc lư vui tươi 2 bên
    if (!_reduceMotion) {
      _currentAngle = (_currentAngle == 0.0) ? 0.12 : -0.12;
      _triggerSpringRestoration(0.5);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: 'Daruma ${widget.daruma.name}. '
            '${widget.daruma.hasLeftEye ? "Đã khai nhãn" : "Chưa khai nhãn"}. '
            '${widget.daruma.hasRightEye ? "Đã hoàn nguyện" : "Chưa hoàn nguyện"}.',
        button: true,
        onTap: _onTapDoll,
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: _onTapDoll,
          onHorizontalDragStart: _onPanStart,
          onHorizontalDragUpdate: _onPanUpdate,
          onHorizontalDragEnd: _onPanEnd,
          onHorizontalDragCancel: _triggerSpringRestoration,
          child: Center(
            child: SizedBox(
              width: widget.size,
              height: widget.size * 1.1,
              child: RepaintBoundary(
                  child: CustomPaint(
                painter: Daruma3dPainter(
                  daruma: widget.daruma,
                  tiltAngle: _currentAngle,
                ),
              )),
            ),
          ),
        ));
  }
}
