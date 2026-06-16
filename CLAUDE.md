# tactile — guide for agents

`tactile` is a published Flutter package (https://pub.dev/packages/tactile) that
makes any widget feel physical on touch: it tilts toward the finger, depresses
at the press point, and a glare tracks where you press. **Compositor-only — no
shaders.** Keep it that way: every effect must stay a transform or an overlay so
it runs on any platform at full frame rate.

This file is the maintenance handoff. Read it before changing anything.

## Toolchain — always use FVM

The project is pinned to **Flutter 3.44.2 / Dart 3.12.2** via `.fvmrc`. Prefix
every command with `fvm`:

```sh
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm dart format .
```

Don't use bare `flutter`/`dart` — they resolve to the global SDK, which may
differ. To bump the pinned version: `fvm use <version>`, then re-run the verify
loop below and update the CI workflow + `pubspec.yaml` floors to match.

## Layout

```
lib/tactile.dart          # public barrel (exports only)
lib/src/tactile.dart      # the core Tactile wrapper (the headline feature)
lib/src/components.dart    # TactileButton/Card/Tile + TactileStyle (styled layer)
test/                      # widget tests
example/lib/main.dart      # the gallery (what users see)
example/lib/demo_capture*.dart  # maintainer-only GIF capture entrypoints
tool/make_gif.sh           # assembles captured frames into doc/tactile.gif
doc/tactile.gif            # README hero
```

## The verify loop (run before every commit)

```sh
fvm dart format .
fvm flutter analyze        # must be zero issues — lints are strict (see analysis_options.yaml)
fvm flutter test           # all tests must pass
```

The package targets a **160/160 pana score**. Before any release, confirm it:

```sh
fvm dart pub global run pana --no-warning .
fvm flutter pub publish --dry-run
```

## Architecture — concepts to preserve

- **Two effect classes.** (1) *Generic* effects work on any child via transform +
  overlay (tilt, point-origin depress, glare) — these live in `Tactile`.
  (2) *Surface-owned* effects need to control the background (neumorphic shadow
  morph) — these live in the styled components, which wrap `Tactile`.
- **One press-progress drives everything.** A single `AnimationController`
  (`_press`, 0→1) scales both tilt and depress, so releasing it springs them
  back together for free. Don't add parallel controllers for these.
- **`Tactile.onPressUpdate`** is the bridge: it reports `(progress, normalized)`
  so surface-owning widgets can morph their own decoration in step with the
  press. That's how `TactileButton` etc. flatten their shadows. Keep this hook
  cheap and call it only when state actually changes.
- **Finger-tracking persists through drags.** `onTap` is suppressed once a press
  passes `kTouchSlop`, but the visual keeps following the finger — that's the
  marquee feature, don't "release on drag."
- **Glare is for colored/dark surfaces.** On flat matte surfaces a white glare
  looks like a stray spotlight, so styled components default `glareIntensity` to
  0 and rely on tilt + depress + shadow-morph + recess.

## Accessibility (don't regress)

Respect `MediaQuery.disableAnimations` (drop tilt/glare, keep a quiet depress),
expose button semantics + a tap action when `onTap` is set, support keyboard
activation, and honor `enabled: false`. There are tests for these.

## Regenerating the marketing GIF

1. In `example/macos/Runner/DebugProfile.entitlements`, set
   `com.apple.security.app-sandbox` to `<false/>` (lets the app write frames to
   `/tmp`). **Revert it to `<true/>` afterward.**
2. `cd example && fvm flutter run -d macos -t lib/demo_capture.dart`
   (or `demo_capture_styled.dart`). It drives a synthetic pointer, writes PNG
   frames, and exits.
3. `tool/make_gif.sh /tmp/tactile_gif_frames doc/tactile.gif` (needs `ffmpeg`).

The capture works by injecting real pointer events via
`GestureBinding.instance.handlePointerEvent` with the correct `viewId` — see the
file for the pattern.

## Releasing a new version

1. Make the change; run the verify loop.
2. Bump `version:` in `pubspec.yaml` (semver: 0.1.x bugfix, 0.x.0 feature).
3. Add a `CHANGELOG.md` entry at the top for the new version.
4. `fvm flutter pub publish --dry-run` + pana → confirm clean / 160.
5. Commit, then `fvm flutter pub publish` (needs interactive Google auth — a
   human runs this). Published versions are **immutable**.
6. `git tag -a vX.Y.Z -m "..." && git push --tags`, then a GitHub Release.

## Commit rules

- Commit/push only when asked.
- **Author is Mouaz only — do NOT add a `Co-Authored-By: Claude` trailer.** This
  is an explicit standing request for this repo.
- `.gitignore` gotcha: gitignore does NOT support inline `#` comments — put
  comments on their own line, or the pattern silently breaks.

## Known follow-ups

- **Custom `GestureRecognizer`** so `Tactile` competes in the gesture arena and
  coexists cleanly inside scrollables (`ListView`/`PageView`) — the headline
  `0.2.0` feature. Today `Tactile` uses a passive `Listener`, so a scroll and the
  tilt animate simultaneously.
- Verify the feel on a real device at 120 Hz (simulators cap at 60).
