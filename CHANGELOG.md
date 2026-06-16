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
