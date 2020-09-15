//
//  VideoCaptureOverlay.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/15.
//

import UIKit
import UICircularProgressRing

public protocol VideoCaptureOverlayDelegate: class {
    func switchCamera()
    func takePicture()
    func startVideoCapturing()
    func stopVideoCapturing(_ isCancel: Bool)
    func dismissVideoCapture()
}

class VideoCaptureOverlay: UIView {
    weak var delegate: VideoCaptureOverlayDelegate?

    let progressView = UICircularProgressRing()
    let rearFrontCameraButton = UIButton()
    let dismissButton = UIButton()

    var cameraTimer: Timer?

    var runCount: Double = 0

    let videoMaximumDuration: TimeInterval

    init(videoMaximumDuration: TimeInterval, frame: CGRect) {
        self.videoMaximumDuration = videoMaximumDuration
        super.init(frame: frame)

        addSubview(progressView)
        addSubview(rearFrontCameraButton)
        addSubview(dismissButton)
        setupViews()
        addGesturesOnProgressView()
        makeConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        progressView.outerRingColor = .white
        progressView.innerRingColor = .orange
        progressView.style = .ontop
//        progressView.isHidden = true
        progressView.minValue = 0
        progressView.startAngle = 270
        progressView.maxValue = CGFloat(videoMaximumDuration)
        progressView.valueFormatter = VideoTimerRingValueFormatter()

        rearFrontCameraButton.addTarget(self, action: #selector(switchCamera(_:)), for: .touchUpInside)
        // TODO: TODO Use image instead of title 😴zZ
//        rearFrontCameraButton.setImage(<#T##image: UIImage?##UIImage?#>, for: <#T##UIControl.State#>)
        rearFrontCameraButton.setTitle("Front/Rear".photoTablelocalized, for: .normal)

        dismissButton.setTitle("Cancel".photoTablelocalized, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
    }

    func addGesturesOnProgressView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        progressView.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPress.require(toFail: tap)
        progressView.addGestureRecognizer(longPress)
    }

    @objc func switchCamera(_ sender: UIButton) {
        delegate?.switchCamera()
    }

    @objc func dismiss(_ sender: UIButton) {
        delegate?.dismissVideoCapture()
    }

    @objc func longPress(_ gesture:UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            delegate?.startVideoCapturing()
            initialProgressView()
            addTimer()
        case .cancelled:
            delegate?.stopVideoCapturing(true)
            restoreProgressView()
            endTimer()
        case .ended:
            if cameraTimer != nil {
                delegate?.stopVideoCapturing(false)
                restoreProgressView()
                endTimer()
            }
        default:
            break
        }
    }

    @objc func tapped(_ gesture: UITapGestureRecognizer) {
        delegate?.takePicture()
    }

    func initialProgressView() {
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
//            self.progressView.value = 0
            self.progressWidthAnchor?.constant = 110
            self.progressHeightAnchor?.constant = 110
        })
    }

    fileprivate func restoreProgressView() {
        progressView.value = 0
        progressWidthAnchor?.constant = 80
        progressHeightAnchor?.constant = 80
    }

    func addTimer() {
        if let timer = cameraTimer {
            if timer.isValid {
                timer.invalidate()
            }
            timer.fire()
        } else {
            cameraTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] timer in
                guard let self = self else { return }
                self.runCount += 0.1
                self.progressView.value += 0.1
                if self.runCount == self.videoMaximumDuration {
                    timer.invalidate()
                    self.delegate?.stopVideoCapturing(false)
                    self.runCount = 0
                }
            })
        }
    }

    func endTimer() {
        if let timer = cameraTimer {
            if timer.isValid {
                timer.invalidate()
                self.cameraTimer = nil
            }
        }
    }

    var progressWidthAnchor: NSLayoutConstraint?
    var progressHeightAnchor: NSLayoutConstraint?

    func makeConstraints() {
        progressView.translatesAutoresizingMaskIntoConstraints = false

        progressView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true
        progressWidthAnchor = progressView.widthAnchor.constraint(equalToConstant: 80)
        progressHeightAnchor = progressView.heightAnchor.constraint(equalToConstant: 80)
        progressWidthAnchor?.isActive = true
        progressHeightAnchor?.isActive = true

        rearFrontCameraButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rearFrontCameraButton.centerYAnchor.constraint(equalTo: self.progressView.centerYAnchor),
            rearFrontCameraButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            rearFrontCameraButton.widthAnchor.constraint(equalToConstant: 100),
            rearFrontCameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            dismissButton.centerYAnchor.constraint(equalTo: self.progressView.centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 80),
            dismissButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    deinit {
        cameraTimer?.invalidate()
    }
}


class VideoTimerRingValueFormatter: UICircularRingValueFormatter {

    public init() { }

    // MARK: API

    /// formats the value of the progress ring using the given properties
    public func string(for value: Any) -> String? {
        guard let value = value as? CGFloat else { return nil }
        if value == 0 {
            return nil
        } else {
            return "\(Int(value))s"
        }
    }
}
