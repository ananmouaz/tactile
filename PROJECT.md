# tactile_ui — Project Brief

> Working package name: **`tactile_ui`** (confirm availability on pub.dev before committing; alternates: `tactile`, `pressable`, `feelable`, `physical_ui`).
> Status: greenfield. This document is the full handoff — an agent should be able to build the package from it without re-researching.

## One-line pitch
A Flutter package that makes **any widget feel physical when you touch it** — it tilts toward your finger, depresses at the exact press point, and a specular highlight tracks where you're pressing. A composable wrapper first, with a few polished styled components on top.

## Why this exists (the gap)
- Researched June 2026. Flutter has neumorphism packages (`flutter_neumorphic` — abandoned; `flutter_neumorphic_plus` — maintained fork) that produce the *static* soft-extruded look.
- **No package does press-_position_-aware tactile interaction** — the visual response that follows *where and how* you touch (tilt toward finger, point-origin depress, moving glare). That interaction is the novel, defensible angle.
- **Absorption risk: low.** Flutter Material/Cupertino will not ship "physical/tactile mode." (Contrast: the iOS-26 liquid-glass idea was abandoned because Flutter is likely to absorb it, and squircles/springs already got absorbed in 3.32 / the `motor` package.)
- **Goal:** a portfolio/reputation project — visually viral (GIF-driven adoption), buildable to high quality in a few weeks by a solo dev.

## Core design decision: generic wrapper + styled components
Do **not** make this button-only. The generic wrapper is the differentiator and the thing people star.

There are **two classes of effect**, and the split drives the architecture:

1. **Generic effects — work on ANY child** (applied *around* the widget via transform + overlay; need only the child's size + local touch position):
   - **3D tilt** toward/away from the press point (perspective `Matrix4` rotation about X/Y).
   - **Point-origin depress** — scale-down/push-in centered on the touch point, not the widget center.
   - **Moving glare / specular highlight** — an overlay painted on top, tracking the finger, clipped to the child's bounds.
   - **Press ripple originating at the exact touch point** (optional).

2. **Surface-owned effects — need to control the widget's background** (a wrapper can't repaint a child's internal shadows):
   - Neumorphic **inset/extruded shadow morph** (shadows flipping to "pressed-in").
   - Background gradient that shifts with the simulated light direction.

→ **Architecture:** ship the generic `Tactile` wrapper as the headless core (effect class 1), and build opinionated styled components (`TactileButton`, `TactileCard`, `TactileTile`) on top that *own their surface* so they can add the class-2 shadow/material morph. This mirrors `flutter_animate` (`.animate()` on anything) + batteries-included examples.

## Public API (target)

### `Tactile` — the core wrapper
```dart
Tactile({
  Key? key,
  required Widget child,
  VoidCallback? onTap,
  VoidCallback? onLongPress,

  // Feel
  double tilt = 0.15,        // 0 = none; max rotation (radians-ish, normalized) toward press point
  double depress = 0.04,     // fractional scale-in at the touch point (0.04 = shrink to 96%)
  bool glare = true,         // moving specular highlight overlay
  Color glareColor = Colors.white,
  double glareIntensity = 0.35,

  // Shape (for clipping the glare/ripple to the child)
  BorderRadius borderRadius = BorderRadius.zero,

  // Physics
  Curve pressCurve = Curves.easeOut,
  Duration pressDuration = const Duration(milliseconds: 90),
  // Spring-back on release. Prefer SpringSimulation; optionally interop with the `motor` package.
  bool springBack = true,

  bool enabled = true,
})
```

Behavior:
- `onTapDown`/`onPanStart`: capture `localPosition`; read child size from the `RenderBox`.
- While pressed (`onPanUpdate`): continuously update tilt/glare to track the finger.
- On release/cancel: spring back to rest.
- `onTap` fires on tap-up within bounds (standard hit-test semantics).

### Styled components (built on `Tactile`, own their surface)
```dart
TactileButton({ required Widget child, VoidCallback? onTap, TactileStyle? style, ... })
TactileCard({ required Widget child, ... })            // tilts like a held card
TactileTile({ Widget? leading, Widget? title, ... })   // list-row press
```
`TactileStyle` carries surface props the wrapper can't infer: base color, light direction, shadow elevation/inset behavior, gradient.

## Implementation notes
- **Touch → geometry:** `GestureDetector` (or `Listener` for finer control) → `onTapDown.localPosition`; `context.findRenderObject() as RenderBox` for size. Normalize touch to [-1, 1] from center → drives tilt axes.
- **Tilt:** `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(dy * tilt)..rotateY(-dx * tilt)`, applied via `Transform(transform: ..., alignment: Alignment.center)`.
- **Point-origin depress:** `Transform.scale(scale: 1 - depress, origin: touchOffsetFromCenter)` so it shrinks toward the finger, not the middle.
- **Glare:** overlay in a `Stack` on top of `child`, clipped via `ClipRRect(borderRadius)`; paint a radial gradient centered at the touch point (`CustomPainter` or a positioned `RadialGradient` container), opacity = `glareIntensity * pressProgress`.
- **Spring-back:** drive an `AnimationController` with `SpringSimulation` on release; or depend on the `motor` package (already common in 2026) for unified spring presets — evaluate but don't hard-require.
- **Performance:** wrap effects in a `RepaintBoundary`. Tilt + glare are transform/overlay → run on the compositor, so 120fps and work on **any** child without touching its layout. **No shaders required** → unlike liquid glass, this works on Skia, web, and all desktop platforms (state this as a selling point).
- **Accessibility (must-have):**
  - Respect `MediaQuery.disableAnimations` / reduce-motion → disable tilt/glare, keep a subtle opacity/scale press only.
  - Add `Semantics(button: true, enabled: enabled)` when `onTap` is provided; forward focus & keyboard activation.
  - Handle `enabled: false` (no effects, no callbacks), pointer-cancel, and ignore multi-touch (track first pointer only).

## Scope
**In scope (v0.1, few weeks):**
- `Tactile` wrapper with tilt + point-origin depress + glare + spring-back + a11y.
- `TactileButton`, `TactileCard`, `TactileTile` styled components.
- Example app with a gallery + recordable GIF scenes (the marketing engine).
- README with GIFs, dartdoc on all public API, unit/widget tests for gesture math & a11y fallbacks.

**Out of scope (later / non-goals):**
- Full neumorphism theme system (link to `flutter_neumorphic_plus` instead).
- Pressure (force-touch) — most platforms don't expose it reliably; keep position-based.
- Heavy 3D / shader lighting. Keep it transform + overlay.

## Differentiation
- vs `flutter_neumorphic_plus`: that's a *static look* + simple pressed-state; this is *position-aware live interaction* on *any* widget.
- vs `InkWell`/`flutter_animate`: those don't do finger-tracking tilt + point-origin glare/depress.

## Suggested milestones (≈ a few weeks)
1. **Core wrapper:** gesture capture + tilt + point-origin depress. Prove on arbitrary children.
2. **Glare overlay + spring-back physics.** Tune the feel (this is the make-or-break).
3. **Styled components** (`TactileButton/Card/Tile`) with surface-owned shadow morph.
4. **Accessibility + reduce-motion fallbacks + tests.**
5. **Example app + GIF scenes + README + dartdoc + publish.**

## Success criteria
- The feel is genuinely satisfying (judged on a real device, 120fps).
- One-line wrap (`Tactile(child: ...)`) works on any widget.
- A demo GIF good enough to post on X / r/FlutterDev. Stars/adoption is the real metric.

## Risks
- **Feel is subjective** — budget real tuning time on milestone 2; ship presets (`Tactile.subtle()`, `Tactile.playful()`).
- **Name availability** on pub.dev — check first.
- Keep effects compositor-only or perf/jank will undercut the whole pitch.

## References (existing landscape, June 2026)
- `flutter_neumorphic_plus` — maintained neumorphism (static look). https://pub.dev/packages/flutter_neumorphic_plus
- `flutter_neumorphic` — abandoned original.
- Flutter Gems neumorphic list — https://fluttergems.dev/neumorphic-ui/
- `motor` — spring/curve unification (consider for spring-back). https://pub.dev/packages/motor
- Prior art on the same dev's machine: a liquid-glass comparison gallery at `~/personal/liquid_glass_gallery` (shader-based; different approach, but useful for project structure / example-app patterns).
