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

class ViewController: UIViewController {

    var stackView = UIStackView()
    let photoLanucher = PhotoLauncher()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)


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
        let suishoupaiBtn = UIButton()

        let cameraPhotoBtn = UIButton()

        photosViewBtn.setTitle("浏览全部照片", for: .normal)
        suishoupaiBtn.setTitle("随手拍", for: .normal)
        cameraPhotoBtn.setTitle("照片or相机", for: .normal)

        photosViewBtn.setTitleColor(.systemBlue, for: .normal)
        suishoupaiBtn.setTitleColor(.systemBlue, for: .normal)
        cameraPhotoBtn.setTitleColor(.systemBlue, for: .normal)

        photosViewBtn.addTarget(self, action: #selector(photosViewButtonClicked(_:)), for: .touchUpInside)
        suishoupaiBtn.addTarget(self, action: #selector(suiShouPaiButtonClicked(_:)), for: .touchUpInside)
        cameraPhotoBtn.addTarget(self, action: #selector(cameraPhotoButtonClicked(_:)), for: .touchUpInside)

        stackView.addArrangedSubview(photosViewBtn)
        stackView.addArrangedSubview(suishoupaiBtn)
        stackView.addArrangedSubview(cameraPhotoBtn)

        self.view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 300),
                stackView.widthAnchor.constraint(equalToConstant: 200),
                stackView.heightAnchor.constraint(equalToConstant: 200)
            ])
        } else {
            // Fallback on earlier versions
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 300),
                stackView.widthAnchor.constraint(equalToConstant: 200),
                stackView.heightAnchor.constraint(equalToConstant: 200)
            ])
        }

//        let imageController = UIImagePickerController()
//        imageController.sourceType = .camera
//        imageController.cameraCaptureMode = .photo
//        print("available media types: \(UIImagePickerController.availableMediaTypes(for: .camera))")
    }

// MARK: - Button action
    @objc func photosViewButtonClicked(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    let gridVC = AssetGridViewController(maximumToSelect: 6, isOnlyImages: false)
                    gridVC.selectedPhotos = { [weak self] images in
                        print("selected \(images.count) photos: \(images)")
                    }
//                    let navi = CustomNavigationController(rootViewController: gridVC)
                    let navi = UINavigationController(rootViewController: gridVC)
                    navi.modalPresentationStyle = .fullScreen
                    self.present(navi, animated: true, completion: nil)
//                    self.navigationController?.navigationBar.tintColor = .white
//                    self.navigationController?.pushViewController(gridVC, animated: true)

                case .denied, .restricted, .notDetermined:
                    print("⚠️ without authorization! ⚠️")
                @unknown default:
                    fatalError()
                }
            }

        }
    }

    @objc func suiShouPaiButtonClicked(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    let addPhotoVC = AddPhotoBlogViewController()
                    addPhotoVC.selectedImageArray = []
                    self.navigationController?.pushViewController(addPhotoVC, animated: true)
                    //                            let navi = CustomTransitionNavigationController(rootViewController: addPhotoVC)
                    //                            navi.modalPresentationStyle = .fullScreen
                //                            self.present(navi, animated: true, completion: nil)
                case .denied, .restricted, .notDetermined:
                    print("⚠️ without authorization! ⚠️")
                @unknown default:
                    fatalError()
                }
            }

        }
    }

    @objc func cameraPhotoButtonClicked(_ sender: UIButton) {
        photoLanucher.delegate = self
        photoLanucher.showImagePickerAlertSheet(in: self, sourceRect: sender.frame, maximumNumberCanChoose: 6, isOnlyImages: true)
    }

    @objc func screenshotTaken(_ noti: Notification) {
        print("screenshot taken!")
        print(noti)

    }
}

extension ViewController: PhotoLauncherDelegate {
    func selectedPhotosInPhotoLauncher(_ photos: [UIImage]) {
        print("selected \(photos.count) images")
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print(#function)
        guard let mediaType = info[.mediaType] as? String else { return }

        switch mediaType {
        case "public.image":
            guard let image = info[.originalImage] as? UIImage else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            picker.dismiss(animated: true, completion: nil)
        case "public.movie":
            guard
                let videoURL = info[.mediaURL] as? URL

                else {
                    picker.dismiss(animated: true, completion: nil)
                    return
            }
//            UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)

            picker.dismiss(animated: true) {
//                 Editor controller
                guard UIVideoEditorController.canEditVideo(atPath: videoURL.absoluteString) else { return }
                let videoEditorController = UIVideoEditorController()
                videoEditorController.videoPath = videoURL.path
                videoEditorController.delegate = self
                videoEditorController.videoMaximumDuration = 15
                videoEditorController.modalPresentationStyle = .fullScreen
                self.present(videoEditorController, animated: true, completion: nil)
            }
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
            print("video saved")
        }
    }

}

extension ViewController: UIVideoEditorControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        print(#function)
        editor.delegate = nil
        UISaveVideoAtPathToSavedPhotosAlbum(editedVideoPath, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        editor.dismiss(animated: true, completion: nil)
    }

}
