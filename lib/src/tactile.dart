import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'components.dart' show TactileStyle;

/// Haptic feedback fired on a confirmed tactile interaction.
///
/// A press that turns into a scroll never fires — feedback is fired only when
/// a press resolves as a real tap (released inside the bounds), on keyboard
/// activation, or when a long-press escalation completes.
enum TactileHaptics {
  /// No haptic feedback (the default).
  none,

  /// A light impact, via [HapticFeedback.lightImpact].
  light,

  /// A medium impact, via [HapticFeedback.mediumImpact].
  medium,

  /// A heavy impact, via [HapticFeedback.heavyImpact].
  heavy,

  /// The subtle selection click, via [HapticFeedback.selectionClick]. Good for
  /// list rows where an impact would feel heavy-handed.
  selection,
}

/// A reusable bundle of the press parameters that aren't structural, with a set
/// of named presets ([TactileFeel.subtle], [TactileFeel.crisp], …).
///
/// Pass one to [Tactile.from] or set it as the default for a subtree via a
/// [TactileTheme]. Individual parameters on [Tactile] still override whatever a
/// feel (or theme) supplies, so you can start from a preset and tweak one knob.
@immutable
class TactileFeel {
  /// Creates a feel. Defaults match [TactileFeel.standard].
  const TactileFeel({
    this.tilt = 0.15,
    this.depress = 0.04,
    this.glare = true,
    this.glareColor = const Color(0xFFFFFFFF),
    this.glareIntensity = 0.35,
    this.pressCurve = Curves.easeOut,
    this.pressDuration = const Duration(milliseconds: 90),
    this.springBack = true,
    this.haptics = TactileHaptics.none,
    this.longPressEscalation = false,
    this.escalationDuration = const Duration(milliseconds: 350),
  }) : assert(tilt >= 0, 'tilt must be non-negative'),
       assert(depress >= 0 && depress < 1, 'depress must be in [0, 1)'),
       assert(
         glareIntensity >= 0 && glareIntensity <= 1,
         'glareIntensity must be in [0, 1]',
       );

  /// Maximum tilt magnitude in radians, applied at the edge of the child.
  final double tilt;

  /// Fractional scale-in at full press, centered on the touch point.
  final double depress;

  /// Whether to paint the moving specular highlight.
  final bool glare;

  /// Color of the specular highlight.
  final Color glareColor;

  /// Peak opacity of the glare at full press, in `[0, 1]`.
  final double glareIntensity;

  /// Curve used while pressing in.
  final Curve pressCurve;

  /// Duration of the press-in animation.
  final Duration pressDuration;

  /// Whether release uses spring physics (otherwise it reverses [pressCurve]).
  final bool springBack;

  /// Haptic feedback fired on a confirmed interaction.
  final TactileHaptics haptics;

  /// When `true`, holding deepens the press past its initial engage level and
  /// "clicks into place" — firing the widget's `onLongPress` and a stronger
  /// haptic — once the deepening completes.
  final bool longPressEscalation;

  /// How long the hold-to-deepen escalation takes once engaged. Only used when
  /// [longPressEscalation] is `true`.
  final Duration escalationDuration;

  /// The default feel: a gentle lean with a soft glare.
  static const TactileFeel standard = TactileFeel();

  /// A restrained feel for cards, rows, and dense UI.
  static const TactileFeel subtle = TactileFeel(
    tilt: 0.08,
    depress: 0.02,
    glareIntensity: 0.18,
    pressDuration: Duration(milliseconds: 110),
  );

  /// A quick, snappy feel — short press, modest tilt.
  static const TactileFeel crisp = TactileFeel(
    tilt: 0.12,
    depress: 0.05,
    glareIntensity: 0.25,
    pressDuration: Duration(milliseconds: 60),
  );

  /// An exaggerated feel for hero buttons and demos.
  static const TactileFeel playful = TactileFeel(
    tilt: 0.28,
    depress: 0.07,
    glareIntensity: 0.5,
    pressDuration: Duration(milliseconds: 70),
  );

  /// A weighty feel: deep, slow press with a medium haptic.
  static const TactileFeel heavy = TactileFeel(
    tilt: 0.18,
    depress: 0.09,
    glareIntensity: 0.3,
    pressDuration: Duration(milliseconds: 130),
    haptics: TactileHaptics.medium,
  );

  /// Returns a copy with the given fields replaced. A `null` keeps the current
  /// value, so this is also how [Tactile] layers its individual parameters over
  /// a feel.
  TactileFeel copyWith({
    double? tilt,
    double? depress,
    bool? glare,
    Color? glareColor,
    double? glareIntensity,
    Curve? pressCurve,
    Duration? pressDuration,
    bool? springBack,
    TactileHaptics? haptics,
    bool? longPressEscalation,
    Duration? escalationDuration,
  }) {
    return TactileFeel(
      tilt: tilt ?? this.tilt,
      depress: depress ?? this.depress,
      glare: glare ?? this.glare,
      glareColor: glareColor ?? this.glareColor,
      glareIntensity: glareIntensity ?? this.glareIntensity,
      pressCurve: pressCurve ?? this.pressCurve,
      pressDuration: pressDuration ?? this.pressDuration,
      springBack: springBack ?? this.springBack,
      haptics: haptics ?? this.haptics,
      longPressEscalation: longPressEscalation ?? this.longPressEscalation,
      escalationDuration: escalationDuration ?? this.escalationDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TactileFeel &&
        other.tilt == tilt &&
        other.depress == depress &&
        other.glare == glare &&
        other.glareColor == glareColor &&
        other.glareIntensity == glareIntensity &&
        other.pressCurve == pressCurve &&
        other.pressDuration == pressDuration &&
        other.springBack == springBack &&
        other.haptics == haptics &&
        other.longPressEscalation == longPressEscalation &&
        other.escalationDuration == escalationDuration;
  }

  @override
  int get hashCode => Object.hash(
    tilt,
    depress,
    glare,
    glareColor,
    glareIntensity,
    pressCurve,
    pressDuration,
    springBack,
    haptics,
    longPressEscalation,
    escalationDuration,
  );
}

/// A wrapper that makes its [child] feel physical when touched.
///
/// [Tactile] applies three compositor-only effects that follow *where* you
/// press, so they work on any child without touching its layout:
///
/// * **Tilt** — the child rotates in perspective toward the press point.
/// * **Depress** — the child scales down toward the touch point (not its
///   center), as if pushed in at your fingertip.
/// * **Glare** — a soft specular highlight tracks the finger, clipped to the
///   child's bounds.
///
/// On release the effects spring back to rest. Everything runs on the
/// compositor (transforms + an overlay), so there are no shaders and it runs
/// at full frame rate on every platform Flutter supports.
///
/// ```dart
/// Tactile(
///   onTap: () => debugPrint('tapped'),
///   borderRadius: BorderRadius.circular(16),
///   child: Container(width: 160, height: 96, color: Colors.indigo),
/// )
/// ```
///
/// The press parameters come from a [TactileFeel]. Use [Tactile.from] to apply
/// a preset (`Tactile.from(TactileFeel.playful, …)`), set a default for a
/// subtree with a [TactileTheme], or pass individual parameters — which always
/// win over a feel or theme. [Tactile.subtle] and [Tactile.playful] remain as
/// shorthands.
class Tactile extends StatefulWidget {
  /// Creates a tactile wrapper around [child].
  ///
  /// Any parameter left `null` is resolved from [feel], then from an enclosing
  /// [TactileTheme], then from [TactileFeel.standard].
  const Tactile({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.feel,
    this.tilt,
    this.depress,
    this.glare,
    this.glareColor,
    this.glareIntensity,
    this.borderRadius = BorderRadius.zero,
    this.pressCurve,
    this.pressDuration,
    this.springBack,
    this.haptics,
    this.longPressEscalation,
    this.escalationDuration,
    this.enabled = true,
    this.onPressUpdate,
  }) : assert(tilt == null || tilt >= 0, 'tilt must be non-negative'),
       assert(
         depress == null || (depress >= 0 && depress < 1),
         'depress must be in [0, 1)',
       ),
       assert(
         glareIntensity == null || (glareIntensity >= 0 && glareIntensity <= 1),
         'glareIntensity must be in [0, 1]',
       );

  /// Creates a tactile wrapper whose press parameters come from [feel].
  ///
  /// ```dart
  /// Tactile.from(TactileFeel.playful, onTap: () {}, child: const FlutterLogo())
  /// ```
  const Tactile.from(
    this.feel, {
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.enabled = true,
    this.onPressUpdate,
  }) : tilt = null,
       depress = null,
       glare = null,
       glareColor = null,
       glareIntensity = null,
       pressCurve = null,
       pressDuration = null,
       springBack = null,
       haptics = null,
       longPressEscalation = null,
       escalationDuration = null;

  /// A restrained preset: small tilt and depress, soft glare.
  ///
  /// Shorthand for `Tactile.from(TactileFeel.subtle, …)`.
  const Tactile.subtle({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.glareColor,
    this.enabled = true,
  }) : feel = TactileFeel.subtle,
       tilt = null,
       depress = null,
       glare = null,
       glareIntensity = null,
       pressCurve = null,
       pressDuration = null,
       springBack = null,
       haptics = null,
       longPressEscalation = null,
       escalationDuration = null,
       onPressUpdate = null;

  /// An exaggerated preset: bigger tilt and depress, bright bouncy glare.
  ///
  /// Shorthand for `Tactile.from(TactileFeel.playful, …)`.
  const Tactile.playful({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.glareColor,
    this.enabled = true,
  }) : feel = TactileFeel.playful,
       tilt = null,
       depress = null,
       glare = null,
       glareIntensity = null,
       pressCurve = null,
       pressDuration = null,
       springBack = null,
       haptics = null,
       longPressEscalation = null,
       escalationDuration = null,
       onPressUpdate = null;

  /// The widget made tactile. Its layout is never modified.
  final Widget child;

  /// Called when a press is released inside the child's bounds.
  ///
  /// When non-null the child is exposed as a button to assistive technologies.
  final VoidCallback? onTap;

  /// Called when the child is long-pressed (or when a long-press escalation
  /// completes, if [longPressEscalation] is enabled).
  final VoidCallback? onLongPress;

  /// Press parameters to use. Any individual parameter below that is non-null
  /// overrides the matching field here. When this is also null, the feel is
  /// taken from an enclosing [TactileTheme], then [TactileFeel.standard].
  final TactileFeel? feel;

  /// Maximum tilt magnitude, in radians, applied at the edge of the child.
  ///
  /// `0` disables tilt. The resolved default of `0.15` (~8.6°) reads as a
  /// gentle lean. Overrides [feel].
  final double? tilt;

  /// Fractional scale-in at full press, centered on the touch point.
  ///
  /// `0.04` shrinks the child to 96% toward the finger. `0` disables depress.
  /// Overrides [feel].
  final double? depress;

  /// Whether to paint the moving specular highlight. Overrides [feel].
  final bool? glare;

  /// Color of the specular highlight. Overrides [feel].
  final Color? glareColor;

  /// Peak opacity of the glare at full press, in `[0, 1]`. Overrides [feel].
  final double? glareIntensity;

  /// Corner radius used to clip the glare (and to round the press surface).
  ///
  /// This is structural rather than part of a [TactileFeel], so it stays on the
  /// widget.
  final BorderRadius borderRadius;

  /// Curve used while pressing in. Overrides [feel].
  final Curve? pressCurve;

  /// Duration of the press-in animation. Overrides [feel].
  final Duration? pressDuration;

  /// Whether release uses spring physics. When `false`, release reverses
  /// [pressCurve] over [pressDuration] instead. Overrides [feel].
  final bool? springBack;

  /// Haptic feedback fired on a confirmed interaction. Overrides [feel].
  final TactileHaptics? haptics;

  /// Whether holding deepens the press and fires [onLongPress] on completion.
  /// Overrides [feel].
  final bool? longPressEscalation;

  /// How long the hold-to-deepen escalation takes. Overrides [feel].
  final Duration? escalationDuration;

  /// When `false`, no effects are shown and callbacks do not fire.
  final bool enabled;

  /// Called whenever press progress or the touch point changes, with progress
  /// in `[0, 1]` and the touch point normalized to `[-1, 1]` from the center.
  ///
  /// Lets a surface-owning widget (such as [TactileButton]) morph its own
  /// shadows in step with the press. Most callers can ignore this.
  final TactilePressCallback? onPressUpdate;

  @override
  State<Tactile> createState() => _TactileState();
}

/// Signature for [Tactile.onPressUpdate].
typedef TactilePressCallback =
    void Function(double progress, Offset normalized);

/// Press progress reached on touch-down before a hold begins escalating, when
/// [TactileFeel.longPressEscalation] is on. Holding then creeps it to 1.0.
const double _kEngageLevel = 0.6;

class _TactileState extends State<Tactile> with SingleTickerProviderStateMixin {
  /// Drives press progress in `[0, 1]`. Both the depress amount and the tilt
  /// magnitude are scaled by this, so a release that animates it back to 0
  /// also returns the tilt to flat — the spring-back falls out for free.
  late final AnimationController _press;

  /// The active pointer's local position. Drives tilt direction, depress
  /// origin, and glare center. Null while at rest.
  Offset? _local;

  /// Size of the child, captured on pointer-down from the render box.
  Size _size = Size.zero;

  /// True once the active pointer has moved far enough to count as a drag,
  /// at which point we yield to scrollables and suppress [Tactile.onTap].
  bool _dragging = false;

  /// True while a pointer is down and unresolved — guards escalation callbacks
  /// that may fire after the press was released or cancelled.
  bool _pointerDown = false;

  /// True once a hold has escalated to the deep press (fired onLongPress), so a
  /// subsequent pointer-up doesn't also fire onTap.
  bool _escalated = false;

  Offset _downPosition = Offset.zero;
  bool _focused = false;

  /// The effective feel for this build, resolved from theme + feel + the
  /// individual overrides. Recomputed in [build] and read by the press
  /// handlers, which run after at least one build.
  TactileFeel _feel = TactileFeel.standard;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: _feel.pressDuration)
      ..addListener(_onTick);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTick() {
    setState(() {});
    _notify();
  }

  void _notify() => widget.onPressUpdate?.call(_press.value, _normalized);

  bool get _effectsAllowed => widget.enabled;

  /// Resolves the feel for this widget: a [TactileTheme] (or standard) supplies
  /// the base, an explicit [Tactile.feel] replaces it, then any non-null
  /// individual parameter wins.
  TactileFeel _resolveFeel() {
    final base = TactileTheme.maybeOf(context)?.feel ?? TactileFeel.standard;
    final withFeel = widget.feel ?? base;
    return withFeel.copyWith(
      tilt: widget.tilt,
      depress: widget.depress,
      glare: widget.glare,
      glareColor: widget.glareColor,
      glareIntensity: widget.glareIntensity,
      pressCurve: widget.pressCurve,
      pressDuration: widget.pressDuration,
      springBack: widget.springBack,
      haptics: widget.haptics,
      longPressEscalation: widget.longPressEscalation,
      escalationDuration: widget.escalationDuration,
    );
  }

  void _fireHaptic(TactileHaptics haptics) {
    switch (haptics) {
      case TactileHaptics.none:
        return;
      case TactileHaptics.light:
        HapticFeedback.lightImpact();
      case TactileHaptics.medium:
        HapticFeedback.mediumImpact();
      case TactileHaptics.heavy:
        HapticFeedback.heavyImpact();
      case TactileHaptics.selection:
        HapticFeedback.selectionClick();
    }
  }

  /// The haptic for a completed escalation: stronger than the tap haptic, but
  /// only when haptics are enabled at all.
  TactileHaptics get _escalationHaptics {
    switch (_feel.haptics) {
      case TactileHaptics.none:
        return TactileHaptics.none;
      case TactileHaptics.heavy:
        return TactileHaptics.heavy;
      case TactileHaptics.light:
      case TactileHaptics.medium:
      case TactileHaptics.selection:
        return TactileHaptics.medium;
    }
  }

  // --- Press handling (driven by the arena recognizer) -----------------------

  /// The Tactile's render box, or null if not laid out.
  RenderBox? get _box {
    final object = context.findRenderObject();
    return object is RenderBox && object.hasSize ? object : null;
  }

  void _onPressStart(Offset globalPosition) {
    if (!_effectsAllowed) return;
    final box = _box;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    _dragging = false;
    _escalated = false;
    _pointerDown = true;
    _downPosition = local;
    setState(() {
      _size = box.size;
      _local = local;
    });
    if (_feel.longPressEscalation) {
      // Engage quickly, then — if the finger stays down — creep deeper.
      _press
          .animateTo(
            _kEngageLevel,
            duration: _feel.pressDuration,
            curve: _feel.pressCurve,
          )
          .whenComplete(_startEscalation);
    } else {
      _press.animateTo(
        1,
        duration: _feel.pressDuration,
        curve: _feel.pressCurve,
      );
    }
  }

  void _startEscalation() {
    if (!_pointerDown || _escalated) return;
    _press
        .animateTo(1, duration: _feel.escalationDuration, curve: Curves.easeIn)
        .whenComplete(_onEscalationComplete);
  }

  void _onEscalationComplete() {
    // Only fire if the deep press was actually reached (not interrupted by a
    // release that cancelled the animation).
    if (!_pointerDown || _escalated || _press.value < 0.999) return;
    _escalated = true;
    _fireHaptic(_escalationHaptics);
    widget.onLongPress?.call();
  }

  void _onPressMove(Offset globalPosition) {
    final box = _box;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    if (!_dragging && (local - _downPosition).distance > kTouchSlop) {
      // Moved far enough to count as a drag rather than a tap: keep tracking
      // the finger (that's the whole effect), but suppress onTap on release.
      _dragging = true;
    }
    setState(() => _local = local);
    _notify();
  }

  void _onPressEnd(Offset globalPosition) {
    final wasDrag = _dragging;
    final wasEscalated = _escalated;
    _pointerDown = false;
    final local = _box?.globalToLocal(globalPosition);
    _release();
    if (!wasDrag && !wasEscalated && local != null && _isInside(local)) {
      // A real tap: escalation already handled its own callback + haptic.
      _fireHaptic(_feel.haptics);
      widget.onTap?.call();
    }
  }

  /// Called when another recognizer wins the arena (most importantly a
  /// [Scrollable]'s drag) or the gesture is cancelled: yield by springing back
  /// without firing onTap, so the scroll takes over cleanly.
  void _onPressCancel() {
    _pointerDown = false;
    _release();
  }

  bool _isInside(Offset position) =>
      position.dx >= 0 &&
      position.dy >= 0 &&
      position.dx <= _size.width &&
      position.dy <= _size.height;

  void _release() {
    _dragging = false;
    _pointerDown = false;
    if (_feel.springBack) {
      // Spring the press progress back to rest. Tilt and depress are both
      // scaled by this value, so they ease back together with a little
      // overshoot for a physical feel.
      const spring = SpringDescription(mass: 1, stiffness: 380, damping: 22);
      _press.animateWith(
        SpringSimulation(spring, _press.value, 0, -_press.velocity),
      );
    } else {
      _press.animateBack(
        0,
        duration: _feel.pressDuration,
        curve: _feel.pressCurve,
      );
    }
  }

  // --- Keyboard / focus ------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onTap == null || !_effectsAllowed) {
      return KeyEventResult.ignored;
    }
    final isActivate =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space;
    if (!isActivate) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      // Pulse from the center for keyboard activation.
      _size = (context.findRenderObject() as RenderBox?)?.size ?? _size;
      setState(() => _local = _size.center(Offset.zero));
      _press.forward(from: 0).whenComplete(_release);
      _fireHaptic(_feel.haptics);
      widget.onTap!.call();
    }
    return KeyEventResult.handled;
  }

  // --- Geometry --------------------------------------------------------------

  /// Touch position normalized to `[-1, 1]` from the child's center.
  Offset get _normalized {
    if (_local == null || _size.isEmpty) return Offset.zero;
    final nx = (_local!.dx / _size.width) * 2 - 1;
    final ny = (_local!.dy / _size.height) * 2 - 1;
    return Offset(nx.clamp(-1.0, 1.0), ny.clamp(-1.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    _feel = _resolveFeel();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final progress = _press.value;

    Widget content = widget.child;

    if (_effectsAllowed && _feel.glare && !reduceMotion && _local != null) {
      content = _GlareOverlay(
        center: _local!,
        size: _size,
        color: _feel.glareColor,
        opacity: _feel.glareIntensity * progress,
        borderRadius: widget.borderRadius,
        child: content,
      );
    }

    if (_effectsAllowed && progress > 0) {
      final n = _normalized;

      // Point-origin depress: scale toward the finger by offsetting the scale
      // origin from the center to the touch point.
      if (_feel.depress > 0) {
        final origin = _local == null
            ? Offset.zero
            : _local! - _size.center(Offset.zero);
        content = Transform.scale(
          scale: 1 - _feel.depress * progress,
          origin: origin,
          child: content,
        );
      }

      // Perspective tilt toward the press point. Suppressed under reduce-motion
      // (the depress above stays as a quieter affordance).
      if (_feel.tilt > 0 && !reduceMotion) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0015) // perspective depth — enough to read as 3D
          ..rotateX(n.dy * _feel.tilt * progress)
          ..rotateY(-n.dx * _feel.tilt * progress);
        content = Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: content,
        );
      }
    }

    content = RepaintBoundary(child: content);

    if (_effectsAllowed) {
      content = RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _TactilePressRecognizer:
              GestureRecognizerFactoryWithHandlers<_TactilePressRecognizer>(
                _TactilePressRecognizer.new,
                (recognizer) {
                  recognizer
                    ..onStart = _onPressStart
                    ..onUpdate = _onPressMove
                    ..onEnd = _onPressEnd
                    ..onCancel = _onPressCancel;
                },
              ),
        },
        child: content,
      );
    }

    // When escalation is on, the long-press is driven by the press controller
    // (so the callback coincides with the deep press); otherwise use a plain
    // long-press detector.
    if (widget.onLongPress != null &&
        _effectsAllowed &&
        !_feel.longPressEscalation) {
      content = GestureDetector(
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    if (widget.onTap != null) {
      content = Focus(
        canRequestFocus: _effectsAllowed,
        onKeyEvent: _onKey,
        onFocusChange: (v) => setState(() => _focused = v),
        child: content,
      );
    }

    return Semantics(
      container: true,
      button: widget.onTap != null,
      enabled: widget.enabled,
      focused: _focused,
      onTap: _effectsAllowed ? widget.onTap : null,
      child: content,
    );
  }
}

/// Paints a radial specular highlight centered on the touch point, clipped to
/// the child's rounded bounds and composited on top of [child].
class _GlareOverlay extends StatelessWidget {
  const _GlareOverlay({
    required this.center,
    required this.size,
    required this.color,
    required this.opacity,
    required this.borderRadius,
    required this.child,
  });

  final Offset center;
  final Size size;
  final Color color;
  final double opacity;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: CustomPaint(
                painter: _GlarePainter(
                  center: center,
                  color: color,
                  opacity: opacity.clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlarePainter extends CustomPainter {
  _GlarePainter({
    required this.center,
    required this.color,
    required this.opacity,
  });

  final Offset center;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    // Radius scales with the child so the glare feels proportional.
    final radius = size.longestSide * 0.55;
    // A hot core that falls off quickly reads as a specular highlight rather
    // than a flat wash.
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: opacity * 0.45),
        color.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.35, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GlarePainter old) =>
      old.center != center || old.opacity != opacity || old.color != color;
}

/// A single-pointer press recognizer that participates in the gesture arena.
///
/// It starts the press visual immediately on touch-down and keeps reporting
/// finger movement while it stays a contender. If another recognizer wins the
/// arena — most importantly a [Scrollable]'s drag — [onCancel] fires so
/// [Tactile] yields and springs back instead of fighting the scroll. When it is
/// the sole contender (a standalone widget) it wins on pointer-up and [onEnd]
/// fires, so dragging your finger around still tilts the widget.
///
/// Positions are reported in the global coordinate space; the listener converts
/// them to local coordinates.
class _TactilePressRecognizer extends OneSequenceGestureRecognizer {
  /// Called on touch-down with the initial global position.
  ValueChanged<Offset>? onStart;

  /// Called as the pointer moves, with its global position.
  ValueChanged<Offset>? onUpdate;

  /// Called when the press is released while still a contender (a real press).
  ValueChanged<Offset>? onEnd;

  /// Called when the arena rejects this recognizer or the gesture is cancelled.
  VoidCallback? onCancel;

  int? _pointer;

  /// Once the gesture is won or lost we stop driving the visual and just wait
  /// for the pointer to lift.
  bool _resolved = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null) return; // track a single pointer only
    _pointer = event.pointer;
    _resolved = false;
    startTrackingPointer(event.pointer, event.transform);
    onStart?.call(event.position);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;

    if (_resolved) {
      if (event is PointerUpEvent || event is PointerCancelEvent) {
        stopTrackingPointer(_pointer!);
        _pointer = null;
      }
      return;
    }

    if (event is PointerMoveEvent) {
      onUpdate?.call(event.position);
    } else if (event is PointerUpEvent) {
      _resolved = true;
      onEnd?.call(event.position);
      // Win the arena if no one else has (e.g. a standalone widget, or a tap
      // inside a scrollable that never became a drag).
      resolve(GestureDisposition.accepted);
      stopTrackingPointer(_pointer!);
      _pointer = null;
    } else if (event is PointerCancelEvent) {
      _resolved = true;
      onCancel?.call();
      stopTrackingPointer(_pointer!);
      _pointer = null;
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _pointer && !_resolved) {
      _resolved = true;
      onCancel?.call();
    }
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
  }

  @override
  String get debugDescription => 'tactile_press';
}

/// Configuration shared by [Tactile] widgets below a [TactileTheme]: a default
/// [feel] for `Tactile` and a default [style] for the styled components.
@immutable
class TactileThemeData {
  /// Creates a tactile theme configuration.
  const TactileThemeData({
    this.feel = TactileFeel.standard,
    this.style = const TactileStyle(),
  });

  /// Default feel for [Tactile] widgets that don't specify their own.
  final TactileFeel feel;

  /// Default surface style for [TactileButton]/[TactileCard]/[TactileTile] that
  /// don't pass a `style`.
  final TactileStyle style;

  /// Returns a copy with the given fields replaced.
  TactileThemeData copyWith({TactileFeel? feel, TactileStyle? style}) =>
      TactileThemeData(feel: feel ?? this.feel, style: style ?? this.style);

  @override
  bool operator ==(Object other) =>
      other is TactileThemeData && other.feel == feel && other.style == style;

  @override
  int get hashCode => Object.hash(feel, style);
}

/// Provides a default [TactileThemeData] to the [Tactile] widgets below it, so
/// you can set the feel (and styled-component surface) once at the app root.
///
/// ```dart
/// TactileTheme(
///   data: const TactileThemeData(feel: TactileFeel.crisp),
///   child: MyApp(),
/// )
/// ```
class TactileTheme extends InheritedWidget {
  /// Creates a tactile theme.
  const TactileTheme({super.key, required this.data, required super.child});

  /// The configuration inherited by descendants.
  final TactileThemeData data;

  /// The nearest theme data, or null if there is none.
  static TactileThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TactileTheme>()?.data;

  /// The nearest theme data, or a default [TactileThemeData] if there is none.
  static TactileThemeData of(BuildContext context) =>
      maybeOf(context) ?? const TactileThemeData();

  @override
  bool updateShouldNotify(TactileTheme oldWidget) => oldWidget.data != data;
}
