//
//  GridViewCell.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/7/15.
//

import UIKit

import UIKit

protocol GridViewCellDelegate: class {
    func gridCell(_ cell: GridViewCell, buttonClickedAt indexPath: IndexPath, assetIdentifier: String)
}

class GridViewCell: UICollectionViewCell {

    var imageView = UIImageView()
    var livePhotoBadgeImageView = UIImageView()
    var videoDurationLabel = UILabel()

    var selectionButton = UIButton()
    var overlayView = UIView()

    var representedAssetIdentifier: String!

    weak var delegate: GridViewCellDelegate?

    var indexPath: IndexPath?

    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }

    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
            isVideoAsset = false
        }
    }

    var videoDuration: String! {
        didSet {
            videoDurationLabel.text = videoDuration
            isVideoAsset = true
        }
    }

    var isVideoAsset: Bool = false {
        didSet {
            selectionButton.isHidden = isVideoAsset
        }
    }
    
    var isEnable: Bool = false {
        willSet {
            overlayView.isHidden = newValue
            isUserInteractionEnabled = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        livePhotoBadgeImageView.image = nil
        selectionButton.setImage(Asset.imageSelectedSmallOff.image, for: .normal)
        indexPath = nil
        isVideoAsset = false
    }
    
    func setupUI() {
//        contentView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        videoDurationLabel.font = UIFont.systemFont(ofSize: 11, weight: .light)
        videoDurationLabel.textColor =  .white

        selectionButton.setImage(Asset.imageSelectedSmallOff.image, for: .normal)
        selectionButton.addTarget(self, action: #selector(selectionButtonClicked(_:)), for: .touchUpInside)

        selectionButton.layer.masksToBounds = true
        selectionButton.layer.cornerRadius = 16

        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        overlayView.isHidden = true

        contentView.addSubview(imageView)
        contentView.addSubview(livePhotoBadgeImageView)
        contentView.addSubview(videoDurationLabel)
        contentView.addSubview(selectionButton)
        contentView.addSubview(overlayView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        livePhotoBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        videoDurationLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            livePhotoBadgeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            livePhotoBadgeImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            livePhotoBadgeImageView.widthAnchor.constraint(equalToConstant: 28),
            livePhotoBadgeImageView.heightAnchor.constraint(equalToConstant: 28)
        ])

        NSLayoutConstraint.activate([
            videoDurationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            videoDurationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
        ])

        NSLayoutConstraint.activate([
            selectionButton.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            selectionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
            selectionButton.widthAnchor.constraint(equalToConstant: 32),
            selectionButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

    }

    @objc func selectionButtonClicked(_ sender: UIButton) {
        if let indexPath = indexPath {
            delegate?.gridCell(self, buttonClickedAt: indexPath, assetIdentifier: representedAssetIdentifier)
        } else {
            assertionFailure("indexpath couldn't be nil!")
        }
    }

    /// change button style: image or number
    /// - Parameter title: if title is empty, button display cirle image, otherwise, button display number string.
    func displayButtonTitle(_ title: String) {
        if title.isEmpty {
            selectionButton.setImage(Asset.imageSelectedSmallOff.image, for: .normal)
            selectionButton.setTitle(title, for: .normal)
            selectionButton.backgroundColor = .clear
        } else {
            selectionButton.setImage(nil, for: .normal)
            selectionButton.setTitle(title, for: .normal)
            selectionButton.backgroundColor = UIColor(red: 24/255.0, green: 135/255.0, blue: 251/255.0, alpha: 1)
        }
    }
    
}