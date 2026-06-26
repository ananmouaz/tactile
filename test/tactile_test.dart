import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactile/tactile.dart';

void main() {
  Widget boxApp({
    VoidCallback? onTap,
    bool enabled = true,
    bool disableAnimations = false,
    Tactile? tactile,
  }) {
    final child =
        tactile ??
        Tactile(
          onTap: onTap,
          enabled: enabled,
          child: const SizedBox(width: 200, height: 100),
        );
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );
  }

  // Captures haptic calls on the platform channel for the duration of a test.
  List<MethodCall> trackHaptics(WidgetTester tester) {
    final calls = <MethodCall>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    return calls;
  }

  List<Object?> hapticArgs(List<MethodCall> calls) => calls
      .where((c) => c.method == 'HapticFeedback.vibrate')
      .map((c) => c.arguments)
      .toList();

  testWidgets('fires onTap when released inside bounds', (tester) async {
    var taps = 0;
    await tester.pumpWidget(boxApp(onTap: () => taps++));

    await tester.tap(find.byType(Tactile));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('does not fire onTap when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(boxApp(onTap: () => taps++, enabled: false));

    await tester.tap(find.byType(Tactile));
    await tester.pumpAndSettle();

    expect(taps, 0);
  });

  testWidgets('applies a transform while pressed and reverts on release', (
    tester,
  ) async {
    await tester.pumpWidget(boxApp(onTap: () {}));

    Matrix4? transformDuringPress() {
      final transforms = tester
          .widgetList<Transform>(find.byType(Transform))
          .toList();
      return transforms.isEmpty ? null : transforms.first.transform;
    }

    // At rest: no Transform from Tactile.
    expect(find.byType(Transform), findsNothing);

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byType(Tactile)) + const Offset(20, 20),
    );
    await tester.pump(); // establish the ticker start time
    await tester.pump(const Duration(milliseconds: 60)); // advance the press

    // Pressed: a transform is applied.
    expect(transformDuringPress(), isNotNull);

    await gesture.up();
    await tester.pumpAndSettle();

    // Released: spring-back returns to rest, transform removed.
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('exposes button semantics only when onTap is provided', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    // With onTap: exposes a tappable button to assistive technologies.
    await tester.pumpWidget(boxApp(onTap: () {}));
    final withTap = tester
        .getSemantics(find.byType(Tactile))
        .getSemanticsData();
    expect(withTap.hasAction(SemanticsAction.tap), isTrue);

    // Without onTap: no tap action is advertised.
    await tester.pumpWidget(boxApp());
    final withoutTap = tester
        .getSemantics(find.byType(Tactile))
        .getSemanticsData();
    expect(withoutTap.hasAction(SemanticsAction.tap), isFalse);

    handle.dispose();
  });

  testWidgets('suppresses tilt under reduce-motion but keeps depress', (
    tester,
  ) async {
    await tester.pumpWidget(
      boxApp(
        disableAnimations: true,
        tactile: const Tactile(
          tilt: 0.3,
          depress: 0.05,
          child: SizedBox(width: 200, height: 100),
        ),
      ),
    );

    await tester.startGesture(tester.getCenter(find.byType(Tactile)));
    await tester.pump(); // establish the ticker start time
    await tester.pump(const Duration(milliseconds: 60)); // advance the press

    // Only the depress Transform.scale should be present — no perspective tilt.
    final transforms = tester
        .widgetList<Transform>(find.byType(Transform))
        .toList();
    expect(transforms.length, 1);
    // A pure scale matrix has no perspective entry at (3, 2).
    expect(transforms.first.transform.entry(3, 2), 0);
  });

  testWidgets('presets construct without error', (tester) async {
    await tester.pumpWidget(
      boxApp(
        tactile: const Tactile.subtle(child: SizedBox(width: 100, height: 100)),
      ),
    );
    expect(find.byType(Tactile), findsOneWidget);

    await tester.pumpWidget(
      boxApp(
        tactile: const Tactile.playful(
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );
    expect(find.byType(Tactile), findsOneWidget);
  });

  testWidgets('a drag keeps the effect but suppresses onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(boxApp(onTap: () => taps++));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Tactile)),
    );
    await tester.pump(); // establish ticker
    await tester.pump(const Duration(milliseconds: 40));
    // Drag past the touch slop but stay within bounds.
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();

    // Still pressed/tilting while the finger is down.
    expect(find.byType(Transform), findsWidgets);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, 0); // a drag is not a tap
    expect(find.byType(Transform), findsNothing); // released
  });

  testWidgets('yields to a scrolling ListView instead of blocking it', (
    tester,
  ) async {
    var taps = 0;
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              Tactile(
                onTap: () => taps++,
                child: const SizedBox(
                  height: 120,
                  child: Center(child: Text('row')),
                ),
              ),
              for (var i = 0; i < 30; i++)
                SizedBox(height: 120, child: Text('item $i')),
            ],
          ),
        ),
      ),
    );

    expect(controller.offset, 0);

    // Fling upward starting on the tactile row — the scroll should win.
    await tester.fling(find.text('row'), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0)); // the list scrolled
    expect(taps, 0); // the drag did not register as a tap
  });

  testWidgets('a tap inside a ListView still fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              Tactile(
                onTap: () => taps++,
                child: const SizedBox(
                  height: 120,
                  child: Center(child: Text('row')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('row'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('fires the configured haptic on a confirmed tap', (tester) async {
    final calls = trackHaptics(tester);
    await tester.pumpWidget(
      boxApp(
        tactile: Tactile(
          onTap: () {},
          haptics: TactileHaptics.light,
          child: const SizedBox(width: 200, height: 100),
        ),
      ),
    );

    await tester.tap(find.byType(Tactile));
    await tester.pumpAndSettle();

    expect(hapticArgs(calls), ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('does not fire a haptic when the press becomes a drag', (
    tester,
  ) async {
    final calls = trackHaptics(tester);
    await tester.pumpWidget(
      boxApp(
        tactile: Tactile(
          onTap: () {},
          haptics: TactileHaptics.medium,
          child: const SizedBox(width: 200, height: 100),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Tactile)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.moveBy(const Offset(60, 0)); // past the touch slop → a drag
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(hapticArgs(calls), isEmpty);
  });

  testWidgets('does not fire a haptic when haptics is none', (tester) async {
    final calls = trackHaptics(tester);
    await tester.pumpWidget(boxApp(onTap: () {})); // default haptics: none

    await tester.tap(find.byType(Tactile));
    await tester.pumpAndSettle();

    expect(hapticArgs(calls), isEmpty);
  });

  testWidgets(
    'long-press escalation deepens, then fires onLongPress + a stronger haptic',
    (tester) async {
      final calls = trackHaptics(tester);
      var longPresses = 0;
      var progress = 0.0;
      await tester.pumpWidget(
        boxApp(
          tactile: Tactile(
            onLongPress: () => longPresses++,
            haptics: TactileHaptics.light,
            onPressUpdate: (p, _) => progress = p,
            feel: const TactileFeel(
              longPressEscalation: true,
              escalationDuration: Duration(milliseconds: 200),
            ),
            child: const SizedBox(width: 200, height: 100),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Tactile)),
      );
      await tester.pump(); // establish ticker
      await tester.pump(const Duration(milliseconds: 120)); // engage completes

      final engaged = progress;
      expect(engaged, greaterThan(0.4));
      expect(engaged, lessThan(0.8)); // engaged, not yet escalated
      expect(longPresses, 0);

      await tester.pump(const Duration(milliseconds: 260)); // creep completes

      expect(progress, greaterThan(engaged)); // deepened past engage
      expect(longPresses, 1);
      expect(hapticArgs(calls), ['HapticFeedbackType.mediumImpact']);

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Tactile.from builds with a preset feel', (tester) async {
    await tester.pumpWidget(
      boxApp(
        tactile: const Tactile.from(
          TactileFeel.playful,
          child: SizedBox(width: 200, height: 100),
        ),
      ),
    );
    expect(find.byType(Tactile), findsOneWidget);
  });

  test('TactileFeel presets, copyWith, and equality', () {
    expect(TactileFeel.standard, const TactileFeel());
    expect(TactileFeel.subtle == TactileFeel.playful, isFalse);
    expect(TactileFeel.subtle.copyWith(tilt: 0.5).tilt, 0.5);
    expect(
      const TactileFeel(tilt: 0.1).hashCode,
      const TactileFeel(tilt: 0.1).hashCode,
    );
  });

  testWidgets('Tactile inherits its feel from an enclosing TactileTheme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TactileTheme(
            // An all-off feel: a press should produce no visual transform.
            data: const TactileThemeData(
              feel: TactileFeel(tilt: 0, depress: 0, glare: false),
            ),
            child: Center(
              child: Tactile(
                onTap: () {},
                child: const SizedBox(width: 200, height: 100),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.startGesture(tester.getCenter(find.byType(Tactile)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Standard defaults would tilt; the theme's all-off feel was used instead.
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('an explicit parameter overrides the theme feel', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TactileTheme(
            data: const TactileThemeData(
              feel: TactileFeel(tilt: 0, depress: 0, glare: false),
            ),
            child: Center(
              child: Tactile(
                onTap: () {},
                tilt: 0.3, // overrides the theme's tilt: 0
                child: const SizedBox(width: 200, height: 100),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.startGesture(tester.getCenter(find.byType(Tactile)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byType(Transform), findsWidgets);
  });
}
