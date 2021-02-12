//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//
#if TESTFILE

import Foundation
import UIKit

/// Based on AAPLSwipeTransitionInteractionController in Apple's CustomTransitions sample code:
/// https://developer.apple.com/library/content/samplecode/CustomTransitions/Introduction/Intro.html
final class SwipeTransitionInteractionController: UIPercentDrivenInteractiveTransition {

    private let panGestureRecognizer: UIPanGestureRecognizer
    private let fromEdge: UIRectEdge
    private let scrollView: UIScrollView?
    private weak var transitionContext: UIViewControllerContextTransitioning?

    init(panGestureRecognizer: UIPanGestureRecognizer, fromEdge: UIRectEdge, scrollView: UIScrollView? = nil) {
        uberAssert(fromEdge == .top || fromEdge == .bottom || fromEdge == .left || fromEdge == .right, "fromEdge must be one of .top, .bottom, .left, or .right", monitoringKey: "SwipeTransitionInteractionController-invalidFromEdge")
        self.panGestureRecognizer = panGestureRecognizer
        self.fromEdge = fromEdge
        self.scrollView = scrollView
        super.init()
        panGestureRecognizer.addTarget(self, action: #selector(didPan(_:)))
    }

    deinit {
        panGestureRecognizer.removeTarget(self, action: #selector(didPan(_:)))
    }

    // MARK: UIViewControllerInteractiveTransitioning

    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        super.startInteractiveTransition(transitionContext)
    }

    // MARK: Private

    private func percentForGesture(panGestureRecognizer: UIPanGestureRecognizer) -> CGFloat {
        guard let transitionContext = transitionContext,
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from),
            shouldStartInteractiveTransition() else { return 0.0 }

        let isPresenting = toViewController.presentingViewController === fromViewController

        let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
        let fromViewInitialFrame = transitionContext.initialFrame(for: fromViewController)
        let presentedFrame = isPresenting ? toViewFinalFrame : fromViewInitialFrame

        let containerView = transitionContext.containerView
        let locationInSourceView = panGestureRecognizer.location(in: containerView)
        let translationInSourceView = panGestureRecognizer.translation(in: containerView)
        let pointInSourceView = isPresenting ? locationInSourceView : translationInSourceView

        if fromEdge == .right {
            let offset = isPresenting ? containerView.bounds.width : 0.0
            return (offset - pointInSourceView.x) / presentedFrame.width
        } else if fromEdge == .left {
            return pointInSourceView.x / presentedFrame.width
        } else if fromEdge == .bottom {
            let offset = isPresenting ? containerView.bounds.height : 0.0
            return (offset - pointInSourceView.y) / presentedFrame.height
        } else if fromEdge == .top {
            return pointInSourceView.y / presentedFrame.height
        } else {
            return 0.0
        }
    }

    private func directionalVelocityForGesture(panGestureRecognizer: UIPanGestureRecognizer) -> CGFloat {
        if let containerView = transitionContext?.containerView {
            let velocity = panGestureRecognizer.velocity(in: containerView)
            if fromEdge == .right {
                return -velocity.x
            } else if fromEdge == .left {
                return velocity.x
            } else if fromEdge == .bottom {
                return -velocity.y
            } else if fromEdge == .top {
                return velocity.y
            }
        }
        return 0.0
    }

    private func shouldStartInteractiveTransition() -> Bool {
        if let scrollView = scrollView {
            // Only start interactive transition if scrollView content offset has reached fromEdge
            if fromEdge == .right {
                // swiftlint:disable:next custom_rules
                return scrollView.frame.size.width + scrollView.contentOffset.x >= scrollView.contentSize.width + scrollView.contentInset.right
            } else if fromEdge == .left {
                return scrollView.contentOffset.x <= 0
            } else if fromEdge == .bottom {
                return scrollView.frame.size.height + scrollView.contentOffset.y >= scrollView.contentSize.height + scrollView.contentInset.bottom
            } else if fromEdge == .top {
                return scrollView.contentOffset.y <= 0
            }
        }
        return true
    }

    @objc private func didPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            break
        case .changed:
            let percentComplete = percentForGesture(panGestureRecognizer: recognizer)
            update(percentComplete)
        case .ended:
            let directionalVelocity = directionalVelocityForGesture(panGestureRecognizer: recognizer)
            let shouldFinish = directionalVelocity > 0 && shouldStartInteractiveTransition()
            if shouldFinish {
                finish()
            } else {
                cancel()
            }
        default:
            cancel()
        }
    }
}

#endif
