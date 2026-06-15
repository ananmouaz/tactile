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
library;

export 'src/components.dart';
export 'src/tactile.dart';
