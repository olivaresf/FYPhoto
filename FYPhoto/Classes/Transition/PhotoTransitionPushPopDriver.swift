//
//  PhotoTransitionDriver.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/1.
//

import Foundation

class PhotoPushPopTransitionDriver: TransitionDriver {
    var transitionAnimator: UIViewPropertyAnimator!
    var isInteractive: Bool {
        return transitionContext.isInteractive
    }
    let transitionContext: UIViewControllerContextTransitioning
    private let operation: UINavigationController.Operation
    private let duration: TimeInterval
    private var itemFrameAnimator: UIViewPropertyAnimator?
    var fromAssetTransitioning: PhotoTransitioning?
    var toAssetTransitioning: PhotoTransitioning?

    var toView: UIView?
    var fromView: UIView?

    var visualEffectView = UIVisualEffectView()

    /// The snapshotView that is animating between the two view controllers.
    fileprivate let transitionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        } else {
            // Fallback on earlier versions
        }
        return imageView
    }()

    // MARK: Initialization

    init(operation: UINavigationController.Operation, context: UIViewControllerContextTransitioning, duration: TimeInterval) {
        self.transitionContext = context
        self.operation = operation
        self.duration = duration

        setup(context)
    }

    func setup(_ context: UIViewControllerContextTransitioning) {
        // Setup the transition "chrome"
        guard
            let fromViewController = context.viewController(forKey: .from),
            let toViewController = context.viewController(forKey: .to),
            let fromAssetTransitioning = (fromViewController as? PhotoTransitioning),
            let toAssetTransitioning = (toViewController as? PhotoTransitioning),
            let fromView = fromViewController.view,
            let toView = toViewController.view
            else {
                assertionFailure("None of them should be nil")
                return
        }

        self.fromAssetTransitioning = fromAssetTransitioning
        self.toAssetTransitioning = toAssetTransitioning
        self.toView = toView
        self.fromView = fromView

        let containerView = context.containerView

        // Create a visual effect view and animate the effect in the transition animator
        let effect: UIVisualEffect? = (operation == .pop) ? UIBlurEffect(style: .extraLight) : nil
        let targetEffect: UIVisualEffect? = (operation == .pop) ? nil : UIBlurEffect(style: .light)
        //        let visualEffectView = UIVisualEffectView(effect: effect)
        visualEffectView.effect = effect
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        containerView.addSubview(visualEffectView)

        // Insert the toViewController's view into the transition container view
        let topView: UIView
        var topViewTargetAlpha: CGFloat = 0.0
        if operation == .push {
            topView = toView
            topViewTargetAlpha = 1.0
            toView.alpha = 0.0
            containerView.addSubview(toView)
        } else {
            topView = fromView
            topViewTargetAlpha = 0.0
            containerView.insertSubview(toView, at: 0)
        }

        // Ensure the toView has the correct size and position
        toView.frame = context.finalFrame(for: toViewController)

        if let fromImage = fromAssetTransitioning.referenceImage() {
            transitionImageView.image = fromImage
        }

        if let frame = fromAssetTransitioning.imageFrame() {
            transitionImageView.frame = frame
        }

        containerView.addSubview(transitionImageView)

        // Inform the view controller's the transition is about to start
        fromAssetTransitioning.transitionWillStart()
        toAssetTransitioning.transitionWillStart()

        // Create a UIViewPropertyAnimator that lives the lifetime of the transition
        let spring = CGFloat(0.95)
        transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: spring) {
            if self.operation == .push {
                if let referencedImage = self.fromAssetTransitioning?.referenceImage(),
                    let toView = self.toView {
                    let toReferenceFrame = Self.calculateZoomInImageFrame(image: referencedImage, forView: toView)
                    self.transitionImageView.frame = toReferenceFrame
                }
            } else {
                if let imageFrame = self.toAssetTransitioning?.imageFrame() {
                    self.transitionImageView.frame = imageFrame
                }
            }
            topView.alpha = topViewTargetAlpha
            self.visualEffectView.effect = targetEffect
        }

        transitionAnimator.addCompletion { _ in
            // Finish the protocol handshake
            self.fromAssetTransitioning?.transitionDidEnd()
            self.toAssetTransitioning?.transitionDidEnd()
            // Remove transition views
            self.transitionImageView.image = nil
            self.transitionImageView.removeFromSuperview()
            self.visualEffectView.removeFromSuperview()

            self.transitionContext.finishInteractiveTransition()
            self.transitionContext.completeTransition(true)
        }

        if transitionAnimator.state == .inactive {
            transitionAnimator.startAnimation()
        }
    }
}