//
//  PhotoBrowserViewController+PlayVideo.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/6/23.
//

import Foundation
import Photos

extension PhotoBrowserViewController {
    func setupPlayer(photo: PhotoProtocol, for cell: VideoDetailCell) {
        if let asset = photo.asset {
            setupPlayer(asset: asset, for: cell.playerView)
            cell.photo = photo
        } else if let url = photo.url {
            cell.startLoading()
            setupPlayer(url: url, for: cell.playerView, completion: { url in
                if let url = url {
                    photo.generateThumbnail(url, size: .zero) { result in
                        cell.endLoading()
                        let image: UIImage
                        switch result {
                        case .success(let thumbnail):
                            image = thumbnail
                        case .failure(let error):
                            image = Asset.imageError.image
                            #if DEBUG
                            print("❌ generate thumbnail failed: \(error)")
                            #endif
                        }
                        let videoThumbnail = Photo.photoWithUIImage(image)
                        cell.photo = videoThumbnail
                    }
                } else {
                    let videoThumbnail = Photo.photoWithUIImage(Asset.imageError.image)
                    cell.photo = videoThumbnail
                }
            })
        }
    }

    fileprivate func setupPlayer(asset: PHAsset, for playerView: PlayerView) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, error, stop, info in
            print("request video from icloud progress: \(progress)")
        }
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { (item, info) in
            if let item = item {
                let player = self.preparePlayer(with: item)
                playerView.player = player
                self.player = player
            }
        }
    }
    
    fileprivate func setupPlayer(url: URL, for playerView: PlayerView, completion: @escaping ((URL?) -> Void)) {
        if url.isFileURL {
            setupPlayerView(url, playerView: playerView)
            completion(url)
        } else {
            if let cache = videoCache {
                cache.fetchFilePathWith(key: url) { (result) in
                    switch result {
                    case .success(let filePath):
                        self.setupPlayerView(filePath, playerView: playerView)
                        completion(filePath)
                    case .failure(let error):
                        self.showError(error)
                        print("FYPhoto fetch url error: \(error)")
                        completion(nil)
                    }
                }
            } else {
                setupPlayerView(url, playerView: playerView)
                completion(url)
            }
        }
    }
    
    fileprivate func setupPlayerView(_ url: URL, playerView: PlayerView) {
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: self.assetKeys)
        let player = self.preparePlayer(with: playerItem)
        playerView.player = player
        self.player = player
    }
    
    fileprivate func preparePlayer(with playerItem: AVPlayerItem) -> AVPlayer {
        if let currentItem = mPlayerItem {
            playerItemStatusToken?.invalidate()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        self.mPlayerItem = playerItem
        // observing the player item's status property
        playerItemStatusToken = playerItem.observe(\.status, options: .new) { (item, change) in
            // Switch over status value
            switch change.newValue {
            case .readyToPlay:
                print("Player item is ready to play.")
            // Player item is ready to play.
            case .failed:
                print("Player item failed. See error.")
            // Player item failed. See error.
            case .unknown:
                print("unknown status")
            // Player item is not yet ready.
            case .none:
                break
            @unknown default:
                fatalError()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        seekToZeroBeforePlay = false
        // Associate the player item with the player

        if let player = self.player {
            player.pause()
            player.replaceCurrentItem(with: playerItem)
            return player
        } else {
            return AVPlayer(playerItem: playerItem)
        }
    }

    func playVideo() {
        guard let player = player else { return }
        if seekToZeroBeforePlay {
            seekToZeroBeforePlay = false
            player.seek(to: .zero)
        }

        player.play()
        isPlaying = true
    }

    func pauseVideo() {
        player?.pause()
        isPlaying = false
    }

     func stopPlayingIfNeeded() {
        guard let player = player, isPlaying else {
            return
        }
        player.pause()
        player.seek(to: .zero)
        isPlaying = false
    }
    
    func stopPlayingVideoIfNeeded(at oldIndexPath: IndexPath) {
        if isPlaying {
            stopPlayingIfNeeded()
        }
    }
    
    // MARK: Target action
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        isPlaying = false
        seekToZeroBeforePlay = true
    }
}
