import 'package:flutter/widgets.dart';

import 'tactile.dart';

/// Surface properties that a wrapper can't infer from an arbitrary child, used
/// by the styled components ([TactileButton], [TactileCard], [TactileTile]) to
/// paint and morph their own background.
@immutable
class TactileStyle {
  /// Creates a style describing a tactile surface.
  const TactileStyle({
    this.color = const Color(0xFFE9ECF2),
    this.gradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    this.elevation = 10,
    this.lightDirection = Alignment.topLeft,
    this.tilt = 0.16,
    this.depress = 0.08,
    this.glareColor = const Color(0xFFFFFFFF),
    this.glareIntensity = 0,
  });

  /// Base surface color. Neumorphic shadows are derived from it, so it reads
  /// best when close to the surrounding background color.
  final Color color;

  /// Optional gradient painted instead of [color] (shadows still derive from
  /// [color]).
  final Gradient? gradient;

  /// Corner radius of the surface (and the glare clip).
  final BorderRadius borderRadius;

  /// Inner padding around the content.
  final EdgeInsets padding;

  /// Resting shadow distance. Morphs to flush (0) at full press.
  final double elevation;

  /// Direction the simulated light comes from. Drives which side gets the
  /// highlight and which gets the drop shadow.
  final Alignment lightDirection;

  /// Tilt passed to the underlying [Tactile].
  final double tilt;

  /// Depress passed to the underlying [Tactile].
  final double depress;

  /// Glare color passed to the underlying [Tactile].
  final Color glareColor;

  /// Glare intensity passed to the underlying [Tactile]. Defaults to `0`:
  /// a moving specular highlight looks out of place on a flat, matte
  /// neumorphic surface, but reads well on a colored or gradient surface, so
  /// raise it (e.g. `0.3`) when you give the style a [gradient].
  final double glareIntensity;

  /// Returns a copy with the given fields replaced.
  TactileStyle copyWith({
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    double? elevation,
    Alignment? lightDirection,
    double? tilt,
    double? depress,
    Color? glareColor,
    double? glareIntensity,
  }) {
    return TactileStyle(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      elevation: elevation ?? this.elevation,
      lightDirection: lightDirection ?? this.lightDirection,
      tilt: tilt ?? this.tilt,
      depress: depress ?? this.depress,
      glareColor: glareColor ?? this.glareColor,
      glareIntensity: glareIntensity ?? this.glareIntensity,
    );
  }
}

/// A tactile, neumorphic button. Tilts and depresses toward the finger while
/// its extruded shadows flatten as it's pressed in.
class TactileButton extends StatelessWidget {
  /// Creates a tactile button.
  const TactileButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.style,
    this.enabled = true,
  });

  /// The button's content (usually a [Text] or an [Icon]).
  final Widget child;

  /// Called when the button is tapped.
  final VoidCallback? onTap;

  /// Called when the button is long-pressed.
  final VoidCallback? onLongPress;

  /// Surface style. Defaults to a neutral neumorphic surface.
  final TactileStyle? style;

  /// When `false`, the button is inert and shows no effects.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _TactileSurface(
      style: style ?? const TactileStyle(),
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}

/// A tactile card that leans toward the finger like a physical card you're
/// holding. Larger radius and tilt than [TactileButton].
class TactileCard extends StatelessWidget {
  /// Creates a tactile card.
  const TactileCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.style,
    this.enabled = true,
  });

  /// The card's content.
  final Widget child;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the card is long-pressed.
  final VoidCallback? onLongPress;

  /// Surface style. Defaults to a roomy, gently lit card surface.
  final TactileStyle? style;

  /// When `false`, the card is inert and shows no effects.
  final bool enabled;

  static const TactileStyle _defaults = TactileStyle(
    borderRadius: BorderRadius.all(Radius.circular(24)),
    padding: EdgeInsets.all(20),
    elevation: 14,
    tilt: 0.22,
    depress: 0.06,
  );

  @override
  Widget build(BuildContext context) {
    return _TactileSurface(
      style: style ?? _defaults,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      child: child,
    );
  }
}

/// A tactile list row with optional [leading]/[trailing] widgets and a
/// [title]/[subtitle]. Uses a restrained press suited to dense lists.
class TactileTile extends StatelessWidget {
  /// Creates a tactile list tile.
  const TactileTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.style,
    this.enabled = true,
  });

  /// Widget shown before the text (e.g. an icon or avatar).
  final Widget? leading;

  /// Primary text widget.
  final Widget? title;

  /// Secondary text widget shown under [title].
  final Widget? subtitle;

  /// Widget shown after the text (e.g. a chevron).
  final Widget? trailing;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// Surface style. Defaults to a flat, low-elevation row.
  final TactileStyle? style;

  /// When `false`, the tile is inert and shows no effects.
  final bool enabled;

  static const TactileStyle _defaults = TactileStyle(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    elevation: 8,
    tilt: 0.12,
    depress: 0.05,
  );

  @override
  Widget build(BuildContext context) {
    return _TactileSurface(
      style: style ?? _defaults,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?title,
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 14), trailing!],
        ],
      ),
    );
  }
}

/// Shared implementation: wraps content in a [Tactile] and paints a neumorphic
/// surface that flattens as press progress rises.
class _TactileSurface extends StatefulWidget {
  const _TactileSurface({
    required this.style,
    required this.child,
    required this.enabled,
    this.onTap,
    this.onLongPress,
  });

  final TactileStyle style;
  final Widget child;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<_TactileSurface> createState() => _TactileSurfaceState();
}

class _TactileSurfaceState extends State<_TactileSurface> {
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final p = widget.enabled ? _progress : 0.0;
    return Tactile(
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      enabled: widget.enabled,
      tilt: s.tilt,
      depress: s.depress,
      glare: s.glareIntensity > 0,
      glareColor: s.glareColor,
      glareIntensity: s.glareIntensity,
      borderRadius: s.borderRadius,
      onPressUpdate: (progress, _) {
        if (progress != _progress) setState(() => _progress = progress);
      },
      child: DecoratedBox(
        decoration: _surfaceDecoration(s, p),
        child: DecoratedBox(
          // Painted over the content: a recess that deepens with the press,
          // the strongest "pushed in" cue on flat/light surfaces where a white
          // glare barely shows.
          position: DecorationPosition.foreground,
          decoration: _pressedRecess(s, p),
          child: Padding(padding: s.padding, child: widget.child),
        ),
      ),
    );
  }
}

BoxDecoration _surfaceDecoration(TactileStyle s, double progress) {
  final extrude = 1 - progress;
  final dir = Offset(s.lightDirection.x, s.lightDirection.y);
  final dist = s.elevation * extrude;
  final blur = s.elevation * 1.7 * extrude;

  // Pressing in nudges the surface darker, reinforcing the "pushed into the
  // material" read.
  final surface = Color.lerp(s.color, _shade(s.color, -0.1), progress)!;

  return BoxDecoration(
    color: s.gradient == null ? surface : null,
    gradient: s.gradient,
    borderRadius: s.borderRadius,
    boxShadow: [
      // Drop shadow on the side away from the light.
      BoxShadow(
        color: _shade(s.color, -0.5).withValues(alpha: 0.6 * extrude),
        offset: -dir * dist,
        blurRadius: blur,
      ),
      // Highlight on the side facing the light.
      BoxShadow(
        color: _shade(s.color, 0.6).withValues(alpha: 0.85 * extrude),
        offset: dir * dist,
        blurRadius: blur,
      ),
    ],
  );
}

/// A soft inner vignette that darkens the edges as the press deepens, faking an
/// inset shadow (Flutter has no inset `BoxShadow`). Transparent in the middle
/// so it doesn't dim the content.
BoxDecoration _pressedRecess(TactileStyle s, double progress) {
  if (progress <= 0.01) return const BoxDecoration();
  return BoxDecoration(
    borderRadius: s.borderRadius,
    gradient: RadialGradient(
      radius: 0.9,
      colors: [
        const Color(0x00000000),
        _shade(s.color, -0.4).withValues(alpha: 0.22 * progress),
      ],
      stops: const [0.5, 1.0],
    ),
  );
}

/// Shifts a color's lightness by [amount] in `[-1, 1]`.
Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}
