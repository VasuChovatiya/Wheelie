import Foundation
import QuartzCore
import UIKit // needed for UIAccessibility.isReduceMotionEnabled

// MARK: - DisplayLinkProxy

/// A lightweight proxy that breaks the retain cycle between `CADisplayLink` and `WheelController`.
/// Main-actor isolated because the display link runs on the main run loop and `tick` is main-actor.
@MainActor
private final class DisplayLinkProxy {
    weak var target: WheelController?

    init(target: WheelController) {
        self.target = target
    }

    @objc func tick(_ link: CADisplayLink) {
        // The controller was deallocated mid-spin: stop the clock so no `land` fires.
        guard let target else {
            link.invalidate()
            return
        }
        target.tick(now: link.timestamp)
    }
}

// MARK: - WheelController

/// The observable engine that drives the wheel animation.
///
/// Attach this object to a `WheelieView` via the `controller:` parameter.
/// All published properties are updated on the main actor.
@MainActor
public final class WheelController: ObservableObject {

    // MARK: Published state

    /// `true` while a spin animation is running.
    @Published public private(set) var isSpinning: Bool = false

    /// The current accumulated rotation in degrees (not normalised; may exceed 360).
    @Published public private(set) var rotation: Double = 0

    /// The index of the segment the wheel last landed on. `nil` before any spin completes.
    @Published public private(set) var landedIndex: Int?

    // MARK: Configuration (set by the view)

    /// The segments of the wheel. Set by `WheelieView` on appear / change.
    var segments: [WheelSegment] = []

    /// Whether the wheel or the pointer rotates.
    var mode: WheelMode = .wheel

    /// The angle of the fixed pointer in degrees (clockwise, 0° = 12 o'clock).
    var pointerAngle: Double = 0

    // MARK: Callbacks (set by the view via environment)

    var onSpinStart: ((WheelSpinStart) -> Void)?
    var onSegmentPass: ((Int) -> Void)?
    var onLand: ((WheelResult) -> Void)?

    // MARK: Private state

    private let options: SpinOptions
    private let random: () -> Double
    private let isReduceMotionEnabled: () -> Bool
    private let drivesFrames: Bool

    private var displayLink: CADisplayLink?
    private var proxy: DisplayLinkProxy?

    private var plan: SpinPlan?
    private var startRotation: Double = 0
    /// Clock time of the spin's first frame. `nil` until that frame arrives.
    private var spinStartTime: Double?
    private var lastTickTime: Double = 0
    private var lastTickIndex: Int = 0

    // Async continuation support
    private var continuation: CheckedContinuation<WheelResult?, Never>?

    // MARK: Init

    /// Creates a controller.
    ///
    /// - Parameters:
    ///   - options: Spin configuration.
    ///   - random: A source of random values in `[0, 1)`. Pass a seeded one for repeatable spins.
    public convenience init(
        options: SpinOptions = SpinOptions(),
        random: @escaping () -> Double = { Double.random(in: 0..<1) }
    ) {
        self.init(
            options: options,
            random: random,
            isReduceMotionEnabled: { UIAccessibility.isReduceMotionEnabled },
            drivesFrames: true
        )
    }

    /// Designated init. Tests pass `drivesFrames: false` and call `tick(now:)` with a fake clock.
    init(
        options: SpinOptions,
        random: @escaping () -> Double,
        isReduceMotionEnabled: @escaping () -> Bool,
        drivesFrames: Bool
    ) {
        self.options = options
        self.random = random
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.drivesFrames = drivesFrames
    }

    // No deinit: the display link holds the proxy, not the controller, and the proxy
    // invalidates the link on the first frame after the controller is gone.

    // MARK: - Public API

    /// Spins the wheel.
    ///
    /// - Parameter index: The segment to land on. Pass `nil` to choose randomly using weights.
    /// - Returns: `true` if the spin started, `false` if already spinning or no eligible segment.
    @discardableResult
    public func spin(to index: Int? = nil) -> Bool {
        guard !isSpinning, !segments.isEmpty else { return false }

        let effectiveOptions = resolvedOptions()

        let targetIndex: Int
        if let forced = index {
            guard forced >= 0, forced < segments.count, !segments[forced].isLocked else { return false }
            targetIndex = forced
        } else {
            let weights = segments.map { $0.isLocked ? 0.0 : $0.weight }
            guard let picked = pickIndex(weights: weights, r: random()) else { return false }
            targetIndex = picked
        }

        let turns = effectiveOptions.turns.lowerBound +
                    random() * (effectiveOptions.turns.upperBound - effectiveOptions.turns.lowerBound)

        guard let spinPlan = SpinPlanner.plan(
            targetIndex: targetIndex,
            segments: segments,
            currentRotation: rotation,
            options: effectiveOptions,
            mode: mode,
            pointerAngle: pointerAngle,
            offset: (random() * 2) - 1,
            turns: turns
        ) else { return false }

        plan = spinPlan
        startRotation = rotation
        spinStartTime = nil
        isSpinning = true
        landedIndex = nil
        lastTickIndex = wedgeIndexAt(localAngle(rotation), segments: segments)

        if drivesFrames {
            startDisplayLink()
        }
        return true
    }

    /// Spins the wheel asynchronously and returns the result when it lands.
    ///
    /// - Parameter index: The segment to land on, or `nil` for weighted random.
    /// - Returns: The `WheelResult` when the spin completes, or `nil` if the spin could not start.
    public func spin(to index: Int? = nil) async -> WheelResult? {
        return await withCheckedContinuation { cont in
            // Start the spin first so a call made while another spin is running is rejected
            // without overwriting (and orphaning) the continuation that spin is waiting on.
            guard self.spin(to: index) else {
                cont.resume(returning: nil)
                return
            }
            self.continuation = cont
        }
    }

    /// Stops any in-progress spin immediately and resets the rotation to 0.
    public func reset() {
        stopDisplayLink()
        isSpinning = false
        rotation = 0
        landedIndex = nil
        plan = nil
        spinStartTime = nil
        // Resume any waiting async continuation with nil.
        let cont = continuation
        continuation = nil
        cont?.resume(returning: nil)
    }

    // MARK: - Internal tick

    /// Advances the spin to clock time `now` (seconds). Called by `CADisplayLink` on every frame.
    func tick(now: Double) {
        guard let plan else { return }

        // First frame: start the clock here so the spin begins at progress 0.
        guard let spinStartTime else {
            spinStartTime = now
            lastTickTime = now
            onSpinStart?(WheelSpinStart(index: plan.targetIndex))
            return
        }

        let elapsed = now - spinStartTime
        let t = min(elapsed / plan.duration, 1.0)
        let easedT = easeOutQuart(t)

        rotation = startRotation + (plan.targetRotation - startRotation) * easedT

        let currentIndex = wedgeIndexAt(localAngle(rotation), segments: segments)

        // Segment pass callback (throttled by minTickInterval)
        if currentIndex != lastTickIndex {
            let interval = now - lastTickTime
            if interval >= options.minTickInterval {
                lastTickTime = now
                lastTickIndex = currentIndex
                onSegmentPass?(currentIndex)
            }
        }

        if t >= 1.0 {
            rotation = plan.targetRotation
            let result = WheelResult(index: plan.targetIndex, rotation: rotation)
            landedIndex = plan.targetIndex
            isSpinning = false
            self.plan = nil
            stopDisplayLink()
            onLand?(result)
            let cont = continuation
            continuation = nil
            cont?.resume(returning: result)
        }
    }

    // MARK: - Private helpers

    private func resolvedOptions() -> SpinOptions {
        if options.respectsReduceMotion && isReduceMotionEnabled() {
            return options.reduceMotionVariant
        }
        return options
    }

    /// The local angle that a given rotation maps to, relative to the wheel's coordinate system.
    ///
    /// In `.wheel` mode the wheel rotates, so the pointer (at `pointerAngle`) corresponds to
    /// a local angle of `pointerAngle - rotation` on the wheel surface.
    /// In `.pointer` mode the wheel is fixed and the pointer is turned by `rotation` from its
    /// rest angle, so it is over `pointerAngle + rotation`.
    func localAngle(_ rot: Double) -> Double {
        switch mode {
        case .wheel:
            return pointerAngle - rot
        case .pointer:
            return pointerAngle + rot
        }
    }

    private func startDisplayLink() {
        let newProxy = DisplayLinkProxy(target: self)
        proxy = newProxy
        let link = CADisplayLink(target: newProxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
    }
}
