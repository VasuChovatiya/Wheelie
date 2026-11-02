# Architecture

## Repo layout

```
Wheelie/
├── Package.swift                  # Swift package: library "Wheelie" (iOS 15+, Swift 6)
├── Sources/Wheelie/
│   ├── Core/                      # Pure math from the spec: layout, wedgeIndexAt, pickIndex, SpinPlanner, easing
│   ├── Engine/                    # WheelController (CADisplayLink clock, spin state, events), SpinOptions
│   ├── Views/                     # WheelieView and its parts, styles and modifiers
│   └── UIKit/                     # WheelieUIView, a UIView that hosts WheelieView
├── Tests/WheelieTests/            # Spec vectors + fake-clock engine tests (Swift Testing)
│   └── Resources/test-vectors.json  -> ../../../spec/test-vectors.json (symlink)
├── examples/ios/WheelieDemo/      # SwiftUI demo app (Swift Playgrounds package) using the library
├── spec/
│   └── test-vectors.json          # Shared expected results for the core math
├── docs/
├── Screenshots/                   # README images, captured from the demo
└── scripts/check-xcsset.sh        # Malware guard, run before every commit
```

A React Native package (`react-native/`, npm `@vasuchovatiya/wheelie`) is planned and will sit next to the Swift package, implementing the same spec. See the [roadmap](roadmap.md).

## Layers

Each layer only depends on the ones above it in this list.

1. **Core:** pure functions with no UI and no clock: `layout`, `wedgeIndexAt`, `pickIndex`, `SpinPlanner.plan` (landing angle, rest angle and target rotation) and `easeOutQuart`. They are defined in [spec.md](spec.md) and checked against `spec/test-vectors.json`.
2. **Engine:** `WheelController` owns one spin at a time. It plans the spin with Core, runs the clock, works out the wedge under the pointer every frame, and emits `spinStart`, `segmentPass` and `land`. A `CADisplayLink` calls `tick(now:)`; tests call it directly with a fake clock.
3. **View:** `WheelieView` draws wedges, labels, rim, pointer and hub, and applies the rotation from the Engine. It holds no spin state. `WheelieUIView` hosts it for UIKit apps.

## Decisions

### One spec, two implementations
The Swift package and the planned React Native package implement the same core math. They stay in step through the shared spec and test vectors rather than shared code. A change to the math means changing the spec, regenerating the vectors, and updating both implementations in the same PR.

### The result comes first
`spin()` decides the winning index before anything moves, then plans a rotation that ends inside that wedge. This lets a server pick the winner, lets prize odds differ from wedge sizes, and keeps analytics and the screen in agreement. Reading the result off wherever an animation stopped is what lets the shown result and the logged result drift apart.

### One clock per spin
The rendered angle and the angle used for ticks and the result must be the same value. A `CADisplayLink` computes `angle = start + (target - start) * easeOutQuart(progress)` each frame, and the view reads that angle with no extra SwiftUI animation on top. A spring or implicit animation layered over a timer makes the view lag the logic, which is the bug this rule exists to prevent.

The display link holds a small proxy with a weak reference to the controller, so a link left running never keeps the controller alive. When the controller is gone, the proxy invalidates the link on the next frame and no `land` fires.

### Feedback is plugged in, not built in
Apps already have their own haptic and sound services, with their own mute settings and sound files. The wheel only emits events and throttles `segmentPass` (45 ms by default) so fast spins don't buzz continuously.

### Platform floor
- **Swift package: iOS 15+, Swift 6 language mode.** `WheelController` is `@MainActor`; the value types (`WheelSegment`, `SpinOptions`, `WheelResult` and the rest) are `Sendable` and `Equatable`.
- **React Native (planned): 0.76+ with `react-native-svg` 15.8+.** No Reanimated in the first version; `Animated` with the native driver is smooth enough for one rotation.

### Randomness can be injected
`WheelController(random:)` takes a `() -> Double` in `[0, 1)`, and the RN engine will take `() => number`. Tests and demo replays pass a seeded one, so spins are repeatable.

## Testing

- **Core:** the test target loads `spec/test-vectors.json` (bundled through a symlink, so there is one copy) and checks every case within the file's `tolerance`, plus the spec rule that `land.index == wedgeIndexAt(localAngle(target))` for each plan.
- **Engine:** spins run with a seeded random source and a fake clock. Tests check that the event order is `spinStart`, then `segmentPass`, then `land`; that `land.index` is the wedge under the pointer at the final angle in both modes and directions; throttling, Reduce Motion, async results, reset, and that the display link doesn't keep the controller alive.
- **View:** not yet tested. Snapshot tests of a 4-, 6- and 12-wedge wheel in both modes are planned.
