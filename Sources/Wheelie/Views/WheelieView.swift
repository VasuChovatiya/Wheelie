import SwiftUI

// MARK: - WheelieView

/// The main Wheelie SwiftUI view.
///
/// Use the `wheelStyle`, `wheelPointer`, `wheelHub`, `wheelHighlight`, `onSpinStart`,
/// `onSegmentPass`, and `onLand` modifiers on this view (or any ancestor) to customise behaviour.
///
/// Example:
/// ```swift
/// WheelieView(count: 6, controller: controller) { index in
///     Text("Segment \(index)")
/// }
/// .wheelStyle(WheelStyle(colors: [.red, .blue]))
/// .onLand { result in print("Landed on \(result.index)") }
/// ```
public struct WheelieView<SegmentContent: View>: View {

    // MARK: Private state

    private let segments: [WheelSegment]
    @ObservedObject private var controller: WheelController
    private let mode: WheelMode
    private let segmentContent: (Int) -> SegmentContent

    // MARK: Environment

    @Environment(\.wheelStyle)        private var style
    @Environment(\.wheelPointer)      private var customPointer
    @Environment(\.wheelPointerAngle) private var pointerAngle
    @Environment(\.wheelHub)          private var customHub
    @Environment(\.wheelHighlights)   private var highlights
    @Environment(\.wheelOnSpinStart)  private var envOnSpinStart
    @Environment(\.wheelOnSegmentPass) private var envOnSegmentPass
    @Environment(\.wheelOnLand)       private var envOnLand

    // MARK: Init – count based (equal segments)

    /// Creates a wheel with `count` equal segments.
    ///
    /// - Parameters:
    ///   - count: Number of equal wedges.
    ///   - controller: The `WheelController` driving animations.
    ///   - mode: Whether the wheel or the pointer rotates.
    ///   - segment: A view builder called with the zero-based segment index.
    public init(
        count: Int,
        controller: WheelController,
        mode: WheelMode = .wheel,
        @ViewBuilder segment: @escaping (Int) -> SegmentContent
    ) {
        self.segments = (0..<max(1, count)).map { _ in WheelSegment() }
        self.controller = controller
        self.mode = mode
        self.segmentContent = segment
    }

    // MARK: Init – segments based

    /// Creates a wheel from an array of `WheelSegment` descriptors.
    ///
    /// - Parameters:
    ///   - segments: The wheel segments.
    ///   - controller: The `WheelController` driving animations.
    ///   - mode: Whether the wheel or the pointer rotates.
    ///   - segment: A view builder called with the zero-based segment index.
    public init(
        segments: [WheelSegment],
        controller: WheelController,
        mode: WheelMode = .wheel,
        @ViewBuilder segment: @escaping (Int) -> SegmentContent
    ) {
        self.segments = segments.isEmpty ? [WheelSegment()] : segments
        self.controller = controller
        self.mode = mode
        self.segmentContent = segment
    }

    // MARK: Body

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2

            ZStack {
                switch mode {
                case .wheel:
                    // The wheel rotates; pointer is fixed.
                    wheelBody(radius: radius)
                        .rotationEffect(.degrees(controller.rotation))

                    pointerBody(radius: radius)

                case .pointer:
                    // The wheel is fixed; the pointer rotates.
                    wheelBody(radius: radius)

                    pointerBody(radius: radius)
                        .rotationEffect(.degrees(controller.rotation))
                }
            }
            .frame(width: size, height: size)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear { wireController() }
        .onChange(of: segments) { _ in wireController() }
        .onChange(of: mode) { _ in wireController() }
        .onChange(of: pointerAngle) { _ in wireController() }
    }

    // MARK: - Wheel body

    @ViewBuilder
    private func wheelBody(radius: CGFloat) -> some View {
        let layouts = layout(segments: segments)
        let landedIdx = controller.landedIndex

        ZStack {
            // Wedges
            ForEach(0..<segments.count, id: \.self) { i in
                let l = layouts[i]
                let color = style.colors.isEmpty ? .gray : style.colors[i % style.colors.count]

                WheelSegmentShape(startAngle: l.start, endAngle: l.start + l.span)
                    .fill(color)
                    .modifier(HighlightModifier(
                        index: i,
                        layout: l,
                        landedIndex: landedIdx,
                        highlights: highlights
                    ))
            }

            // Separator lines
            ForEach(0..<segments.count, id: \.self) { i in
                let l = layouts[i]
                SeparatorLine(angle: l.start, radius: radius, width: style.separatorWidth)
            }

            // Segment content
            ForEach(0..<segments.count, id: \.self) { i in
                let l = layouts[i]
                let contentRadius = radius * CGFloat(style.labelRadius)
                let angleRad = l.center * .pi / 180

                segmentContent(i)
                    .rotationEffect(.degrees(l.center + 90)) // point outward
                    .offset(
                        x: CGFloat(sin(angleRad)) * contentRadius,
                        y: -CGFloat(cos(angleRad)) * contentRadius
                    )
            }

            // Rim
            Circle()
                .strokeBorder(style.rimColor, lineWidth: CGFloat(style.rimWidth))
                .frame(width: radius * 2, height: radius * 2)

            // Hub
            hubBody(landedIdx: landedIdx ?? 0)
        }
    }

    // MARK: - Pointer body

    @ViewBuilder
    private func pointerBody(radius: CGFloat) -> some View {
        let angle = pointerAngle

        VStack(spacing: 0) {
            Group {
                if let custom = customPointer {
                    custom
                } else {
                    WheelPointerView()
                }
            }
            Spacer()
        }
        .frame(width: radius * 2, height: radius * 2)
        .rotationEffect(.degrees(angle))
    }

    // MARK: - Hub body

    @ViewBuilder
    private func hubBody(landedIdx: Int) -> some View {
        if let custom = customHub {
            custom(landedIdx)
        } else {
            WheelHubView()
        }
    }

    // MARK: - Wire controller

    private func wireController() {
        controller.segments = segments
        controller.mode = mode
        controller.pointerAngle = pointerAngle
        controller.onSpinStart = envOnSpinStart
        controller.onSegmentPass = envOnSegmentPass
        controller.onLand = envOnLand
    }
}

// MARK: - Separator line helper

private struct SeparatorLine: View {
    let angle: Double
    let radius: CGFloat
    let width: Double

    var body: some View {
        SeparatorPath(angle: angle, radius: radius)
            .stroke(Color.white, lineWidth: CGFloat(width))
    }
}

/// A line from the centre of its frame out to `radius` at `angle` (degrees, clockwise, 0° = 12 o'clock).
private struct SeparatorPath: Shape {
    let angle: Double
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let angleRad = angle * .pi / 180

        var path = Path()
        path.move(to: centre)
        path.addLine(to: CGPoint(
            x: centre.x + CGFloat(sin(angleRad)) * radius,
            y: centre.y - CGFloat(cos(angleRad)) * radius
        ))
        return path
    }
}

// MARK: - Highlight modifier

private struct HighlightModifier: ViewModifier {
    let index: Int
    let layout: SegmentLayout
    let landedIndex: Int?
    let highlights: [WheelHighlight]

    func body(content: Content) -> some View {
        guard let landed = landedIndex else {
            return AnyView(content)
        }

        var view: AnyView = AnyView(content)
        for highlight in highlights {
            view = apply(highlight: highlight, to: view, index: index, landed: landed)
        }
        return view
    }

    private func apply(highlight: WheelHighlight, to view: AnyView, index: Int, landed: Int) -> AnyView {
        switch highlight {
        case .none:
            return view

        case .dimOthers(let opacity):
            if index != landed {
                return AnyView(view.opacity(opacity))
            }
            return view

        case .outline(let color, let width):
            if index == landed {
                return AnyView(view.overlay(
                    WheelSegmentShape(
                        startAngle: layout.start,
                        endAngle: layout.start + layout.span
                    )
                    .stroke(color, lineWidth: CGFloat(width))
                ))
            }
            return view

        case .pulse(let scale):
            if index == landed {
                return AnyView(view.scaleEffect(scale))
            }
            return view
        }
    }
}
