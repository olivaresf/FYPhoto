//
//  PhotoPickerHelper.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/8/4.
//

import Foundation
import AVFoundation
import Photos
import MobileCoreServices
import PhotosUI

public protocol PhotoLauncherDelegate: class {
    func selectedPhotosInPhotoLauncher(_ photos: [SelectedImage])
//    func selectedPhotosInPhotoLauncher(_ photos: [Photo])
}

/// A helper class to launch photo picker and camera.
@objc public class PhotoLauncher: NSObject {
    public struct PhotoLauncherConfig {
        /// the rectangle in the specified view in which to anchor the popover(for iPad).
        public var sourceRect: CGRect = .zero
        /// You can choose the maximum number of photos, default 6.
        public var maximumNumberCanChoose: Int = 6
        /// mediaOptions contain image, video. If camera action is choosed,
        /// this value determines camera can either capture video or image or both.
        /// Default video format is mp4.
        public var mediaOptions: MediaOptions = .image
        /// maximum video capture duration. Default 15s
        public var videoMaximumDuration: TimeInterval = 15
        /// url extension, e.g., xxx.mp4
        public var videoPathExtension: String = "mp4"

        public init() {

        }
    }

    public typealias CameraContainer = UIViewController & UINavigationControllerDelegate & CameraViewControllerDelegate

    public weak var delegate: PhotoLauncherDelegate?

    var captureVideoImagePicker: UIImagePickerController?

    deinit {
        print(#function, #file)
    }

    public override init() {
        super.init()
    }

    @available(swift, deprecated: 0.3, message: "Use PhotoPickerViewController instead")
    /// Show PhotoPicker or Camera action sheet. This is for CUSTOM photo picker, if you want to use SYSTEM photo picker,
    /// use
    /// `showSystemPhotoPickerAletSheet(in:, sourceRect:, maximumNumberCanChoose:, isOnlyImages:)`
    /// instead.
    /// CUSTOM PhotoPicker need Authority.
    /// - Parameters:
    ///   - container: camera container.
    ///   - config: launcher config. Default config:
    ///     sourceRect = .zero, maximumNumberCanChoose = 6, isOnlyImages = true, videoMaximumDuration = 15, videoPathExtension = mp4
    public func showCustomPhotoPickerCameraAlertSheet(in container: CameraContainer, config: PhotoLauncherConfig = PhotoLauncherConfig()) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: "photo".photoTablelocalized, style: .default) { (_) in
            self.launchCustomPhotoLibrary(in: container, maximumNumberCanChoose: config.maximumNumberCanChoose, mediaOptions: config.mediaOptions)
        }
        let camera = UIAlertAction(title: "camera".photoTablelocalized, style: .default) { (_) in
            if config.mediaOptions == .image {
                self.launchCamera(in: container,
                                  captureModes: [CameraViewController.CaptureMode.image],
                                  videoMaximumDuration: config.videoMaximumDuration)
            } else if config.mediaOptions == .video {
                self.launchCamera(in: container,
                                  captureModes: [.movie],
                                  moviePathExtension: config.videoPathExtension,
                                  videoMaximumDuration: config.videoMaximumDuration)
            } else {
                self.launchCamera(in: container,
                                  captureModes: [.movie, .image],
                                  moviePathExtension: config.videoPathExtension,
                                  videoMaximumDuration: config.videoMaximumDuration)
            }
        }

        let cancel = UIAlertAction(title: "Cancel".photoTablelocalized, style: .cancel, handler: nil)

        alert.addAction(photo)
        alert.addAction(camera)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = container.view
        alert.popoverPresentationController?.sourceRect = config.sourceRect
        container.present(alert, animated: true, completion: nil)
    }

    /// launch camera for capturing media
    /// - Parameters:
    ///   - viewController: container comforms to some protocols.
    ///   - captureModes: image / movie
    ///   - moviePathExtension: movie extension, default is mp4.
    ///   - videoMaximumDuration: video capture duration. Default 15s
    public func launchCamera(in viewController: CameraContainer,
                             captureModes: [CameraViewController.CaptureMode] = [.image],
                             moviePathExtension: String? = nil,
                             videoMaximumDuration: TimeInterval = 15) {
        let cameraVC = CameraViewController()
        cameraVC.captureModes = captureModes
        cameraVC.videoMaximumDuration = videoMaximumDuration
        cameraVC.moviePathExtension = moviePathExtension ?? "mp4"
        cameraVC.delegate = viewController
        cameraVC.modalPresentationStyle = .fullScreen
        viewController.present(cameraVC, animated: true, completion: nil)
    }

    public func launchCustomPhotoLibrary(in viewController: UIViewController,
                                         maximumNumberCanChoose: Int,
                                         mediaOptions: MediaOptions = .image) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            launchPhotoLibrary(in: viewController, maximumNumberCanChoose, mediaOptions: mediaOptions)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self.launchPhotoLibrary(in: viewController, maximumNumberCanChoose, mediaOptions: mediaOptions)
                    }
                default: break
                }
            }
        default: break
        }
    }

    func launchPhotoLibrary(in viewController: UIViewController, _ maximumNumberCanChoose: Int, mediaOptions: MediaOptions) {
        let gridVC = PhotoPickerViewController(mediaTypes: mediaOptions)
            .setMaximumPhotosCanBeSelected(maximumNumberCanChoose)
            .setPickerWithCamera(false)
        gridVC.selectedPhotos = { [weak self] images in
            self?.delegate?.selectedPhotosInPhotoLauncher(images)
        }

        let navi = UINavigationController(rootViewController: gridVC)
        navi.modalPresentationStyle = .fullScreen
        viewController.present(navi, animated: true, completion: nil)
    }

    @objc public func previousDeniedCaptureAuthorization() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            return true
        default:
            return false
        }
    }
}

@available(iOS 14, *)
extension PhotoLauncher: PHPickerViewControllerDelegate {

    /// Show PhotoPicker or Camera action sheet. This is for SYSTEM photo picker, if you want to use CUSTOM photo picker,
    /// use
    /// `showCustomPhotoPickerAletSheet(in:, sourceRect:, maximumNumberCanChoose:, isOnlyImages:)`
    /// instead.
    /// SYSTEM PhotoPicker do not need Authority.
    /// - Parameters:
    ///   - container: camera container.
    ///   - config: launcher config. Default config:
    ///     sourceRect = .zero, maximumNumberCanChoose = 6, isOnlyImages = true, videoMaximumDuration = 15, videoPathExtension = mp4
    public func showSystemPhotoPickerCameraAlertSheet(in container: CameraContainer,
                                                      config: PhotoLauncherConfig = PhotoLauncherConfig()) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: "photo".photoTablelocalized, style: .default) { (_) in
            self.launchSystemPhotoPicker(in: container, maximumNumberCanChoose: config.maximumNumberCanChoose, mediaOptions: config.mediaOptions)
        }
        let camera = UIAlertAction(title: "camera".photoTablelocalized, style: .default) { (_) in
            if config.mediaOptions == .image {
                self.launchCamera(in: container, captureModes: [.image], videoMaximumDuration: config.videoMaximumDuration)
            } else if config.mediaOptions == .video {
                self.launchCamera(in: container, captureModes: [.movie], moviePathExtension: config.videoPathExtension, videoMaximumDuration: config.videoMaximumDuration)
            } else {
                self.launchCamera(in: container, captureModes: [.image, .movie], moviePathExtension: config.videoPathExtension, videoMaximumDuration: config.videoMaximumDuration)
            }
        }

        let cancel = UIAlertAction(title: "cancel".photoTablelocalized, style: .cancel, handler: nil)

        alert.addAction(photo)
        alert.addAction(camera)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = container.view
        alert.popoverPresentationController?.sourceRect = config.sourceRect
        container.present(alert, animated: true, completion: nil)
    }

    public func launchSystemPhotoPicker(in viewController: UIViewController, maximumNumberCanChoose: Int = 6, mediaOptions: MediaOptions = .image) {
        var configuration = PHPickerConfiguration()
        let filter: PHPickerFilter
        if mediaOptions == .image {
            filter = PHPickerFilter.images
        } else if mediaOptions == .video {
            filter = PHPickerFilter.videos
        } else {
            filter = PHPickerFilter.any(of: [.images, .videos])
        }
        configuration.filter = filter
        configuration.selectionLimit = maximumNumberCanChoose
        let pickerController = PHPickerViewController(configuration: configuration)
        pickerController.delegate = self
        viewController.present(pickerController, animated: true, completion: nil)
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        parsePickerFetchResults(results) { (images) in
            self.delegate?.selectedPhotosInPhotoLauncher(images)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func parsePickerFetchResults(_ results: [PHPickerResult], completion: @escaping (([SelectedImage]) -> Void)) {
        guard !results.isEmpty else {
            completion([])
            return
        }

        var images: [SelectedImage] = []
        let group = DispatchGroup()

        results.forEach { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        var asset: PHAsset?
                        if let id = result.assetIdentifier {
                            asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
                        }
                        images.append(SelectedImage(asset: asset, image: image))
                    } else {
                        //TODO: what's the use of the code below?
//                        if let placeholder = "cover_placeholder".photoImage {
//                            images.append(placeholder)
//                        }
                        print("Couldn't load image with error: \(error?.localizedDescription ?? "unknown error")")
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(images)
        }
    }

}
