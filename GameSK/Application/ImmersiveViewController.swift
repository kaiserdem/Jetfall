import UIKit

/// Shared base for immersive game screens — keeps the Home Indicator auto-hidden.
class ImmersiveViewController: UIViewController {

    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .bottom }
}
