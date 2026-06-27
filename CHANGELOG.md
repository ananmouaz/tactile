## 0.3.1

- Add a funding link (Ko-fi) to the package metadata and README. No code changes.

## 0.3.0

- **Haptics.** New `TactileHaptics` (`none`/`light`/`medium`/`heavy`/`selection`)
  fired on a *confirmed* interaction only — a real tap, keyboard activation, or a
  completed long-press escalation. A press that turns into a scroll never buzzes.
  Set it via `Tactile(haptics: …)` or `TactileStyle(haptics: …)`.
- **Feel presets.** New `TactileFeel` bundles the press parameters with named
  presets — `TactileFeel.standard`, `.subtle`, `.crisp`, `.playful`, `.heavy`.
  Apply one with `Tactile.from(TactileFeel.playful, …)`. `Tactile.subtle()` and
  `Tactile.playful()` remain as shorthands.
- **Theme.** New `TactileTheme`/`TactileThemeData` (an `InheritedWidget`) set a
  default feel — and a default `TactileStyle` for the styled components — once for
  a whole subtree. Individual parameters on a widget still win over the theme.
- **Long-press escalation.** With `longPressEscalation: true`, holding deepens the
  press past its engage level and "clicks into place" — firing `onLongPress` and a
  stronger haptic when the deepening completes. Driven by the single existing press
  controller, so release still springs everything back together.
- No breaking changes: existing `Tactile`/`TactileStyle` code behaves identically.

## 0.2.0

- `Tactile` now drives its press with a custom gesture recognizer that
  participates in Flutter's gesture arena. Inside a scrollable (`ListView`,
  `PageView`, …) it yields to the scroll's drag and springs back instead of
  animating alongside it, while standalone widgets still track the finger as
  before. Taps and finger-tracking are unchanged.

## 0.1.0

Initial release.

- `Tactile` core wrapper: makes any child feel physical on touch.
  - 3D tilt toward the press point (perspective rotation).
  - Point-origin depress (shrinks toward the finger, not the center).
  - Moving specular glare clipped to the child's bounds.
  - Spring-back physics on release (`SpringSimulation`).
  - The effect tracks the finger continuously while pressed, including through
    drags; `onTap` is suppressed once a press becomes a drag.
- Presets: `Tactile.subtle()` and `Tactile.playful()`.
- Styled components built on `Tactile` that own their surface and morph their
  neumorphic shadows from extruded to flush as they're pressed:
  `TactileButton`, `TactileCard`, `TactileTile`, configured via `TactileStyle`.
- Accessibility: respects reduce-motion, exposes button semantics, supports
  keyboard activation, and disables cleanly when `enabled: false`.
- Compositor-only (transform + overlay) — no shaders, runs everywhere.
