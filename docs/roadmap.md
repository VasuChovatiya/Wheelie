# Roadmap

## v0.1: Swift package (done)

- `Wheelie` Swift package (iOS 15+, Swift 6) with every function in the [spec](spec.md), passing all 151 cases in `spec/test-vectors.json`.
- `WheelController` on `CADisplayLink`, with `.wheel` and `.pointer` modes, the result-first `spin(to:)`, an async `spin(to:)`, events, Reduce Motion, and an injectable random source.
- `WheelieView` with custom wedge content, colours, rim, the default pointer and hub, `wheelPointer`, `wheelHub`, and the highlight (dim, outline, pulse). `WheelieUIView` for UIKit.
- Engine tests on a fake clock.
- SwiftUI demo app (`examples/ios/WheelieDemo`): prize wheel, spin the bottle, and a playground.
- CI: SwiftLint `--strict`, tests on a simulator, a demo build, and a malware check.

**Done when:** a spinning-bottle game and a prize wheel both run on it with no game-specific code inside the library. ✓

## v0.2: React Native core

- `core.ts` with every function in the spec, passing `spec/test-vectors.json` in Jest.
- `useWheelie` with `wheel` and `pointer` modes, the result-first `spin(to?)`, events, Reduce Motion, and an injectable random source.
- `<Wheelie>` with labels, colours, ring, the default pointer, `renderPointer`, `renderHub`, and the highlight (dim, outline, pulse).
- Example app, and CI (lint, type check, tests, malware check).

**Done when:** the same prize wheel and bottle game run on React Native and land on the same wedges as iOS for the same seeded spins.

## v0.3: Feel

- Flick to spin, with the swipe speed setting spin strength, and drag to wind up.
- A flapper pointer that bends as it passes each peg.
- Rims with pegs, and bulbs that chase around the edge.
- Curved labels along the arc.
- Locked wedges with a lock icon.
- Elimination mode: the winning wedge animates out and the rest close the gap.
- Snapshot tests of the rendered wheel.

## Later

- Tagged releases on SPM and npm.
- An optional Reanimated adapter (`useWheelieReanimated`) for apps that already use it.
- An optional confetti burst on land.
- A check that it renders correctly on Android (fonts and SVG text baseline).
