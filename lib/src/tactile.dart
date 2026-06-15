import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
/// Use [Tactile.subtle] or [Tactile.playful] for tuned presets.
class Tactile extends StatefulWidget {
  /// Creates a tactile wrapper around [child].
  const Tactile({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.tilt = 0.15,
    this.depress = 0.04,
    this.glare = true,
    this.glareColor = const Color(0xFFFFFFFF),
    this.glareIntensity = 0.35,
    this.borderRadius = BorderRadius.zero,
    this.pressCurve = Curves.easeOut,
    this.pressDuration = const Duration(milliseconds: 90),
    this.springBack = true,
    this.enabled = true,
    this.onPressUpdate,
  }) : assert(tilt >= 0, 'tilt must be non-negative'),
       assert(depress >= 0 && depress < 1, 'depress must be in [0, 1)'),
       assert(
         glareIntensity >= 0 && glareIntensity <= 1,
         'glareIntensity must be in [0, 1]',
       );

  /// A restrained preset: small tilt and depress, soft glare.
  ///
  /// Good for cards, list rows, and dense UI where a loud effect would feel
  /// gimmicky.
  const Tactile.subtle({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.glareColor = const Color(0xFFFFFFFF),
    this.enabled = true,
  }) : tilt = 0.08,
       depress = 0.02,
       glare = true,
       glareIntensity = 0.18,
       pressCurve = Curves.easeOut,
       pressDuration = const Duration(milliseconds: 110),
       springBack = true,
       onPressUpdate = null;

  /// An exaggerated preset: bigger tilt and depress, bright bouncy glare.
  ///
  /// Good for hero buttons and demo scenes.
  const Tactile.playful({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.glareColor = const Color(0xFFFFFFFF),
    this.enabled = true,
  }) : tilt = 0.28,
       depress = 0.07,
       glare = true,
       glareIntensity = 0.5,
       pressCurve = Curves.easeOut,
       pressDuration = const Duration(milliseconds: 70),
       springBack = true,
       onPressUpdate = null;

  /// The widget made tactile. Its layout is never modified.
  final Widget child;

  /// Called when a press is released inside the child's bounds.
  ///
  /// When non-null the child is exposed as a button to assistive technologies.
  final VoidCallback? onTap;

  /// Called when the child is long-pressed.
  final VoidCallback? onLongPress;

  /// Maximum tilt magnitude, in radians, applied at the edge of the child.
  ///
  /// `0` disables tilt. The default of `0.15` (~8.6°) reads as a gentle lean.
  final double tilt;

  /// Fractional scale-in at full press, centered on the touch point.
  ///
  /// `0.04` shrinks the child to 96% toward the finger. `0` disables depress.
  final double depress;

  /// Whether to paint the moving specular highlight.
  final bool glare;

  /// Color of the specular highlight.
  final Color glareColor;

  /// Peak opacity of the glare at full press, in `[0, 1]`.
  final double glareIntensity;

  /// Corner radius used to clip the glare (and to round the press surface).
  final BorderRadius borderRadius;

  /// Curve used while pressing in.
  final Curve pressCurve;

  /// Duration of the press-in animation.
  final Duration pressDuration;

  /// Whether release uses spring physics. When `false`, release reverses
  /// [pressCurve] over [pressDuration] instead.
  final bool springBack;

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

  /// The pointer we are tracking. We follow the first pointer only and ignore
  /// the rest, so multi-touch can't tear the effect in two directions.
  int? _pointer;

  /// True once the active pointer has moved far enough to count as a drag,
  /// at which point we yield to scrollables and suppress [Tactile.onTap].
  bool _dragging = false;

  Offset _downPosition = Offset.zero;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: widget.pressDuration)
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

  // --- Pointer handling ------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (!_effectsAllowed || _pointer != null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _pointer = event.pointer;
    _dragging = false;
    _downPosition = event.localPosition;
    setState(() {
      _size = box.size;
      _local = event.localPosition;
    });
    _press.animateTo(
      1,
      duration: widget.pressDuration,
      curve: widget.pressCurve,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    if (!_dragging &&
        (event.localPosition - _downPosition).distance > kTouchSlop) {
      // Moved far enough to count as a drag rather than a tap: keep tracking
      // the finger (that's the whole effect), but suppress onTap on release.
      _dragging = true;
    }
    setState(() => _local = event.localPosition);
    _notify();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final wasDrag = _dragging;
    final position = event.localPosition;
    _release();
    if (!wasDrag && _isInside(position)) {
      widget.onTap?.call();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _release();
  }

  bool _isInside(Offset position) =>
      position.dx >= 0 &&
      position.dy >= 0 &&
      position.dx <= _size.width &&
      position.dy <= _size.height;

  void _release() {
    _pointer = null;
    _dragging = false;
    if (widget.springBack) {
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
        duration: widget.pressDuration,
        curve: widget.pressCurve,
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final progress = _press.value;

    Widget content = widget.child;

    if (_effectsAllowed && widget.glare && !reduceMotion && _local != null) {
      content = _GlareOverlay(
        center: _local!,
        size: _size,
        color: widget.glareColor,
        opacity: widget.glareIntensity * progress,
        borderRadius: widget.borderRadius,
        child: content,
      );
    }

    if (_effectsAllowed && progress > 0) {
      final n = _normalized;

      // Point-origin depress: scale toward the finger by offsetting the scale
      // origin from the center to the touch point.
      if (widget.depress > 0) {
        final origin = _local == null
            ? Offset.zero
            : _local! - _size.center(Offset.zero);
        content = Transform.scale(
          scale: 1 - widget.depress * progress,
          origin: origin,
          child: content,
        );
      }

      // Perspective tilt toward the press point. Suppressed under reduce-motion
      // (the depress above stays as a quieter affordance).
      if (widget.tilt > 0 && !reduceMotion) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0015) // perspective depth — enough to read as 3D
          ..rotateX(n.dy * widget.tilt * progress)
          ..rotateY(-n.dx * widget.tilt * progress);
        content = Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: content,
        );
      }
    }

    content = RepaintBoundary(child: content);

    content = Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: content,
    );

    if (widget.onLongPress != null && _effectsAllowed) {
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
