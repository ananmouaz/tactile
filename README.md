# tactile

[![pub package](https://img.shields.io/pub/v/tactile.svg)](https://pub.dev/packages/tactile)
[![pub points](https://img.shields.io/pub/points/tactile)](https://pub.dev/packages/tactile/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/ananmouaz/tactile/actions/workflows/ci.yml/badge.svg)](https://github.com/ananmouaz/tactile/actions/workflows/ci.yml)
[![ko-fi](https://img.shields.io/badge/Buy%20me%20a%20coffee-ko--fi-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/ananmouaz)

**Make any Flutter widget feel physical when you touch it.** It tilts toward
your finger, depresses at the exact press point, and a specular highlight
tracks where you press.

No shaders. Compositor-only. Works on iOS, Android, web, macOS, Windows, and
Linux at full frame rate.

```dart
Tactile(
  onTap: () => print('tapped'),
  child: const FlutterLogo(size: 120),
)
```

<p align="center">
  <img src="doc/tactile.gif" alt="A card tilting toward the finger with a glare that tracks the press point" width="460">
</p>

## Why

Flutter has neumorphism packages for the *static* soft-extruded look. None of
them make interaction **press-position-aware** — the visual response that
follows *where and how* you touch. That's what `tactile` does, and it works on
**any** child, not just buttons.

## Install

```sh
flutter pub add tactile
```

Then `import 'package:tactile/tactile.dart';`.

## Usage

Wrap anything:

```dart
Tactile(
  borderRadius: BorderRadius.circular(16),
  onTap: () {},
  child: myWidget,
)
```

### Feel presets

A `TactileFeel` bundles the press parameters; named presets cover the common
cases, and `Tactile.from` applies one:

```dart
Tactile.from(TactileFeel.subtle,  child: ...)  // restrained — cards, dense UI
Tactile.from(TactileFeel.crisp,   child: ...)  // quick and snappy
Tactile.from(TactileFeel.playful, child: ...)  // exaggerated — hero buttons
Tactile.from(TactileFeel.heavy,   child: ...)  // deep, slow, with a haptic

Tactile.subtle(child: ...)   // shorthand, still supported
Tactile.playful(child: ...)
```

Start from a preset and tweak one knob — individual parameters always win:

```dart
Tactile(feel: TactileFeel.playful, tilt: 0.1, child: ...)
```

<p align="center">
  <img src="doc/presets.gif" alt="The subtle, crisp, playful, and heavy presets pressed in turn" width="420">
</p>

### Haptics

Opt into haptic feedback, fired only on a **confirmed** interaction — a real
tap, keyboard activation, or a completed long-press escalation. A press that
turns into a scroll never buzzes:

```dart
Tactile(onTap: () {}, haptics: TactileHaptics.light, child: ...)
```

`TactileHaptics` is `none` (default), `light`, `medium`, `heavy`, or
`selection`. With `longPressEscalation: true`, holding deepens the press and
fires `onLongPress` plus a stronger haptic when it clicks into place:

<p align="center">
  <img src="doc/escalation.gif" alt="A button deepening as it is held, then springing back" width="320">
</p>

### Theme

Set a default feel — and a default `TactileStyle` for the styled components —
once for a whole subtree with `TactileTheme`. Individual widgets still override
it:

```dart
TactileTheme(
  data: const TactileThemeData(feel: TactileFeel.crisp),
  child: MyApp(),
)
```

### Styled components

Batteries-included widgets built on `Tactile` that **own their surface**, so
they also morph their neumorphic shadows from extruded to flush as you press:

```dart
TactileButton(onTap: () {}, child: const Text('Press me'))

TactileCard(child: ...)               // leans like a held card

TactileTile(                          // list row
  leading: const Icon(Icons.bolt),
  title: const Text('Title'),
  subtitle: const Text('Subtitle'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {},
)
```

Pass a `TactileStyle` to control the surface (`color`, `gradient`,
`borderRadius`, `elevation`, `lightDirection`) and the feel (`tilt`, `depress`,
`glareIntensity`). Neumorphic shadows read best when `color` is close to the
surrounding background.

<p align="center">
  <img src="doc/button.gif" alt="A neumorphic button flattening as it is pressed" width="300">
  <img src="doc/tile.gif" alt="A tactile list row depressing under the finger" width="300">
</p>
<p align="center">
  <img src="doc/card.gif" alt="A glossy gradient card tilting with a glare that tracks the finger" width="360">
</p>

### Tuning

| Parameter        | Default            | What it does                                        |
| ---------------- | ------------------ | --------------------------------------------------- |
| `tilt`           | `0.15`             | Max perspective rotation toward the press point (radians). `0` disables. |
| `depress`        | `0.04`             | Fractional scale-in at the touch point. `0.04` → shrinks to 96%.         |
| `glare`          | `true`             | Moving specular highlight overlay.                  |
| `glareColor`     | `Colors.white`     | Highlight color.                                    |
| `glareIntensity` | `0.35`             | Peak glare opacity at full press.                   |
| `borderRadius`   | `BorderRadius.zero`| Clips the glare to the child's rounded shape.       |
| `springBack`     | `true`             | Release uses spring physics (vs. reversed curve).   |
| `pressCurve`     | `Curves.easeOut`   | Curve while pressing in.                             |
| `pressDuration`  | `90ms`             | Press-in duration.                                  |
| `haptics`        | `none`             | Haptic on a confirmed press: `light`/`medium`/`heavy`/`selection`. |
| `longPressEscalation` | `false`       | Hold to deepen the press; fires `onLongPress` on completion. |
| `enabled`        | `true`             | When `false`, no effects and callbacks don't fire.  |

Any of these can be left unset and supplied by a `feel:` bundle or a
`TactileTheme`; an explicit value here always wins.

## How it works

The press point drives everything — touch position is normalized to `[-1, 1]`
from the child's center, and a single press-progress value scales both the tilt
magnitude and depress depth, so release springs them back together:

- **Tilt** — a perspective `Matrix4` rotation about X/Y toward the finger.
- **Depress** — `Transform.scale` with its origin offset to the touch point, so
  the child shrinks *toward* your finger rather than its center.
- **Glare** — a radial gradient painted on top, centered at the finger and
  clipped to `borderRadius`.
- **Spring-back** — a `SpringSimulation` returns press-progress to rest on
  release, with a little overshoot.

Effects are transform + overlay only and wrapped in a `RepaintBoundary`, so they
run on the compositor and never touch the child's layout.

## Accessibility

- Respects the platform **reduce-motion** setting: tilt and glare are dropped,
  leaving only a quiet depress as the press affordance.
- Exposes **button semantics** and a tap action when `onTap` is provided.
- Supports **keyboard activation** (Enter/Space) when focused — which also
  fires the configured haptic.
- Haptics fire only on a **confirmed** interaction, so a press that becomes a
  scroll never produces stray feedback.
- `enabled: false` disables all effects and callbacks.
- Tracks a single pointer; multi-touch can't tear the effect in two directions.
- The effect follows your finger as you drag, while `onTap` is suppressed once
  the press becomes a drag (so dragging never counts as a tap).

> **Scrollables:** `Tactile` drives its press through a gesture recognizer that
> joins the gesture arena, so inside a `ListView`/`PageView` it yields to the
> scroll's drag (springing back) instead of animating alongside it. Taps and
> standalone finger-tracking are unaffected.

## Example

A gallery with recordable scenes lives in [`example/`](example/). Run it with:

```sh
cd example && flutter run
```

## Status

The core `Tactile` wrapper, the styled components (`TactileButton`,
`TactileCard`, `TactileTile`) with neumorphic shadow-morph, gesture-arena
coexistence with scrollables, feel presets (`TactileFeel`), app-wide theming
(`TactileTheme`), haptics, and long-press escalation are all in place.

## Development

This repo is pinned to a Flutter version with [FVM](https://fvm.app)
(see `.fvmrc`). With FVM installed:

```sh
fvm install              # gets the pinned Flutter version
fvm flutter pub get
fvm flutter test
fvm flutter analyze
```

(Plain `flutter` works too if your global SDK satisfies the constraints in
`pubspec.yaml`.)

## Support

If `tactile` saved you time, you can [buy me a coffee ☕](https://ko-fi.com/ananmouaz).

## License

MIT © 2026
