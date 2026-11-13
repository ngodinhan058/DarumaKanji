import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/daruma_model.dart';
import 'daruma_3d_painter.dart';
import 'daruma_mesh.dart';
import 'daruma_orbit_painter.dart';
import 'daruma_surface.dart';

class DarumaOrbitView extends StatefulWidget {
  final DarumaModel daruma;
  final double size;

  /// Optional shared resource: caller retains ownership when supplied.
  final DarumaSurface? surface;
  const DarumaOrbitView(
      {super.key, required this.daruma, this.size = 300, this.surface});

  @override
  State<DarumaOrbitView> createState() => _DarumaOrbitViewState();
}

class _DarumaOrbitViewState extends State<DarumaOrbitView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _spring;
  DarumaCamera _camera = DarumaCamera(pitch: 0.10);
  DarumaSurface? _surface;
  bool _ownsSurface = false, _failed = false, _reduceMotion = false;
  int _request = 0, _pointers = 0;
  String _requestedAppearance = '';
  Offset _startFocal = Offset.zero;
  double _startYaw = 0, _startPitch = 0, _startZoom = 1, _startScale = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _spring = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _camera = DarumaCamera(
              yaw: _camera.yaw,
              pitch: _camera.pitch,
              zoom: _camera.zoom,
              roll: _spring.value);
        });
      });
    _loadSurface();
  }

  void _loadSurface() {
    final generation = ++_request;
    _requestedAppearance = DarumaSurface.keyOf(widget.daruma);
    _failed = false;
    final provided = widget.surface;
    if (provided != null && provided.matches(widget.daruma)) {
      _replaceSurface(provided, owned: false);
      return;
    }
    unawaited(DarumaSurface.create(widget.daruma).then((created) {
      if (!mounted || generation != _request) {
        created.dispose();
        return;
      }
      setState(() => _replaceSurface(created, owned: true));
    }).catchError((Object error, StackTrace stack) {
      if (mounted && generation == _request) setState(() => _failed = true);
    }));
  }

  void _replaceSurface(DarumaSurface next, {required bool owned}) {
    if (_ownsSurface && _surface != next) _surface?.dispose();
    _surface = next;
    _ownsSurface = owned;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion || !TickerMode.valuesOf(context).enabled) _stopWobble();
  }

  @override
  void didUpdateWidget(covariant DarumaOrbitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.daruma.id != widget.daruma.id) _reset();
    if (_requestedAppearance != DarumaSurface.keyOf(widget.daruma) ||
        oldWidget.surface != widget.surface) {
      _loadSurface();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(_stopWobble);
    }
  }

  void _stopWobble() {
    _spring.stop();
    _camera = DarumaCamera(
        yaw: _camera.yaw, pitch: _camera.pitch, zoom: _camera.zoom);
  }

  void _tap() {
    HapticFeedback.selectionClick();
    if (_reduceMotion) return;
    _spring.animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 100, damping: 9),
      0.09,
      0,
      -0.15,
    ));
  }

  void _reset() {
    _spring.stop();
    setState(() => _camera = DarumaCamera(pitch: 0.10));
  }

  void _start(ScaleStartDetails details) {
    _stopWobble();
    _startFocal = details.localFocalPoint;
    _startYaw = _camera.yaw;
    _startPitch = _camera.pitch;
    _startZoom = _camera.zoom;
    _startScale = 1;
    _pointers = details.pointerCount;
  }

  void _update(ScaleUpdateDetails details) {
    if (_pointers != details.pointerCount) {
      _startFocal = details.localFocalPoint;
      _startYaw = _camera.yaw;
      _startPitch = _camera.pitch;
      _startZoom = _camera.zoom;
      _startScale = details.scale;
      _pointers = details.pointerCount;
    }
    final delta = details.localFocalPoint - _startFocal;
    if (!delta.dx.isFinite ||
        !delta.dy.isFinite ||
        !details.scale.isFinite ||
        details.scale <= 0 ||
        _startScale <= 0) {
      return;
    }
    setState(() => _camera = DarumaCamera(
          yaw: _startYaw +
              (_pointers == 1 ? delta.dx / widget.size * math.pi * 2 : 0),
          pitch:
              _startPitch + (_pointers == 1 ? delta.dy / widget.size * 1.8 : 0),
          zoom: _startZoom * details.scale / _startScale,
        ));
  }

  void _turn(double angle) {
    _stopWobble();
    setState(() => _camera = DarumaCamera(
        yaw: _camera.yaw + angle, pitch: _camera.pitch, zoom: _camera.zoom));
  }

  @override
  void dispose() {
    ++_request;
    WidgetsBinding.instance.removeObserver(this);
    _spring.dispose();
    if (_ownsSurface) _surface?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = _surface;
    final ready = surface != null && surface.matches(widget.daruma);
    final media = MediaQuery.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        label: 'Daruma 3D ${widget.daruma.name}. '
            '${widget.daruma.hasLeftEye ? "Đã khai nhãn" : "Chưa khai nhãn"}. '
            '${widget.daruma.hasRightEye ? "Đã hoàn nguyện" : "Chưa hoàn nguyện"}.',
        hint: 'Kéo để xoay, chụm hai ngón tay để phóng to.',
        onIncrease: () => _turn(math.pi / 6),
        onDecrease: () => _turn(-math.pi / 6),
        onTap: _tap,
        // A scale recognizer normally waits twice as far as the parent's
        // vertical-scroll recognizer. Give orbit drags an earlier threshold
        // inside this region only; outside it the page keeps normal scrolling.
        child: MediaQuery(
            data: media.copyWith(
                gestureSettings: DeviceGestureSettings(
                    touchSlop:
                        (media.gestureSettings.touchSlop ?? kTouchSlop) * 0.3)),
            child: GestureDetector(
              key: const ValueKey('daruma-orbit-gesture'),
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onScaleStart: ready ? _start : null,
              onScaleUpdate: ready ? _update : null,
              onTap: ready ? _tap : null,
              child: SizedBox(
                  width: widget.size,
                  height: widget.size * 1.1,
                  child: ClipRect(
                      child: RepaintBoundary(
                          child: CustomPaint(
                    painter: ready
                        ? DarumaOrbitPainter(surface: surface, camera: _camera)
                        : Daruma3dPainter(daruma: widget.daruma, tiltAngle: 0),
                  )))),
            )),
      ),
      if (_failed)
        TextButton.icon(
            onPressed: () => setState(_loadSurface),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại 3D'))
      else
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(ready ? 'Kéo để xoay 360°' : 'Đang chuẩn bị Daruma 3D…',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            IconButton(
                tooltip: 'Xoay trái',
                onPressed: ready ? () => _turn(-math.pi / 6) : null,
                icon: const Icon(Icons.chevron_left, size: 20)),
            IconButton(
                tooltip: 'Mặt trước',
                onPressed: ready ? _reset : null,
                icon: const Icon(Icons.restart_alt, size: 20)),
            IconButton(
                tooltip: 'Xoay phải',
                onPressed: ready ? () => _turn(math.pi / 6) : null,
                icon: const Icon(Icons.chevron_right, size: 20)),
          ],
        ),
    ]);
  }
}
