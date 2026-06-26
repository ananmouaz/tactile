/// Make any Flutter widget feel physical when you touch it.
///
/// Wrap any widget in [Tactile] and it tilts toward your finger, depresses at
/// the exact press point, and a specular highlight tracks where you press.
///
/// ```dart
/// Tactile(
///   onTap: () => print('tapped'),
///   child: const FlutterLogo(size: 120),
/// )
/// ```
///
/// Tune the press with a [TactileFeel] preset (`Tactile.from(TactileFeel.playful,
/// …)`), set a default feel for a subtree with a [TactileTheme], add
/// [TactileHaptics], or use the styled components ([TactileButton],
/// [TactileCard], [TactileTile]) that own their surface.
library;

export 'src/components.dart';
export 'src/tactile.dart';
