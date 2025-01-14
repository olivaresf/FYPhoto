//
//  VideoCaptureOverlay.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/15.
//

import UIKit
import UICircularProgressRing

public protocol VideoCaptureOverlayDelegate: AnyObject {
    func switchCameraDevice(_ cameraButton: UIButton)
    func takePicture()
    func startVideoCapturing()
    func stopVideoCapturing(_ isCancel: Bool)
    func dismissVideoCapture()
    func flashSwitch()
    
    func resumeButtonClicked(_ resumeButton: UIButton)
}

public class VideoCaptureOverlay: UIView {
    weak var delegate: VideoCaptureOverlayDelegate?
    /// capture mode. Default is photo.
    public var captureMode: MediaOptions = .image

    let progressView = UICircularProgressRing()
    let rearFrontCameraButton = UIButton()
    let dismissButton = UIButton()
    let resumeButton = UIButton()
    let cameraUnavailableLabel = UILabel()

    let flashButton = UIButton()
    
    var cameraTimer: Timer?

    var runCount: Double = 0

    var videoMaximumDuration: TimeInterval = 15

    var progressWidthAnchor: NSLayoutConstraint?
    var progressHeightAnchor: NSLayoutConstraint?

    var enableTakePicture = true {
        willSet {
            tapGesture.isEnabled = newValue && captureMode.contains(.image)
        }
    }
    var enableTakeVideo = true {
        willSet {
            longPressGesture.isEnabled = newValue && captureMode.contains(.video)
        }
    }
    var enableSwitchCamera = true {
        willSet {
            rearFrontCameraButton.isEnabled = newValue
        }
    }

    var enableFlash = true {
        willSet {
            flashButton.isEnabled = newValue
        }
    }

    var flashOn: Bool = true {
        willSet {
            let image = newValue ? Asset.icons8FlashOn.image : Asset.icons8FlashOff.image
            flashButton.setImage(image, for: .normal)
        }
    }

    let tapGesture = UITapGestureRecognizer()
    let longPressGesture = UILongPressGestureRecognizer()

    init(videoMaximumDuration: TimeInterval, tintColor: UIColor) {
        self.videoMaximumDuration = videoMaximumDuration
        super.init(frame: .zero)
        self.tintColor = tintColor
        addSubview(progressView)
        addSubview(rearFrontCameraButton)
        addSubview(dismissButton)
        addSubview(resumeButton)
        addSubview(cameraUnavailableLabel)
        addSubview(flashButton)

        setupViews()
        addGesturesOnProgressView()
        makeConstraints()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        progressView.outerRingColor = .white
        progressView.innerRingColor = self.tintColor
        progressView.style = .ontop
//        progressView.isHidden = true
        progressView.minValue = 0
        progressView.startAngle = 270
        progressView.maxValue = CGFloat(videoMaximumDuration)
        progressView.valueFormatter = VideoTimerRingValueFormatter()

        rearFrontCameraButton.addTarget(self, action: #selector(switchCamera(_:)), for: .touchUpInside)
        
        rearFrontCameraButton.setImage(Asset.flipCamera.image, for: .normal)

        dismissButton.setTitle(L10n.cancel, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        resumeButton.isHidden = true
        resumeButton.setTitle(L10n.resume, for: .normal)
        resumeButton.addTarget(self, action: #selector(resume(_:)), for: .touchUpInside)

        flashButton.setImage(Asset.icons8FlashOn.image, for: .normal)
        flashButton.addTarget(self, action: #selector(switchFlash(_:)), for: .touchUpInside)
    }

    func addGesturesOnProgressView() {
        tapGesture.addTarget(self, action: #selector(tapped(_:)))
        progressView.addGestureRecognizer(tapGesture)

        longPressGesture.addTarget(self, action: #selector(longPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        progressView.addGestureRecognizer(longPressGesture)

    }

    @objc func switchCamera(_ sender: UIButton) {
        delegate?.switchCameraDevice(sender)
    }

    @objc func dismiss(_ sender: UIButton) {
        delegate?.dismissVideoCapture()
    }
    
    @objc func resume(_ sender: UIButton) {
        delegate?.resumeButtonClicked(sender)
    }

    @objc func longPress(_ gesture:UILongPressGestureRecognizer) {
        guard captureMode == .video || captureMode == .all else { return }
        
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
        guard captureMode.contains(.image) else {
            return
        }
        delegate?.takePicture()
    }

    @objc func switchFlash(_ sender: UIButton) {
        flashOn = !flashOn
        delegate?.flashSwitch()
    }

    func initialProgressView() {
        UIView.animate(withDuration: 0.37, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
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

    func makeConstraints() {
        progressView.translatesAutoresizingMaskIntoConstraints = false

        progressView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -40).isActive = true
        progressWidthAnchor = progressView.widthAnchor.constraint(equalToConstant: 80)
        progressHeightAnchor = progressView.heightAnchor.constraint(equalToConstant: 80)
        progressWidthAnchor?.isActive = true
        progressHeightAnchor?.isActive = true

        rearFrontCameraButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rearFrontCameraButton.centerYAnchor.constraint(equalTo: self.progressView.centerYAnchor),
            rearFrontCameraButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            rearFrontCameraButton.widthAnchor.constraint(equalToConstant: 50),
            rearFrontCameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            dismissButton.centerYAnchor.constraint(equalTo: self.progressView.centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 80),
            dismissButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        flashButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flashButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 30),
            flashButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            flashButton.widthAnchor.constraint(equalToConstant: 45),
            flashButton.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        resumeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resumeButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            resumeButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
        ])
    }

    deinit {
        cameraTimer?.invalidate()
    }
}


class VideoTimerRingValueFormatter: UICircularRingValueFormatter {

    public init() { }

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
