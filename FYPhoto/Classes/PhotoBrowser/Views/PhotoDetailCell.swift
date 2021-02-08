//
//  PhotoDetailCell.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/27.
//

import UIKit
import Photos

class PhotoDetailCell: UICollectionViewCell, CellWithPhotoProtocol {
    static let reuseIdentifier = "PhotoDetailCell"
    
    let zoomingView = ZoomingScrollView(frame: .zero)    

    var image: UIImage? {
        zoomingView.imageView.image ?? Asset.coverPlaceholder.image
    }

    var photo: PhotoProtocol? {
        didSet {
            zoomingView.photo = photo
        }
    }
    
    var maximumZoomScale: CGFloat = 1 {
        willSet {
            zoomingView.maximumZoomScale = newValue
        }
    }

    var minimumZoomScale: CGFloat = 1 {
        willSet {
            zoomingView.minimumZoomScale = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(zoomingView)
        contentView.backgroundColor = .black
        zoomingView.delegate = self
        zoomingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            zoomingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            zoomingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            zoomingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        zoomingView.imageView.image = nil
    }

}

extension PhotoDetailCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomingView.imageView
    }
}