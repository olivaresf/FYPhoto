//
//  ViewController.swift
//  FYPhoto
//
//  Created by t2je on 07/15/2020.
//  Copyright (c) 2020 t2je. All rights reserved.
//

import UIKit
import FYPhoto
import Photos
import PhotosUI
import MobileCoreServices

class ViewController: UIViewController {

    var stackView = UIStackView()
    let photoLanucher = PhotoLauncher()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        photoLanucher.delegate = self
        print("PhotosAuthority.isCameraAvailable: \(PhotosAuthority.isCameraAvailable())")
        print("PhotosAuthority.isPhotoLibraryAvailable: \(PhotosAuthority.isPhotoLibraryAvailable())")
        print("PhotosAuthority.doesCameraSupportTakingPhotos: \(PhotosAuthority.doesCameraSupportTakingPhotos())")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UI
    fileprivate func setupUI() {
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.distribution = .equalCentering

        let photosViewBtn = UIButton()

        let cameraPhotoBtn = UIButton()
        let playRemoteVideoBtn = UIButton()

        let customCameraBtn = UIButton()
        let remoteImageBtn = UIButton()
        
        let photoEditorBtn = UIButton()
        
        photosViewBtn.setTitle("浏览全部照片（Custom）", for: .normal)
        cameraPhotoBtn.setTitle("照片or相机", for: .normal)
        playRemoteVideoBtn.setTitle("Play remote video", for: .normal)
        customCameraBtn.setTitle("Custom Camera", for: .normal)
        remoteImageBtn.setTitle("Display remote images", for: .normal)
        photoEditorBtn.setTitle("Photo Editor", for: .normal)
        
        photosViewBtn.setTitleColor(.systemBlue, for: .normal)
        cameraPhotoBtn.setTitleColor(.systemBlue, for: .normal)
        playRemoteVideoBtn.setTitleColor(.systemBlue, for: .normal)
        customCameraBtn.setTitleColor(.systemPink, for: .normal)
        remoteImageBtn.setTitleColor(.systemGreen, for: .normal)
        photoEditorBtn.setTitleColor(.systemYellow, for: .normal)

        photosViewBtn.addTarget(self, action: #selector(photosViewButtonClicked(_:)), for: .touchUpInside)
        cameraPhotoBtn.addTarget(self, action: #selector(cameraPhotoButtonClicked(_:)), for: .touchUpInside)
        playRemoteVideoBtn.addTarget(self, action: #selector(playRemoteVideo(_:)), for: .touchUpInside)
        customCameraBtn.addTarget(self, action: #selector(launchCustomCamera(_:)), for: .touchUpInside)
        remoteImageBtn.addTarget(self, action: #selector(displayRemoteImagesButtonClicked(_:)), for: .touchUpInside)
        photoEditorBtn.addTarget(self, action: #selector(photoEditorButtonClicked(_:)), for: .touchUpInside)
        
        stackView.addArrangedSubview(photosViewBtn)
        stackView.addArrangedSubview(cameraPhotoBtn)
        stackView.addArrangedSubview(playRemoteVideoBtn)
        stackView.addArrangedSubview(customCameraBtn)
        stackView.addArrangedSubview(remoteImageBtn)
        stackView.addArrangedSubview(photoEditorBtn)
        
        self.view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 100),
                stackView.widthAnchor.constraint(equalToConstant: 300),
                stackView.heightAnchor.constraint(equalToConstant: 200)
            ])
        } else {
            // Fallback on earlier versions
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100),
                stackView.widthAnchor.constraint(equalToConstant: 300),
                stackView.heightAnchor.constraint(equalToConstant: 200)
            ])
        }
    }
    
// MARK: - Button action
    @objc func photosViewButtonClicked(_ sender: UIButton) {
        var pickerConfig = FYPhotoPickerConfiguration()
        pickerConfig.selectionLimit = 0
        pickerConfig.supportCamera = true
        pickerConfig.mediaFilter = .all
        
        pickerConfig.compressedQuality = .mediumQuality
        pickerConfig.maximumVideoMemorySize = 40 // MB
        pickerConfig.maximumVideoDuration = 15 // Seconds
        let colorConfig = FYColorConfiguration()
        colorConfig.topBarColor = FYColorConfiguration.BarColor(itemTintColor: .red,
                                                                itemDisableColor: .gray,
                                                                itemBackgroundColor: .black,
                                                                backgroundColor: .blue)

        pickerConfig.colorConfiguration = colorConfig
        let photoPickerVC = PhotoPickerViewController(configuration: pickerConfig)
    
        photoPickerVC.selectedPhotos = { [weak self] images in
            print("selected \(images.count) photos: \(images)")
            self?.presentSelectedPhotos(images)
        }
        
        photoPickerVC.selectedVideo = { [weak self] selectedResult in
            switch selectedResult {
            case .success(let video):
                print("selected video: \(video)")
                let previewVideo = VideoPreviewController(videoURL: video.url)
                self?.present(previewVideo, animated: true, completion: nil)
            case .failure(let error):
                print("selected video error: \(error)")
            }
        }
        photoPickerVC.modalPresentationStyle = .fullScreen
        self.present(photoPickerVC, animated: true, completion: nil)
    }

    @objc func cameraPhotoButtonClicked(_ sender: UIButton) {
        var config = PhotoLauncher.PhotoLauncherConfig()
        config.maximumNumberCanChoose = 1
        config.mediaOptions = [.image, .video]
        config.sourceRect = sender.frame
        config.videoPathExtension = "mp4"
        config.videoMaximumDuration = 15
        if #available(iOS 14, *) {
            photoLanucher.showSystemPhotoPickerCameraAlertSheet(in: self, config: config)
        } else {
            photoLanucher.showCustomPhotoPickerCameraAlertSheet(in: self, config: config)            
        }
    }

    @objc func playRemoteVideo(_ sender: UIButton) {
//        guard let url = URL(string: "https://www.radiantmediaplayer.com/media/big-buck-bunny-360p.mp4") else { return }
//        let urlStr = "https://www.radiantmediaplayer.com/media/big-buck-bunny-360p.mp4"
        let urlStr = "https://wolverine.raywenderlich.com/content/ios/tutorials/video_streaming/foxVillage.mp4"
//        let urlStr = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
        guard let url = URL(string: urlStr) else { return }

        let photo = Photo.photoWithURL(url)
        
        let photosDetailVC = PhotoBrowserViewController.create(photos: [photo], initialIndex: 0) {
            $0
                .buildBottomToolBar()
                .buildNavigationBar()
        }
        photosDetailVC.delegate = self
        navigationController?.pushViewController(photosDetailVC, animated: true)
    }

    @objc func launchCustomCamera(_ sender: UIButton) {
        photoLanucher.launchCamera(in: self, captureMode: [.image, .video])
    }
    
    @objc func displayRemoteImagesButtonClicked(_ sender: UIButton) {
        guard let url = URL(string: "https://images.unsplash.com/photo-1546608235-3310a2494cdf?ixlib=rb-1.2.1&ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&auto=format&fit=crop&w=3161&q=80") else {
            return
        }
        let image = Photo.photoWithURL(url)
        let photoBrowser = PhotoBrowserViewController.create(photos: [image], initialIndex: 0)
        photoBrowser.delegate = self
        self.fyphoto.present(photoBrowser, animated: true, completion: nil)
    }
    
    var restoreData: CroppedRestoreData?
    @objc func photoEditorButtonClicked(_ sender: UIButton) {
        
        let vc = CropImageViewController(image: UIImage(named: "sunflower")!, customRatio: [RatioItem(title: "3:20", value: 0.15)], restoreData: restoreData)
        vc.croppedImage = { [weak self] result in
            guard let self = self else { return }
            self.restoreData = vc.restoreData
            switch result {
            case .success(let image):
                let image = Photo.photoWithUIImage(image)
                let photoBrowser = PhotoBrowserViewController.create(photos: [image], initialIndex: 0)
                photoBrowser.delegate = self
                self.fyphoto.present(photoBrowser, animated: true, completion: nil)
            case .failure(let error):
                print("crop image failed with error: \(error)")
            }
        }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: PRESENT SELECTED
    func presentSelectedPhotos(_ images: [SelectedImage]) {
        let photos = images.map { Photo.photoWithUIImage($0.image) }
        let photoBrowser = PhotoBrowserViewController.create(photos: photos, initialIndex: 0)
        self.fyphoto.present(photoBrowser, animated: true, completion: nil)
    }

}

extension ViewController: PhotoLauncherDelegate {
    func selectedVideoInPhotoLauncher(_ video: Result<SelectedVideo, Error>) {
        print("Selected video: \(try? video.get())")
    }
    
    func selectedPhotosInPhotoLauncher(_ photos: [SelectedImage]) {
        print("selected \(photos.count) images")
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print(#function)
        guard let mediaType = info[.mediaType] as? String else { return }
        
        switch mediaType {
        case String(kUTTypeImage):
            guard let image = info[.originalImage] as? UIImage else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            picker.dismiss(animated: true) {
                let photo = Photo.photoWithUIImage(image)
                let detailVC = PhotoBrowserViewController.create(photos: [photo], initialIndex: 0, builder: nil)
//                let detailVC = PhotoBrowserViewController(photos: [photo], initialIndex: 0)
                detailVC.delegate = self
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
        case String(kUTTypeMovie):
            guard
                let videoURL = info[.mediaURL] as? URL
                else {
                    picker.dismiss(animated: true, completion: nil)
                    return
            }
            picker.dismiss(animated: true) {}
        default:
            break
        }


    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            print("🤢\(error)🤮")
        } else {
            print("image saved")
        }
    }

    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            print("🤢\(error)🤮")
        } else {
            print("video saved at: \(videoPath)")
        }
    }

}

extension ViewController: VideoPreviewControllerDelegate {
//    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
//        print(#function)
//        editor.delegate = nil
//        UISaveVideoAtPathToSavedPhotosAlbum(editedVideoPath, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
//        editor.dismiss(animated: true, completion: nil)
//    }
//
    func videoPreviewController(_ preview: VideoPreviewController, didSaveVideoAt path: URL) {
        print(#function)
        preview.delegate = nil
        preview.dismiss(animated: true, completion: nil)
        print("video path: \(path)\npath.path: \(path.path)")
        UISaveVideoAtPathToSavedPhotosAlbum(path.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    func videoPreviewControllerDidCancel(_ preview: VideoPreviewController) {
        preview.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: PhotoBrowserViewControllerDelegate {
    
}

extension ViewController: CameraViewControllerDelegate {
    
    func cameraViewControllerStartAddingWatermark() {
        print("Processing video......")
    }
    
    func camera(_ cameraViewController: CameraViewController, didFinishAddingWatermarkAt path: URL) {
        print("End processing.")
        cameraViewController.dismiss(animated: true) {
            let previewVC = VideoPreviewController(videoURL: path)
            previewVC.delegate = self
            previewVC.modalPresentationStyle = .fullScreen
            self.present(previewVC, animated: true, completion: nil)
        }
    }
    
    func cameraDidCancel(_ cameraViewController: CameraViewController) {
        cameraViewController.dismiss(animated: true, completion: nil)
    }
    
    func camera(_ cameraViewController: CameraViewController, didFinishCapturingMediaInfo info: [CameraViewController.InfoKey : Any]) {
        print(#function)
        guard let mediaType = info[.mediaType] as? String else { return }

        switch mediaType {
//        case "public.image":
        case String(kUTTypeImage):
//            guard let data = info[.mediaMetadata] as? Data else { return }
//            CameraViewController.saveImageDataToAlbums(data) { (error) in
//                if let error = error {
//                    print("🤢\(error)🤮")
//                } else {
//                    print("image saved")
//                }
//
//            }
            // watermark
            guard let image = info[.watermarkImage] as? UIImage else { return }
//            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            CameraViewController.saveImageToAlbums(image) { (result) in
                switch result {
                case .success(_):
                    
                    print("image saved successfully")
                case .failure(let error):
                    print(error)
                }
            }
            cameraViewController.dismiss(animated: true) {
                let photo = Photo.photoWithUIImage(image)
                let detailVC = PhotoBrowserViewController.create(photos: [photo], initialIndex: 0)
                detailVC.delegate = self
                self.navigationController?.fyphoto.pushViewController(detailVC, animated: true)
            }
        case String(kUTTypeMovie):
            guard
                let videoURL = info[.watermarkVideoURL] as? URL
                else {
                cameraViewController.dismiss(animated: true, completion: nil)
                return
            }

            cameraViewController.dismiss(animated: true) {
                let previewVC = VideoPreviewController(videoURL: videoURL)
                previewVC.delegate = self
                self.present(previewVC, animated: true, completion: nil)
            }
        default:
            break
        }
    }
    
    func watermarkImage() -> WatermarkImage? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 3
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.white
        ]
    
        let flightNumber = "航班号： MU5701"
        let parkingNumber = "机位：154"
        let nodeName = "节点名称：加清水"
        let uploadTime = "上传时间：2020-11-25"
        let shooterName = "拍摄人：小明"
        
        let string = String(format: "%@\n%@\n%@\n%@\n%@", flightNumber, parkingNumber, nodeName, uploadTime, shooterName)
        
        let attributedString = NSAttributedString(string: string, attributes: attrs)

//        let feeyoImage = UIImage(named: "variflight")
        
        let waterMarkSize = CGSize(width: 180, height: 95)
        let render = UIGraphicsImageRenderer(size: waterMarkSize)
        let renderedImage = render.image { (ctx) in
            ctx.cgContext.setFillColor(UIColor(white: 0, alpha: 0.1).cgColor)
//            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
//            ctx.cgContext.setLineWidth(10)
            ctx.cgContext.addRect(CGRect(origin: .zero, size: waterMarkSize))
            ctx.cgContext.drawPath(using: .fill)

            attributedString.draw(in: CGRect(x: 10, y: 5, width: waterMarkSize.width, height: waterMarkSize.height - 8))
//            feeyoImage?.draw(in: CGRect(x: 0, y: 35, width: 64, height: 15))
            
        }
        return WatermarkImage(image: renderedImage, frame: CGRect(x: 15, y: view.frame.size.height - 15, width: waterMarkSize.width, height: waterMarkSize.height))
    }
}

extension ViewController: VideoTrimmerViewControllerDelegate {
    func videoTrimmerDidCancel(_ videoTrimmer: VideoTrimmerViewController) {
        videoTrimmer.dismiss(animated: true, completion: nil)
    }
    
    func videoTrimmer(_ videoTrimmer: VideoTrimmerViewController, didFinishTrimingAt url: URL) {
        print("trimmed video url: \(url)")
    }
}
