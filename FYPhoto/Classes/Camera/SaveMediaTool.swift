//
//  SaveMediaTool.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/20.
//

import Foundation
import Photos

class SaveMediaTool {
	
	static let shared = SaveMediaTool()
	
	// CS Singleton -> You may only have one instance of the class
	// Apple Singletons -> Shared static variables
	init() { }
	
    enum SaveMediaError: Error, LocalizedError {
        case withoutAuthourity
		case couldNotPerformChanges(Error)
		
		public var errorDescription: String? {
			switch self {
			case .withoutAuthourity:
				return L10n.noPermissionToSave
			case .couldNotPerformChanges:
				return L10n.performImageChangeFailed
			}
		}
    }
    
	/// Save the given image data to PHPhotoLibrary default album. Calling this function will request authorization to access the user's photo library, so NSCameraUsageDescription, NSPhotoLibraryUsageDescription and NSMicrophoneUsageDescription should already be set in the Info.plist file.
	///
	/// Photo formats accepted by PHPhotoLibrary are currently unknown, so be aware that passing image data may return an error if the image data is unsupported by PHPhotoLibrary.
	///
	/// - Parameters:
	///   - photoData: data representing an image accepted by PHPhotoLibrary
	///   - completion: called on the main queue when the image is saved or a `SaveMediaError` occurs.
    func saveImageDataToAlbums(_ photoData: Data, completion: @escaping ((Result<Void, SaveMediaError>) -> Void)) {
        PHPhotoLibrary.requestAuthorization { status in
			
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                }, completionHandler: { _, error in
                    DispatchQueue.main.async {
                        if let error = error {
							completion(.failure(.couldNotPerformChanges(error)))
                            print("Error occurred while saving photo to photo library: \(error)")
                        } else {
                            completion(.success(()))
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(.failure(SaveMediaError.withoutAuthourity))
                }
            }
        }
    }

    func saveImageToAlbums(_ image: UIImage, completion: @escaping ((Result<Void, Error>) -> Void)) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
//                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    if let data = image.jpegData(compressionQuality: 1) {
                        creationRequest.addResource(with: .photo, data: data, options: options)
                    }
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }                    
                })
            } else {
                DispatchQueue.main.async {
                    completion(.failure(SaveMediaError.withoutAuthourity))
                }
                
            }
        }
    }
    
    func saveVideoDataToAlbums(_ videoPath: URL, completion: @escaping ((Result<Void, Error>) -> Void)) {
        // Check the authorization status.
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Save the movie file to the photo library and cleanup.
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: videoPath, options: options)
                }, completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                    if !success {
                        print("FYPhoto couldn't save the movie to your photo library: \(String(describing: error))")
                    }
                    
                })
            } else {
                DispatchQueue.main.async {
                    completion(.failure(SaveMediaError.withoutAuthourity))
                }
            }
        }
    }
}
