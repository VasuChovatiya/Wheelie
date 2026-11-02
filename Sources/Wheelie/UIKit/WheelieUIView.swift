import SwiftUI
import UIKit

// MARK: - WheelieUIView

/// A `UIView` subclass that embeds a `WheelieView` via `UIHostingController`.
///
/// Supports both label-based and custom-content initialisers.
@available(iOS 15, *)
public final class WheelieUIView: UIView {

    // MARK: Public properties

    /// Visual style applied to the wheel.
    public var style: WheelStyle = WheelStyle() {
        didSet { updateHostedView() }
    }

    /// The wedges, including each one's size, weight and lock state.
    /// Defaults to equal segments, one per label (or `count`).
    public var segments: [WheelSegment] {
        didSet { updateHostedView() }
    }

    /// Whether the wheel or the pointer rotates.
    public var mode: WheelMode = .wheel {
        didSet { updateHostedView() }
    }

    /// The angle the pointer sits at (degrees, clockwise, 0° = 12 o'clock).
    public var pointerAngle: Double = 0 {
        didSet { updateHostedView() }
    }

    /// Called when the pointer crosses into a new segment.
    public var onSegmentPass: ((Int) -> Void)?

    /// Called when the spin animation finishes.
    public var onLand: ((WheelResult) -> Void)?

    /// Called when a spin animation starts.
    public var onSpinStart: ((WheelSpinStart) -> Void)?

    // MARK: Private state

    private let controller: WheelController = WheelController()
    private var hostingController: UIHostingController<AnyView>?

    private let segmentViewBuilder: ((Int) -> UIView)?
    private let labels: [String]?

    // MARK: Init – label based

    /// Creates a wheel where each segment shows a text label.
    ///
    /// - Parameters:
    ///   - labels: The label for each segment (one per wedge).
    ///   - frame: The initial frame.
    public init(labels: [String], frame: CGRect = .zero) {
        self.labels = labels
        self.segments = labels.map { _ in WheelSegment() }
        self.segmentViewBuilder = nil
        super.init(frame: frame)
        setup()
    }

    // MARK: Init – custom content

    /// Creates a wheel where each segment shows a custom `UIView`.
    ///
    /// - Parameters:
    ///   - segmentView: A closure returning a `UIView` for a given segment index.
    ///   - count: Total number of segments.
    ///   - frame: The initial frame.
    public init(
        segmentView: @escaping (Int) -> UIView,
        count: Int,
        frame: CGRect = .zero
    ) {
        self.labels = nil
        self.segments = (0..<max(1, count)).map { _ in WheelSegment() }
        self.segmentViewBuilder = segmentView
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported. Use init(labels:frame:) or init(segmentView:count:frame:) instead.")
    }

    // MARK: - Public API

    /// Spins the wheel.
    ///
    /// - Parameter index: The segment to land on, or `nil` for weighted random.
    public func spin(to index: Int? = nil) {
        controller.spin(to: index)
    }

    /// Stops any in-progress spin and resets the wheel to its default position.
    public func reset() {
        controller.reset()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        hostingController?.view.frame = bounds
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        // The responder chain only reaches a view controller once the view is in a hierarchy,
        // so the hosting controller is (re)parented here rather than at init.
        attachHostingControllerToParent()
    }

    // MARK: - Private helpers

    private func setup() {
        backgroundColor = .clear
        embed()
    }

    private func makeSwiftUIView() -> AnyView {
        let ctrl = controller
        let s = style
        let segs = segments
        let m = mode
        let angle = pointerAngle

        // Callbacks are read through weak self when they fire, so ones set after init are used
        // and the hosted view doesn't retain this view.
        if let labels = labels {
            let view = WheelieView(
                segments: segs,
                controller: ctrl,
                mode: m
            ) { index in
                Text(index < labels.count ? labels[index] : "")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .wheelStyle(s)
            .wheelPointerAngle(angle)
            .onSpinStart { [weak self] in self?.onSpinStart?($0) }
            .onSegmentPass { [weak self] in self?.onSegmentPass?($0) }
            .onLand { [weak self] in self?.onLand?($0) }

            return AnyView(view)
        } else if let builder = segmentViewBuilder {
            let view = WheelieView(
                segments: segs,
                controller: ctrl,
                mode: m
            ) { index in
                // Wrap the UIView in a UIViewRepresentable
                UIViewWrapper(builder: builder, index: index)
            }
            .wheelStyle(s)
            .wheelPointerAngle(angle)
            .onSpinStart { [weak self] in self?.onSpinStart?($0) }
            .onSegmentPass { [weak self] in self?.onSegmentPass?($0) }
            .onLand { [weak self] in self?.onLand?($0) }

            return AnyView(view)
        } else {
            return AnyView(EmptyView())
        }
    }

    private func embed() {
        let rootView = makeSwiftUIView()
        let host = UIHostingController(rootView: rootView)
        host.view.backgroundColor = .clear

        addSubview(host.view)
        host.view.frame = bounds

        hostingController = host
    }

    /// Makes the hosting controller a child of the nearest view controller while this view is
    /// in a window, and detaches it when the view leaves.
    private func attachHostingControllerToParent() {
        guard let host = hostingController else { return }
        let parentVC = window == nil ? nil : parentViewController()
        guard host.parent !== parentVC else { return }

        if host.parent != nil {
            host.willMove(toParent: nil)
            host.removeFromParent()
        }
        if let parentVC = parentVC {
            parentVC.addChild(host)
            host.didMove(toParent: parentVC)
        }
    }

    private func updateHostedView() {
        // Rebuild the hosted SwiftUI view with new style / callbacks.
        hostingController?.rootView = makeSwiftUIView()
    }

    private func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let viewController = next as? UIViewController { return viewController }
            responder = next
        }
        return nil
    }
}

// MARK: - UIViewWrapper

/// Wraps a `UIView` inside a SwiftUI `UIViewRepresentable`.
private struct UIViewWrapper: UIViewRepresentable {
    let builder: (Int) -> UIView
    let index: Int

    func makeUIView(context: Context) -> UIView {
        builder(index)
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
