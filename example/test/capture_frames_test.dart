// Headless GIF-frame capture for every tactile capability.
//
// Unlike the `demo_capture*.dart` entrypoints (which run a real macOS window and
// stall if that window is ever occluded), this renders entirely offscreen with
// deterministic `pump()` + `RenderRepaintBoundary.toImage()` — the same path
// golden tests use. No window, no sandbox toggle, reliable in CI / unattended.
//
// Run it, then assemble each frame dir into doc/*.gif:
//   cd example && fvm flutter test test/capture_frames_test.dart
//   (from repo root, for each scene)  tool/make_gif.sh /tmp/tactile_<name>_frames doc/<gif>
//
// Frame dirs: /tmp/tactile_{hero,presets,button,escalation,card,tile}_frames.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactile/tactile.dart';

const _pr = 2.0; // capture pixel ratio
const _step = Duration(milliseconds: 16); // ~60fps frame step
const _light = Color(0xFFE9ECF2);
const _ink = Color(0xFF2A2D34);

void main() {
  testWidgets('capture all tactile scenes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 470));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Headless tests render the Ahem placeholder font (solid boxes), so load a
    // real font for legible text. Icons are avoided below for the same reason.
    final loader = FontLoader('Capture');
    for (final path in const [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    ]) {
      final f = File(path);
      if (f.existsSync()) {
        final bytes = f.readAsBytesSync();
        loader.addFont(
          Future.value(
            ByteData.view(
              bytes.buffer,
              bytes.offsetInBytes,
              bytes.lengthInBytes,
            ),
          ),
        );
      }
    }
    await loader.load();

    final canvasKey = GlobalKey();
    final heroKey = GlobalKey();
    final cardKey = GlobalKey();
    final btnKey = GlobalKey();
    final escKey = GlobalKey();
    final tileKey = GlobalKey();
    final presetKeys = List.generate(4, (_) => GlobalKey());

    var frame = 0;

    Future<void> prepDir(String dir) async {
      final d = Directory(dir)..createSync(recursive: true);
      for (final e in d.listSync()) {
        if (e is File) e.deleteSync();
      }
      frame = 0;
    }

    Future<void> cap(String dir) async {
      final boundary =
          canvasKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: _pr);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final name = frame.toString().padLeft(4, '0');
        File(
          '$dir/frame_$name.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
      });
      frame++;
    }

    Widget app(Color backdrop, Widget stage) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Capture'),
      home: Material(
        color: backdrop,
        child: Center(
          child: RepaintBoundary(key: canvasKey, child: stage),
        ),
      ),
    );

    Future<void> show(Color backdrop, Widget stage) async {
      await tester.pumpWidget(app(backdrop, stage));
      await tester.pump();
    }

    // --- drive routines ------------------------------------------------------

    Future<void> sweep(
      GlobalKey target,
      String dir, {
      int n = 96,
      int release = 18,
      double rx = 0.34,
      double ry = 0.34,
    }) async {
      await prepDir(dir);
      final r = tester.getRect(find.byKey(target));
      final c = r.center;
      Offset at(double t) {
        final a = t * 2 * math.pi;
        return c +
            Offset(math.sin(a) * r.width * rx, math.sin(a * 2) * r.height * ry);
      }

      final g = await tester.startGesture(at(0));
      for (var i = 0; i < n; i++) {
        await g.moveTo(at(i / n));
        await tester.pump(_step);
        await cap(dir);
      }
      await g.up();
      for (var i = 0; i < release; i++) {
        await tester.pump(_step);
        await cap(dir);
      }
    }

    Future<void> pressHold(
      GlobalKey target,
      String dir, {
      Offset frac = const Offset(0.5, 0.5),
      int rest = 6,
      int hold = 30,
      int release = 24,
    }) async {
      await prepDir(dir);
      final r = tester.getRect(find.byKey(target));
      final p = r.topLeft + Offset(r.width * frac.dx, r.height * frac.dy);
      for (var i = 0; i < rest; i++) {
        await tester.pump(_step);
        await cap(dir);
      }
      final g = await tester.startGesture(p);
      for (var i = 0; i < hold; i++) {
        await tester.pump(_step);
        await cap(dir);
      }
      await g.up();
      for (var i = 0; i < release; i++) {
        await tester.pump(_step);
        await cap(dir);
      }
    }

    Future<void> drivePresets(String dir) async {
      await prepDir(dir);
      for (final k in presetKeys) {
        final p = tester.getRect(find.byKey(k)).center;
        for (var i = 0; i < 2; i++) {
          await tester.pump(_step);
          await cap(dir);
        }
        final g = await tester.startGesture(p);
        for (var i = 0; i < 14; i++) {
          await tester.pump(_step);
          await cap(dir);
        }
        await g.up();
        for (var i = 0; i < 12; i++) {
          await tester.pump(_step);
          await cap(dir);
        }
      }
    }

    // --- stages --------------------------------------------------------------

    Widget darkStage(double w, double h, Widget child) => Container(
      width: w,
      height: h,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.2,
          colors: [Color(0xFF1A1A22), Color(0xFF0B0B0F)],
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );

    Widget lightStage(double w, double h, Widget child) => Container(
      width: w,
      height: h,
      color: _light,
      alignment: Alignment.center,
      child: child,
    );

    Widget swatch(String label) => Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2F45), Color(0xFF20222F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // --- scene 1: hero (tilt + glare + depress) ------------------------------
    await show(
      const Color(0xFF000000),
      darkStage(
        520,
        360,
        Tactile.playful(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            key: heroKey,
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
    );
    await sweep(heroKey, '/tmp/tactile_hero_frames');

    // --- scene 2: feel presets ----------------------------------------------
    const feels = [
      (TactileFeel.subtle, 'subtle'),
      (TactileFeel.crisp, 'crisp'),
      (TactileFeel.playful, 'playful'),
      (TactileFeel.heavy, 'heavy'),
    ];
    await show(
      const Color(0xFF000000),
      darkStage(
        580,
        220,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < feels.length; i++)
              Tactile.from(
                feels[i].$1,
                key: presetKeys[i],
                borderRadius: BorderRadius.circular(22),
                child: swatch(feels[i].$2),
              ),
          ],
        ),
      ),
    );
    await drivePresets('/tmp/tactile_presets_frames');

    // --- scene 3: styled button surface morph --------------------------------
    await show(
      _light,
      lightStage(
        460,
        300,
        TactileButton(
          key: btnKey,
          onTap: () {},
          child: const Text(
            'Press me',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
    await pressHold(
      btnKey,
      '/tmp/tactile_button_frames',
      frac: const Offset(0.72, 0.32),
      hold: 32,
    );

    // --- scene 4: long-press escalation --------------------------------------
    await show(
      _light,
      lightStage(
        460,
        300,
        TactileButton(
          key: escKey,
          onTap: () {},
          onLongPress: () {},
          style: const TactileStyle(
            longPressEscalation: true,
            depress: 0.12,
            tilt: 0.16,
            elevation: 12,
          ),
          child: const Text(
            'Hold to deepen',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
    await pressHold(
      escKey,
      '/tmp/tactile_escalation_frames',
      frac: const Offset(0.62, 0.4),
      hold: 44,
      release: 26,
    );

    // --- scene 5: glossy card glare ------------------------------------------
    await show(
      const Color(0xFF000000),
      darkStage(
        540,
        320,
        TactileCard(
          key: cardKey,
          onTap: () {},
          style: TactileStyle(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F5BFF), Color(0xFF5B7BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: const Color(0xFF5B6BFF),
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            tilt: 0.2,
            glareIntensity: 0.34,
          ),
          child: SizedBox(
            width: 300,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Glossy surface — drag to catch the light.',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await sweep(cardKey, '/tmp/tactile_card_frames', rx: 0.3, ry: 0.26);

    // --- scene 6: list rows --------------------------------------------------
    Widget tileRow(Color dot, String title, String subtitle, {Key? key}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TactileTile(
            key: key,
            onTap: () {},
            leading: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            title: Text(
              title,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6B6F78), fontSize: 13),
            ),
            trailing: const Text(
              '›',
              style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 22),
            ),
          ),
        );
    await show(
      _light,
      lightStage(
        460,
        300,
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              tileRow(
                const Color(0xFF7F5BFF),
                'Wi-Fi',
                'Home network',
                key: tileKey,
              ),
              tileRow(const Color(0xFF49C6E5), 'Bluetooth', 'On'),
              tileRow(
                const Color(0xFFFF6B6B),
                'Notifications',
                'Badges, sounds',
              ),
            ],
          ),
        ),
      ),
    );
    await pressHold(
      tileKey,
      '/tmp/tactile_tile_frames',
      frac: const Offset(0.4, 0.5),
      hold: 28,
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
