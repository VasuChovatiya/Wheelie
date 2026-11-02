import Foundation
import Testing
@testable import Wheelie

// MARK: - Test harness

/// Everything the controller emitted, in order, with the fake-clock time of each event.
private enum Event: Equatable {
    case start(Int)
    case pass(Int)
    case land(Int)
}

/// A controller driven by a fake clock instead of `CADisplayLink`.
@MainActor
private final class Harness {
    let controller: WheelController
    private(set) var events: [Event] = []
    private(set) var passTimes: [Double] = []
    /// For each `segmentPass`, whether its index matched the wedge under the pointer at that moment.
    private(set) var passMatchedPointer: [Bool] = []
    private(set) var now: Double = 100

    /// - Parameter randoms: Values handed out by the random source, in order, then repeated from the start.
    init(
        segments: [WheelSegment] = Array(repeating: WheelSegment(), count: 8),
        mode: WheelMode = .wheel,
        pointerAngle: Double = 0,
        options: SpinOptions = SpinOptions(),
        randoms: [Double] = [0.5],
        reduceMotion: Bool = false
    ) {
        var cursor = 0
        controller = WheelController(
            options: options,
            random: {
                defer { cursor += 1 }
                return randoms[cursor % randoms.count]
            },
            isReduceMotionEnabled: { reduceMotion },
            drivesFrames: false
        )
        controller.segments = segments
        controller.mode = mode
        controller.pointerAngle = pointerAngle
        controller.onSpinStart = { [unowned self] in self.events.append(.start($0.index)) }
        controller.onSegmentPass = { [unowned self] index in
            self.events.append(.pass(index))
            self.passTimes.append(self.now)
            self.passMatchedPointer.append(index == self.wedgeUnderPointer)
        }
        controller.onLand = { [unowned self] in self.events.append(.land($0.index)) }
    }

    /// Starts a spin through the synchronous API (async tests would otherwise pick the async overload).
    @discardableResult
    func spin(to index: Int? = nil) -> Bool {
        controller.spin(to: index)
    }

    /// Ticks at `fps` until the spin lands (or `limit` seconds pass). Returns the clock time of the landing frame.
    @discardableResult
    func runToLand(fps: Double = 60, limit: Double = 30) -> Double {
        let end = now + limit
        while controller.isSpinning && now < end {
            tick(after: 1 / fps)
        }
        return now
    }

    func tick(after seconds: Double) {
        now += seconds
        controller.tick(now: now)
    }

    /// The wedge under the pointer at the controller's current rotation.
    var wedgeUnderPointer: Int {
        wedgeIndexAt(controller.localAngle(controller.rotation), segments: controller.segments)
    }
}

@MainActor
private func startSpin(_ controller: WheelController) -> Bool {
    controller.spin(to: 1)
}

// MARK: - WheelControllerTests

@MainActor
@Suite("WheelController with a fake clock")
struct WheelControllerTests {

    // MARK: Events

    @Test(arguments: [WheelMode.wheel, .pointer], [SpinDirection.clockwise, .counterClockwise])
    func eventsArriveInOrderAndLandUnderThePointer(mode: WheelMode, direction: SpinDirection) {
        for target in 0..<8 {
            for pointerAngle in [0.0, 90, 225] {
                let options = SpinOptions(direction: direction)
                let wheel = Harness(mode: mode, pointerAngle: pointerAngle, options: options, randoms: [0.1, 0.9, 0.3])
                #expect(wheel.spin(to: target))
                wheel.runToLand()

                #expect(wheel.events.first == .start(target))
                #expect(wheel.events.last == .land(target))
                #expect(wheel.events.dropFirst().dropLast().allSatisfy { if case .pass = $0 { true } else { false } })
                #expect(wheel.controller.landedIndex == target)
                #expect(wheel.wedgeUnderPointer == target, "\(mode) \(direction) pointer \(pointerAngle)° target \(target)")
            }
        }
    }

    @Test func segmentPassReportsTheWedgeNowUnderThePointer() {
        let wheel = Harness(mode: .pointer, options: SpinOptions(turns: 4...4))
        wheel.spin(to: 5)
        wheel.runToLand(fps: 120)

        #expect(wheel.passTimes.count > 20)
        #expect(wheel.passMatchedPointer.allSatisfy { $0 })
    }

    @Test func segmentPassIsThrottledByMinTickInterval() {
        let options = SpinOptions(turns: 5...5, duration: .fixed(2), minTickInterval: 0.045)
        let wheel = Harness(segments: Array(repeating: WheelSegment(), count: 12), options: options)
        wheel.spin(to: 0)
        wheel.runToLand(fps: 1000)

        let gaps = zip(wheel.passTimes.dropFirst(), wheel.passTimes).map { $0 - $1 }
        #expect(!gaps.isEmpty)
        #expect(gaps.allSatisfy { $0 >= 0.045 - 1e-9 })
    }

    @Test func spinStartFiresOnTheFirstFrameNotOnSpin() {
        let wheel = Harness()
        wheel.spin(to: 3)
        #expect(wheel.events.isEmpty)
        wheel.tick(after: 1 / 60)
        #expect(wheel.events == [.start(3)])
        #expect(wheel.controller.rotation == 0)
    }

    // MARK: Picking

    @Test func randomSourcePicksTheWinnerByWeight() {
        // 0.6 of a total weight of 4 lands in the third wedge.
        let wheel = Harness(segments: Array(repeating: WheelSegment(), count: 4), randoms: [0.6, 0, 0.5])
        wheel.spin()
        wheel.runToLand()
        #expect(wheel.events.last == .land(2))
    }

    @Test func lockedAndZeroWeightWedgesNeverWin() {
        let segments = [
            WheelSegment(weight: 0),
            WheelSegment(isLocked: true),
            WheelSegment(weight: 1),
            WheelSegment(weight: 0),
        ]
        for r in stride(from: 0.0, to: 1, by: 0.05) {
            let wheel = Harness(segments: segments, randoms: [r])
            wheel.spin()
            wheel.runToLand()
            #expect(wheel.events.last == .land(2))
        }
    }

    @Test func spinRejectsBadTargets() {
        let wheel = Harness(segments: [WheelSegment(), WheelSegment(isLocked: true), WheelSegment()])
        #expect(!wheel.spin(to: -1))
        #expect(!wheel.spin(to: 3))
        #expect(!wheel.spin(to: 1))
        #expect(!wheel.controller.isSpinning)

        let allLocked = Harness(segments: [WheelSegment(isLocked: true), WheelSegment(weight: 0)])
        #expect(!allLocked.spin())
    }

    @Test func spinWhileSpinningIsIgnored() {
        let wheel = Harness()
        #expect(wheel.spin(to: 1))
        wheel.tick(after: 0.5)
        #expect(!wheel.spin(to: 4))
        wheel.runToLand()
        #expect(wheel.events.filter { if case .start = $0 { true } else { false } }.count == 1)
        #expect(wheel.events.last == .land(1))
    }

    // MARK: Timing and motion

    @Test func landsWhenTheDurationIsUp() {
        let wheel = Harness(options: SpinOptions(turns: 3...3, duration: .byTurns(base: 2, perTurn: 0.5)))
        wheel.spin(to: 0)
        wheel.tick(after: 0.01)
        let start = wheel.now
        let landedAt = wheel.runToLand(fps: 100)
        #expect(abs((landedAt - start) - 3.5) < 0.011)
    }

    @Test func reduceMotionShortensTheSpin() {
        let wheel = Harness(randoms: [0.5], reduceMotion: true)
        wheel.spin(to: 4)
        wheel.tick(after: 0.01)
        let start = wheel.now
        let landedAt = wheel.runToLand(fps: 100)
        #expect(abs((landedAt - start) - 0.8) < 0.011)
        // One turn plus the distance to the wedge: under two full turns.
        #expect(abs(wheel.controller.rotation) < 720)
    }

    @Test func reduceMotionCanBeIgnored() {
        let wheel = Harness(options: SpinOptions(turns: 3...3, respectsReduceMotion: false), reduceMotion: true)
        wheel.spin(to: 4)
        wheel.runToLand()
        #expect(abs(wheel.controller.rotation) >= 3 * 360)
    }

    @Test func rotationStaysContinuousBetweenSpins() {
        let wheel = Harness(options: SpinOptions(turns: 3...3))
        wheel.spin(to: 2)
        wheel.runToLand()
        let first = wheel.controller.rotation

        wheel.spin(to: 6)
        wheel.tick(after: 1 / 60) // first frame: start
        wheel.tick(after: 1 / 60)
        #expect(wheel.controller.rotation >= first)
        wheel.runToLand()
        #expect(wheel.controller.rotation - first >= 3 * 360)
        #expect(wheel.wedgeUnderPointer == 6)
    }

    @Test func counterClockwiseSpinsGoNegative() {
        let wheel = Harness(options: SpinOptions(direction: .counterClockwise))
        wheel.spin(to: 3)
        wheel.runToLand()
        #expect(wheel.controller.rotation < -3 * 360)
        #expect(wheel.wedgeUnderPointer == 3)
    }

    // MARK: Reset and async

    @Test func resetMidSpinFiresNoLand() {
        let wheel = Harness()
        wheel.spin(to: 2)
        wheel.tick(after: 0.5)
        wheel.tick(after: 0.5)
        wheel.controller.reset()
        wheel.tick(after: 10)

        #expect(!wheel.controller.isSpinning)
        #expect(wheel.controller.rotation == 0)
        #expect(wheel.controller.landedIndex == nil)
        #expect(!wheel.events.contains(.land(2)))
    }

    @Test func asyncSpinReturnsTheResult() async throws {
        let wheel = Harness(options: SpinOptions(turns: 3...3))
        let task = Task { await wheel.controller.spin(to: 5) }
        while !wheel.controller.isSpinning { await Task.yield() }

        wheel.runToLand()
        let result = try #require(await task.value)
        #expect(result.index == 5)
        #expect(result.rotation == wheel.controller.rotation)
    }

    @Test func asyncSpinReturnsNilWhenItCannotStartOrIsReset() async {
        let wheel = Harness()
        wheel.spin(to: 1)
        #expect(await wheel.controller.spin(to: 2) == nil)

        // The first spin is still running and can be reset; a waiting async spin gets nil.
        wheel.controller.reset()
        let task = Task { await wheel.controller.spin(to: 3) }
        while !wheel.controller.isSpinning { await Task.yield() }
        wheel.tick(after: 0.5)
        wheel.controller.reset()
        #expect(await task.value == nil)
    }

    // MARK: Display link

    @Test func displayLinkDoesNotKeepTheControllerAlive() async throws {
        weak var weakController: WheelController?
        var landed = false
        do {
            let controller = WheelController(options: SpinOptions(turns: 1...1, duration: .fixed(0.05)))
            controller.segments = Array(repeating: WheelSegment(), count: 4)
            controller.onLand = { _ in landed = true }
            weakController = controller
            #expect(startSpin(controller))
        }
        #expect(weakController == nil)

        // The orphaned display link must stop without firing `land`.
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(!landed)
    }
}
