import Foundation
import Testing
@testable import Wheelie

// MARK: - Shared vectors

/// `spec/test-vectors.json`, decoded. The React Native package checks the same file.
struct SpecVectors: Decodable, Sendable {
    struct WedgeCase: Decodable, Sendable, CustomTestStringConvertible {
        let sizes: [Double]
        let angle: Double
        let index: Int
        var testDescription: String { "sizes \(sizes) at \(angle)° → \(index)" }
    }

    struct PickCase: Decodable, Sendable, CustomTestStringConvertible {
        let weights: [Double]
        let r: Double
        let index: Int?
        var testDescription: String { "weights \(weights), r \(r) → \(index.map(String.init) ?? "nil")" }
    }

    struct PlanCase: Decodable, Sendable, CustomTestStringConvertible {
        let mode: String
        let sizes: [Double]
        let index: Int
        let offset: Double
        let spread: Double
        let pointerAngle: Double
        let current: Double
        let turns: Double
        let direction: String
        let landingAngle: Double
        let restAngle: Double
        let target: Double
        var testDescription: String { "\(mode) \(direction), \(sizes.count) wedges → \(index)" }
    }

    struct EaseCase: Decodable, Sendable, CustomTestStringConvertible {
        let t: Double
        let value: Double
        var testDescription: String { "t \(t)" }
    }

    let version: Int
    let tolerance: Double
    let wedgeIndexAt: [WedgeCase]
    let pickIndex: [PickCase]
    let plan: [PlanCase]
    let easeOutQuart: [EaseCase]

    static func load() throws -> SpecVectors {
        // Bundled from Resources/test-vectors.json, a symlink to spec/test-vectors.json.
        let url = try #require(Bundle.module.url(forResource: "test-vectors", withExtension: "json"))
        return try JSONDecoder().decode(SpecVectors.self, from: Data(contentsOf: url))
    }

    static let tolerance = 1e-6
}

private func segments(_ sizes: [Double]) -> [WheelSegment] {
    sizes.map { WheelSegment(size: $0) }
}

private func isClose(_ a: Double, _ b: Double) -> Bool {
    abs(a - b) <= SpecVectors.tolerance
}

// MARK: - SpecVectorTests

@Suite("Spec test vectors")
struct SpecVectorTests {

    @Test func fileMatchesThisImplementation() throws {
        let vectors = try SpecVectors.load()
        #expect(vectors.version == 1)
        #expect(vectors.tolerance == SpecVectors.tolerance)
        let total = vectors.wedgeIndexAt.count + vectors.pickIndex.count + vectors.plan.count + vectors.easeOutQuart.count
        #expect(total == 151)
    }

    @Test(arguments: try SpecVectors.load().wedgeIndexAt)
    func wedgeIndexAt(_ vector: SpecVectors.WedgeCase) {
        #expect(Wheelie.wedgeIndexAt(vector.angle, segments: segments(vector.sizes)) == vector.index)
    }

    @Test(arguments: try SpecVectors.load().pickIndex)
    func pickIndex(_ vector: SpecVectors.PickCase) {
        #expect(Wheelie.pickIndex(weights: vector.weights, r: vector.r) == vector.index)
    }

    @Test(arguments: try SpecVectors.load().plan)
    func plan(_ vector: SpecVectors.PlanCase) throws {
        let mode: WheelMode = vector.mode == "pointer" ? .pointer : .wheel
        let options = SpinOptions(direction: vector.direction == "ccw" ? .counterClockwise : .clockwise, spread: vector.spread)
        let wedges = segments(vector.sizes)

        let plan = try #require(SpinPlanner.plan(
            targetIndex: vector.index,
            segments: wedges,
            currentRotation: vector.current,
            options: options,
            mode: mode,
            pointerAngle: vector.pointerAngle,
            offset: vector.offset,
            turns: vector.turns
        ))

        #expect(isClose(plan.landingAngle, vector.landingAngle))
        #expect(isClose(plan.restAngle, vector.restAngle))
        #expect(isClose(plan.targetRotation, vector.target))

        // Spec rule: land.index == wedgeIndexAt(localAngle(target)).
        let local = mode == .wheel ? vector.pointerAngle - vector.target : vector.pointerAngle + vector.target
        #expect(Wheelie.wedgeIndexAt(local, segments: wedges) == vector.index)
    }

    @Test(arguments: try SpecVectors.load().easeOutQuart)
    func easeOutQuart(_ vector: SpecVectors.EaseCase) {
        #expect(isClose(Wheelie.easeOutQuart(vector.t), vector.value))
    }
}

// MARK: - LayoutTests

@Suite("Layout")
struct LayoutTests {

    @Test(arguments: 1...12)
    func equalWedgesAreCentredEvenly(count: Int) {
        let layouts = layout(segments: Array(repeating: WheelSegment(), count: count))
        let span = 360.0 / Double(count)
        for (i, l) in layouts.enumerated() {
            #expect(isClose(l.span, span))
            #expect(isClose(l.center, Double(i) * span))
        }
    }

    @Test func wedgesCoverTheWholeCircle() {
        let layouts = layout(segments: segments([2, 1, 3, 0.5]))
        let total = layouts.reduce(0) { $0 + $1.span }
        #expect(isClose(total, 360))
        #expect(isClose(layouts[0].center, 0))
        #expect(isClose(layouts[3].start + layouts[3].span, layouts[0].start + 360))
    }

    @Test func emptyWheelHasNoLayout() {
        #expect(layout(segments: []).isEmpty)
    }

    @Test func clockwiseSpinTravelsBetweenTurnsAndOneMore() throws {
        // Clockwise targets travel between `turns` and `turns + 1` full turns.
        for index in 0..<6 {
            let plan = try #require(SpinPlanner.plan(
                targetIndex: index,
                segments: Array(repeating: WheelSegment(), count: 6),
                currentRotation: 123,
                options: SpinOptions(),
                mode: .wheel,
                turns: 3
            ))
            let travel = plan.targetRotation - 123
            #expect(travel >= 3 * 360 && travel < 4 * 360)
        }
    }

    @Test func planRejectsOutOfRangeIndex() {
        let wedges = Array(repeating: WheelSegment(), count: 4)
        for index in [-1, 4] {
            let plan = SpinPlanner.plan(
                targetIndex: index, segments: wedges, currentRotation: 0, options: SpinOptions(), mode: .wheel, turns: 3
            )
            #expect(plan == nil)
        }
    }
}
