// Captures a TactileButton being pressed off-center, to verify the styled
// surface morph (shadow flatten + recess + tilt + depress). See demo_capture.dart
// for the capture mechanics and sandbox note.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tactile/tactile.dart';

const _frameDir = '/tmp/tactile_styled_frames';
const _pixelRatio = 2.0;
const _pointerId = 9;

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: _Stage()),
);

class _Stage extends StatefulWidget {
  const _Stage();
  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  final _canvasKey = GlobalKey();
  final _btnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _dispatch(PointerEvent e) =>
      GestureBinding.instance.handlePointerEvent(e);

  Future<void> _shot(RenderRepaintBoundary b, int i) async {
    final img = await b.toImage(pixelRatio: _pixelRatio);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (data == null) return;
    await File(
      '$_frameDir/frame_${i.toString().padLeft(4, '0')}.png',
    ).writeAsBytes(data.buffer.asUint8List());
  }

  Future<void> _run() async {
    Directory(_frameDir).createSync(recursive: true);
    await WidgetsBinding.instance.endOfFrame;
    final canvas =
        _canvasKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final btn = _btnKey.currentContext!.findRenderObject()! as RenderBox;
    final viewId = View.of(_btnKey.currentContext!).viewId;
    final origin = btn.localToGlobal(Offset.zero);
    // Press at upper-right of the button so tilt is visible alongside depress.
    final press =
        origin + Offset(btn.size.width * 0.72, btn.size.height * 0.32);

    var f = 0;
    // A few frames at rest.
    for (var i = 0; i < 8; i++, f++) {
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      await _shot(canvas, f);
    }
    // Press in and hold.
    _dispatch(PointerAddedEvent(viewId: viewId, position: press));
    _dispatch(
      PointerDownEvent(viewId: viewId, pointer: _pointerId, position: press),
    );
    for (var i = 0; i < 34; i++, f++) {
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      await _shot(canvas, f);
    }
    // Release and spring back.
    _dispatch(
      PointerUpEvent(viewId: viewId, pointer: _pointerId, position: press),
    );
    for (var i = 0; i < 26; i++, f++) {
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      await _shot(canvas, f);
    }
    stdout.writeln('CAPTURE_DONE $f frames -> $_frameDir');
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: const Color(0xFF0B0B0F),
        child: Center(
          child: RepaintBoundary(
            key: _canvasKey,
            child: Container(
              width: 460,
              height: 300,
              color: const Color(0xFFE9ECF2),
              alignment: Alignment.center,
              child: TactileButton(
                key: _btnKey,
                onTap: () {},
                child: const Text(
                  'Press me',
                  style: TextStyle(
                    color: Color(0xFF2A2D34),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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
