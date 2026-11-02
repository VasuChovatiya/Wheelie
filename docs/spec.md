# Spec

This is the contract both platforms implement. Every function here has cases in [`spec/test-vectors.json`](../spec/test-vectors.json). If this doc and the vectors disagree, the vectors win, and the doc should be fixed.

## Conventions

- Angles are in **degrees**, measured **clockwise**, with **0° at 12 o'clock**.
- `norm(x) = ((x mod 360) + 360) mod 360`, which maps any angle into `[0, 360)`.
- Rotations are not normalised. A wheel that has spun five times is at 1800°, not 0°. This keeps animation start values continuous between spins.

## Segments

A wheel has `n ≥ 1` segments. Each segment has:

| Field | Default | Meaning |
|---|---|---|
| `size` | `1` | How much of the circle it takes, relative to the other segments |
| `weight` | `1` | How likely it is to win, relative to the others. `0` means it never wins |

Size and weight are independent. A large "Try again" wedge can still be rare.

## Layout

```
span_i   = 360 * size_i / sum(size)
start_0  = -span_0 / 2              // wedge 0 is centred at 12 o'clock
start_i  = start_(i-1) + span_(i-1)
center_i = start_i + span_i / 2
```

Wedges run clockwise from wedge 0. With equal sizes, wedge `i` is centred at `i * 360 / n`.

## Which wedge is under the pointer

The **local angle** is the angle on the wheel's own artwork that the pointer is over:

| Mode | What rotates | Local angle |
|---|---|---|
| `wheel` | The wheel, by `rotation` | `norm(pointerAngle - rotation)` |
| `pointer` | The pointer, by `rotation` | `norm(pointerAngle + rotation)` |

`pointerAngle` is where the pointer sits, or where it points when at rest. It defaults to `0` (top).

`wedgeIndexAt(localAngle, sizes)`:

```
s = norm(localAngle - start_0)
return the first i where s < span_0 + ... + span_i   (fall back to n - 1)
```

An angle exactly on a boundary belongs to the clockwise wedge, the one whose `start` it is.

## Picking the winner

`pickIndex(weights, r)` with `r` in `[0, 1)`:

```
x = r * sum(weights)
walk wedges with weight > 0, adding up weights;
return the first i where x < running total   (fall back to the last wedge with weight > 0)
```

`spin(to: index)` skips this step and uses the index it is given.

## Planning the spin

1. **Where in the wedge to stop.** Stopping on the centre every time looks fake, and stopping near an edge leaves the result in doubt.

   ```
   landingAngle = center_i + offset * spread * span_i / 2
   ```

   `offset` is random in `[-1, 1]`. `spread` defaults to `0.7`, so the stop always stays at least 15% of the wedge away from either edge.

2. **What rotation puts that angle under the pointer.**

   | Mode | `restAngle` |
   |---|---|
   | `wheel` | `norm(pointerAngle - landingAngle)` |
   | `pointer` | `norm(landingAngle - pointerAngle)` |

3. **The target rotation** after at least `turns` full turns from `current`:

   ```
   clockwise:         base = current + turns * 360;  target = base + norm(restAngle - base)
   counter-clockwise: base = current - turns * 360;  target = base - norm(base - restAngle)
   ```

   This travels between `turns` and `turns + 1` turns, so the spin length stays roughly the same whichever wedge wins.

## Timing

| Option | Default | Notes |
|---|---|---|
| `turns` | random in `[3, 5]` | |
| `duration` | `3200 ms + 350 ms * turns` | Longer spins take longer, so the peak speed stays about the same |
| `easing` | `easeOutQuart(t) = 1 - (1 - t)^4` | Slows steadily and creeps to rest, with no hard stop |
| `direction` | clockwise | |
| Reduce Motion | `turns = 1`, `duration = 800 ms` | Applies when the OS setting is on, unless the app overrides it |

At each frame: `rotation = current + (target - current) * easing(elapsed / duration)`.

## Events

| Event | When | Payload |
|---|---|---|
| `spinStart` | The frame the spin begins | `{ index }`, the winner already chosen |
| `segmentPass` | `wedgeIndexAt` of the current frame differs from the last one that fired, and at least `minTickInterval` (default 45 ms) has passed since the last fired event | `{ index }`, the wedge now under the pointer |
| `land` | The frame `elapsed >= duration` | `{ index, rotation }` |

Rules:

- `land.index` must equal `wedgeIndexAt(localAngle(target))`. The test vectors check this for every plan case.
- Calling `spin()` while a spin is running does nothing and returns `false` / `null`.
- Unmounting or deallocating mid-spin stops the clock and fires no `land`.
- `segmentPass` fires when the pointer crosses a wedge **edge** (where a peg would sit), not a wedge centre.

## Test vectors

`spec/test-vectors.json` has these sections. Compare numbers within `tolerance`.

| Section | Inputs | Expected |
|---|---|---|
| `wedgeIndexAt` | `sizes`, `angle` | `index` |
| `pickIndex` | `weights`, `r` | `index` |
| `plan` | `mode`, `sizes`, `index`, `offset`, `spread`, `pointerAngle`, `current`, `turns`, `direction` | `landingAngle`, `restAngle`, `target` |
| `easeOutQuart` | `t` | `value` |

With equal sizes, `spread = 0.7`, `pointer` mode and `pointerAngle = 0`, these formulas give exactly the same results as the spinning-bottle game they were taken from. That was checked across 2 to 12 wedges before the vectors were written.
