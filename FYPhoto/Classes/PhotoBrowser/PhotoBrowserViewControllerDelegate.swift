//
//  PhotoDetailCollectionViewControllerDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/21.
//

import Foundation
import Photos

public protocol PhotoBrowserViewControllerDelegate: AnyObject {
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt item: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String])
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol])
 
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, longPressedOnPhoto photo: PhotoProtocol)
    
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, saveMediaCompletedWith error: Error?)
    
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, editedPhotos: [String: CroppedRestoreData])
}

public extension PhotoBrowserViewControllerDelegate {

    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt item: Int) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, editedPhotos: [String: CroppedRestoreData]) { }
}

public extension PhotoBrowserViewControllerDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, longPressedOnPhoto photo: PhotoProtocol) {
        alertSavePhoto(photo, on: photoBrowser)
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, saveMediaCompletedWith error: Error?) {
        if let error = error {
            photoBrowser.showError(error)
        } else {
            photoBrowser.showMessage(L10n.successfullySavedMedia)
        }        
    }
    
    func alertSavePhoto(_ photo: PhotoProtocol, on viewController: PhotoBrowserViewController) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actionTitle = photo.isVideo ? L10n.saveVideo : L10n.savePhoto
        let saveAction = UIAlertAction(title: actionTitle, style: .default) { (_) in
            self.savePhotoToLibrary(photo, with: viewController)
        }
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        viewController.present(alertController, animated: true, completion: nil)        
    }
    
    func savePhotoToLibrary(_ photo: PhotoProtocol, with viewController: PhotoBrowserViewController) {        
        if photo.isVideo, let url = photo.url {
            VideoCache.shared?.fetchFilePathWith(key: url, completion: { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let filePath):
                    SaveMediaTool.saveVideoDataToAlbums(filePath) { (result) in
                        switch result {
                        case .failure(let error):
                            self.photoBrowser(viewController, saveMediaCompletedWith: error)
                        case .success(_):
                            self.photoBrowser(viewController, saveMediaCompletedWith: nil)
                        }
                    }
                case .failure(let error):
                    self.photoBrowser(viewController, saveMediaCompletedWith: error)
                }
            })
        } else if let image = photo.image {
            SaveMediaTool.saveImageToAlbums(image) { (result) in
                switch result {
                case .failure(let error):
                    self.photoBrowser(viewController, saveMediaCompletedWith: error)
                case .success(_):
                    self.photoBrowser(viewController, saveMediaCompletedWith: nil)
                }                
            }
        }
    }
        
}
