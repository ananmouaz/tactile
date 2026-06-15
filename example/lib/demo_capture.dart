// A self-playing demo that drives a synthetic finger across a hero [Tactile]
// and writes each rendered frame to disk as a PNG. Assemble the frames into a
// GIF with ffmpeg (see tool/make_gif.sh).
//
// Run with:
//   flutter run -d macos -t lib/demo_capture.dart
//
// Frames land in /tmp/tactile_gif_frames/; the app exits when capture finishes.
// Writing to /tmp requires the macOS sandbox to be off, so before capturing set
// `com.apple.security.app-sandbox` to <false/> in
// macos/Runner/DebugProfile.entitlements (revert it afterwards). Then assemble
// the GIF with `tool/make_gif.sh`.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tactile/tactile.dart';

const _frameDir = '/tmp/tactile_gif_frames';
const _sweepFrames = 96; // frames spent tracing the finger path
const _releaseFrames = 20; // frames spent watching the spring-back
const _pixelRatio = 2.0;
const _pointerId = 7;

void main() => runApp(const _CaptureApp());

class _CaptureApp extends StatelessWidget {
  const _CaptureApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _CaptureStage(),
    );
  }
}

class _CaptureStage extends StatefulWidget {
  const _CaptureStage();

  @override
  State<_CaptureStage> createState() => _CaptureStageState();
}

class _CaptureStageState extends State<_CaptureStage> {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _heroKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _dispatch(PointerEvent event) =>
      GestureBinding.instance.handlePointerEvent(event);

  Future<void> _capture(RenderRepaintBoundary boundary, int index) async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return;
    final name = index.toString().padLeft(4, '0');
    await File(
      '$_frameDir/frame_$name.png',
    ).writeAsBytes(data.buffer.asUint8List());
  }

  Future<void> _run() async {
    Directory(_frameDir).createSync(recursive: true);

    await WidgetsBinding.instance.endOfFrame;
    final canvas =
        _canvasKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final hero = _heroKey.currentContext!.findRenderObject()! as RenderBox;
    final viewId = View.of(_heroKey.currentContext!).viewId;

    final heroOrigin = hero.localToGlobal(Offset.zero);
    final heroCenter =
        heroOrigin + Offset(hero.size.width / 2, hero.size.height / 2);
    final rx = hero.size.width * 0.34;
    final ry = hero.size.height * 0.34;

    // Diagnostic: confirm a hit-test at the hero center actually lands on
    // something (the Listener inside Tactile). Empty => events would be lost.
    final hitTest = HitTestResult();
    GestureBinding.instance.hitTestInView(hitTest, heroCenter, viewId);
    stdout.writeln(
      'HITTEST viewId=$viewId path=${hitTest.path.length} '
      'center=$heroCenter',
    );

    Offset pointAt(double t) {
      // A figure-eight (Lissajous) sweep — keeps the finger inside the bounds
      // while exercising every tilt direction and corner of the glare.
      final a = t * 2 * math.pi;
      return heroCenter + Offset(math.sin(a) * rx, math.sin(a * 2) * ry);
    }

    // Press in, then trace the path while held.
    _dispatch(PointerAddedEvent(viewId: viewId, position: pointAt(0)));
    _dispatch(
      PointerDownEvent(
        viewId: viewId,
        pointer: _pointerId,
        position: pointAt(0),
      ),
    );
    for (var i = 0; i < _sweepFrames; i++) {
      final pos = pointAt(i / _sweepFrames);
      _dispatch(
        PointerMoveEvent(viewId: viewId, pointer: _pointerId, position: pos),
      );
      setState(() {}); // guarantee a frame is scheduled
      await WidgetsBinding.instance.endOfFrame;
      await _capture(canvas, i);
    }

    // Release and watch it spring back.
    _dispatch(
      PointerUpEvent(viewId: viewId, pointer: _pointerId, position: pointAt(1)),
    );
    for (var j = 0; j < _releaseFrames; j++) {
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      await _capture(canvas, _sweepFrames + j);
    }

    stdout.writeln(
      'CAPTURE_DONE ${_sweepFrames + _releaseFrames} frames -> '
      '$_frameDir',
    );
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: RepaintBoundary(
          key: _canvasKey,
          child: Container(
            width: 520,
            height: 360,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.4),
                radius: 1.2,
                colors: [Color(0xFF1A1A22), Color(0xFF0B0B0F)],
              ),
            ),
            alignment: Alignment.center,
            child: Tactile.playful(
              borderRadius: BorderRadius.circular(32),
              child: Container(
                key: _heroKey,
                width: 240,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F5BFF), Color(0xFF49C6E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7F5BFF).withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'tactile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
