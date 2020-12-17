//
//  PhotoDetailCollectionViewController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/27.
//

import UIKit
import Photos
import MobileCoreServices

public class PhotoBrowserViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public class Builder {
        let photos: [PhotoProtocol]
        let initialIndex: Int
        
        var selectedPhotos: [PhotoProtocol] = []
        var maximumCanBeSelected: Int = 6
        var isForSelection = false
        var supportThumbnails = true
        var supportCaption = false
        var supportNavigationBar = true
        var supportBottomToolBar = true
        
        public init(photos: [PhotoProtocol], initialIndex: Int) {
            self.photos = photos
            self.initialIndex = initialIndex
        }
        
        public func setSelectedPhotos(_ selected: [PhotoProtocol]) -> Self {
            selectedPhotos = selected
            return self
        }
        
        public func setMaximumCanBeSelected(_ maximum: Int) -> Self {
            maximumCanBeSelected = maximum
            return self
        }
        
        public func buildForSelection(_ isForSelection: Bool) -> Self {
            self.isForSelection = isForSelection
            return self
        }
        
        public func supportThumbnails(_ supportThumbnails: Bool) -> Self {
            self.supportThumbnails = supportThumbnails
            return self
        }
        
        public func supportCaption(_ supportCaption: Bool) -> Self {
            self.supportCaption = supportCaption
            return self
        }
        
        public func supportNavigationBar(_ supportNavigationBar: Bool) -> Self {
            self.supportNavigationBar = supportNavigationBar
            return self
        }
        
        public func supportBottomToolBar(_ supportBottomToolBar: Bool) -> Self {
            self.supportBottomToolBar = supportBottomToolBar
            return self
        }
        
        public func quickBuildForSelection(_ selected: [PhotoProtocol], maximumCanBeSelected: Int) -> Self {
            isForSelection = true
            supportThumbnails = true
            supportNavigationBar = true
            supportBottomToolBar = true
            supportCaption = false
            self.maximumCanBeSelected = maximumCanBeSelected
            self.selectedPhotos = selected
            return self
        }
        
        func quickBuildJustForBrowser() -> Self {
            isForSelection = false
            supportThumbnails = false
            supportNavigationBar = true
            supportBottomToolBar = true
            supportCaption = true
            self.maximumCanBeSelected = 0
            self.selectedPhotos = []
            return self
        }
        
        public func build() -> PhotoBrowserViewController {
            let photoBrowser = PhotoBrowserViewController(photos: self.photos, initialIndex: self.initialIndex)
            photoBrowser.selectedPhotos = selectedPhotos
            photoBrowser.maximumCanBeSelected = maximumCanBeSelected
            photoBrowser.isForSelection = isForSelection
            photoBrowser.supportThumbnails = supportThumbnails
            photoBrowser.supportCaption = supportCaption
            photoBrowser.supportNavigationBar = supportNavigationBar
            photoBrowser.supportBottomToolBar = supportBottomToolBar
            return photoBrowser
        }
    }
    
    private let photoCellReuseIdentifier = "PhotoDetailCell"
    private let videoCellReuseIdentifier = "VideoDetailCell"
    private let selectedThumbnailsReuseIdentifier = "PBSelectedPhotosThumbnailCell"

    public weak var delegate: PhotoBrowserViewControllerDelegate?

    // bar item
    fileprivate var doneBarItem: UIBarButtonItem!
    fileprivate var addPhotoBarItem: UIBarButtonItem!
    fileprivate var playVideoBarItem: UIBarButtonItem!
    fileprivate var pauseVideoBarItem: UIBarButtonItem!

    fileprivate var mainCollectionView: UICollectionView!

    /// 底部标题
    fileprivate lazy var captionView = CaptionView()

    fileprivate var playBarItemsIsShowed = false

    fileprivate var initialScrollDone = false

    fileprivate let addLocalizedString = "add".photoTablelocalized

    fileprivate var previousNavigationBarHidden: Bool?
    fileprivate var previousToolBarHidden: Bool?
    fileprivate var previousInteractivePop: Bool?
    fileprivate var previousNavigationTitle: String?
    fileprivate var previousAudioCategory: AVAudioSession.Category?

    fileprivate var originCaptionTransform: CGAffineTransform!

    fileprivate var mainFlowLayout: UICollectionViewFlowLayout? {
        return mainCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }

    fileprivate var assetSize: CGSize?

    fileprivate var resized = false

    // MARK: Video properties
    var player: AVPlayer?
    var mPlayerItem: AVPlayerItem?
    var isPlaying = false {
        willSet {
            if currentPhoto.isVideo {
                updateToolBarItems(isPlaying: newValue)
            }
        }
    }
    let assetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    var playerItemStatusToken: NSKeyValueObservation?

    /// After the movie has played to its end time, seek back to time zero
    /// to play it again.
    private var seekToZeroBeforePlay: Bool = false

    fileprivate var currentDisplayedIndexPath: IndexPath {
        willSet {
            stopPlayingIfNeeded()
            currentPhoto = photos[newValue.item]
            if currentDisplayedIndexPath != newValue {
                delegate?.photoBrowser(self, scrollAt: newValue)
            }
            if isForSelection {
                updateAddBarItem(at: newValue)
            }
            if supportCaption {
                updateCaption(at: newValue)
            }
            if supportThumbnails {
                if isScrollingMainPhotos {
                    updateThumbnails(at: newValue)
                }
            }
            updateNavigationTitle(at: newValue)
            stopPlayingVideoIfNeeded(at: currentDisplayedIndexPath)
        }
    }
    
    var selectedThumbnailIndexPath: IndexPath? {
        willSet {
            guard isThumbnailIndexPathInitialized else {
                return
            }
            guard newValue != selectedThumbnailIndexPath else {
                return
            }
            guard let idx = newValue else {
                if selectedThumbnailIndexPath != nil { // 有值 -> 无值 取消 thumbnail selected 状态
                    thumbnailsCollectionView.reloadData()
                }
                return
            }
            // 处理滑动主 collectionView 照片， 如果thubnails 里面有，刷新cell，改变 selected 状态
            thumbnailsCollectionView.reloadData()
            guard !isScrollingMainPhotos else { // 点击 thumbnail
                return
            }
                        
            // 处理点击thumbnail collectionView cell， 滑动主 collectionView
            let thumbnailPhoto = selectedPhotos[idx.item]
            let mainPhoto = photos[currentDisplayedIndexPath.item]
            if !thumbnailPhoto.isEqualTo(mainPhoto), mainCollectionView.superview != nil {
                if let firstIndex = firstIndexOfPhoto(thumbnailPhoto, in: photos) { // 点击thumbnail cell 滑动主collectionView
                    let mainPhotoIndexPath = IndexPath(item: firstIndex, section: 0)
                    mainCollectionView.scrollToItem(at: mainPhotoIndexPath, at: .centeredHorizontally, animated: true)
                    currentDisplayedIndexPath = mainPhotoIndexPath
                }
            }
        }
        didSet {
            if !isThumbnailIndexPathInitialized {
                isThumbnailIndexPathInitialized = true
            }
        }
    }
    // 避免 main photo 与 thumbnail indexpath 循环调用
    fileprivate var isScrollingMainPhotos = false
    
    fileprivate var currentPhoto: PhotoProtocol {
        willSet {
            if newValue.isVideo {
                // tool bar items
                if !playBarItemsIsShowed {
                    updateToolBar(shouldShowDone: isForSelection, shouldShowPlay: true)
                    playBarItemsIsShowed = true
                } else {
                    updateToolBarItems(isPlaying: isPlaying)
                }
            } else {
                updateToolBar(shouldShowDone: isForSelection, shouldShowPlay: false)
                playBarItemsIsShowed = false
            }
        }
    }
    
    fileprivate var isThumbnailIndexPathInitialized = false
    
    // main data source
    var selectedPhotos: [PhotoProtocol] = [] {
        didSet {
            let assetIdentifiers = selectedPhotos.compactMap { $0.asset?.localIdentifier }
            delegate?.photoBrowser(self, selectedAssets: assetIdentifiers)
            if supportThumbnails {
                if !selectedPhotos.isEmpty {
                    if !isThumbnailIndexPathInitialized {
                        let initialPhoto = photos[initialIndex]
                        if let photoIndexInSelectedPhotos = firstIndexOfPhoto(initialPhoto, in: selectedPhotos) {
                            let initialIndexPathInThumbnails = IndexPath(item: photoIndexInSelectedPhotos, section: 0)
                            selectedThumbnailIndexPath = initialIndexPathInThumbnails
                        }
                    } else {
                        return selectedThumbnailIndexPath = IndexPath(item: selectedPhotos.count - 1, section: 0)
                    }
                } else {
                    selectedThumbnailIndexPath = nil
                }
            }
        }
    }

    /// the maximum number of photos you can select
    var maximumCanBeSelected: Int = 0
    fileprivate let photos: [PhotoProtocol]
    fileprivate let initialIndex: Int
    
    var isForSelection = false
    var supportThumbnails = true
    var supportCaption = false
    var supportNavigationBar = false
    var supportBottomToolBar = false
    
    // MARK: - Function
    
    // MARK: LifeCycle`
    /// PhotoBrowserViewController initialization.
    /// - Parameters:
    ///   - photos: data source to show
    ///   - initialIndex: first show the photo you clicked
    public init(photos: [PhotoProtocol], initialIndex: Int) {
        self.photos = photos
        self.initialIndex = initialIndex
        currentDisplayedIndexPath = IndexPath(row: initialIndex, section: 0)
        currentPhoto = photos[currentDisplayedIndexPath.item]
//        flowLayout.itemSize = frame.size
        super.init(nibName: nil, bundle: nil)
        
        mainCollectionView = generateMainCollectionView()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        playerItemStatusToken?.invalidate()
        player?.pause()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        view.backgroundColor = UIColor.white
        edgesForExtendedLayout = .all

        cachePreviousData()
        
        addSubviews()
        
        setupCollectionView()

        setupNavigationBar()
        setupNavigationToolBar()
        
        makeConstraints()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.setNavigationBarHidden(!supportNavigationBar, animated: true)
        self.navigationController?.setToolbarHidden(!supportBottomToolBar, animated: false)

        originCaptionTransform = captionView.transform
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(mainCollectionView.contentOffset)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayingIfNeeded()
        restoreNavigationControllerData()
    }

    fileprivate func cachePreviousData() {
        previousToolBarHidden = self.navigationController?.toolbar.isHidden
        previousNavigationBarHidden = self.navigationController?.navigationBar.isHidden
        previousInteractivePop = self.navigationController?.interactivePopGestureRecognizer?.isEnabled
        previousNavigationTitle = self.navigationController?.navigationItem.title
        previousAudioCategory = AVAudioSession.sharedInstance().category
    }
    
    // MARK: Setup
    
    func addSubviews() {
        addCollectionView()
        if supportThumbnails {
            addThumbnailCollectionView()
        }
        if supportCaption {
            addCaptionView()
        }
    }
    
    func generateMainCollectionView() -> UICollectionView {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 20
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.scrollDirection = .horizontal
        return UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }
    
    func generateThumbnailsCollectionView() -> UICollectionView {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 50, height: 50)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        return UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }
    
    func setupCollectionView() {
        mainCollectionView.register(PhotoDetailCell.self, forCellWithReuseIdentifier: photoCellReuseIdentifier)
        mainCollectionView.register(VideoDetailCell.self, forCellWithReuseIdentifier: videoCellReuseIdentifier)
        mainCollectionView.isPagingEnabled = true
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self
//        collectionView.backgroundColor = .white
        mainCollectionView.contentInsetAdjustmentBehavior = .never
    }

    func setupNavigationBar() {
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if isForSelection {
            addPhotoBarItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(PhotoBrowserViewController.addPhotoBarItemClicked(_:)))
            addPhotoBarItem.title = addLocalizedString
            addPhotoBarItem.tintColor = .black
            self.navigationItem.rightBarButtonItem = addPhotoBarItem
        }
        updateNavigationTitle(at: currentDisplayedIndexPath)
    }

    func setupNavigationToolBar() {
        guard supportBottomToolBar else { return }
        playVideoBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play, target: self, action: #selector(PhotoBrowserViewController.playVideoBarItemClicked(_:)))
        pauseVideoBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.pause, target: self, action: #selector(PhotoBrowserViewController.playVideoBarItemClicked(_:)))

        var showVideoPlay = false
        if currentPhoto.isVideo {
            showVideoPlay = true
        }
        
        if isForSelection {
            doneBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(PhotoBrowserViewController.doneBarButtonClicked(_:)))
            doneBarItem.isEnabled = !selectedPhotos.isEmpty
        }

        updateToolBar(shouldShowDone: isForSelection, shouldShowPlay: showVideoPlay)
    }

    fileprivate func restoreNavigationControllerData() {
        if let title = previousNavigationTitle {
            navigationItem.title = title
        }

        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = previousInteractivePop ?? true

        if let originalIsNavigationBarHidden = previousNavigationBarHidden {
            navigationController?.setNavigationBarHidden(originalIsNavigationBarHidden, animated: false)
        }
        // Drag to dismiss quickly canceled, may result in a navigation hide animation bug
        if let originalToolBarHidden = previousToolBarHidden {
            //            navigationController?.setToolbarHidden(originalToolBarHidden, animated: false)
            navigationController?.isToolbarHidden = originalToolBarHidden
        }

        if let audioCategory = previousAudioCategory {
            try? AVAudioSession.sharedInstance().setCategory(audioCategory)
        }
    }

    // selected photo thumbnail collectionView
    lazy var thumbnailsCollectionView: UICollectionView = {
        let collectionView = generateThumbnailsCollectionView()
        collectionView.register(PBSelectedPhotosThumbnailCell.self, forCellWithReuseIdentifier: selectedThumbnailsReuseIdentifier)
        collectionView.isPagingEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
//        collectionView.backgroundColor = .white
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()
        
    func addThumbnailCollectionView() {
        view.addSubview(thumbnailsCollectionView)
        let safeAreaLayoutGuide = self.view.safeAreaLayoutGuide
        thumbnailsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailsCollectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 0),
            thumbnailsCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
            thumbnailsCollectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
            thumbnailsCollectionView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func addCaptionView() {
        view.addSubview(captionView)
        let safeAreaLayoutGuide = self.view.safeAreaLayoutGuide
        captionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            captionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            captionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
        ])
    }
    
    func addCollectionView() {
        view.addSubview(mainCollectionView)
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainCollectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mainCollectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    func makeConstraints() {
        
    }
    
    func hideCaptionView(_ flag: Bool, animated: Bool = true) {
        if flag { // hide
            let transition = CGAffineTransform(translationX: 0, y: captionView.bounds.height)
            if animated {
                UIView.animate(withDuration: 0.2, animations: {
                    self.captionView.transform = transition
                }) { (_) in
                    self.captionView.isHidden = true
                }
            } else {
                captionView.transform = transition
                captionView.isHidden = true
            }
        } else { // show
            captionView.isHidden = false
            if animated {
                UIView.animate(withDuration: 0.3) {
                    self.captionView.transform = self.originCaptionTransform
                }
            } else {
                self.captionView.transform = originCaptionTransform
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if collectionView == self.mainCollectionView {
            return photos.count
        } else { // selected photos thumnail collectionView
            return selectedPhotos.count
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.mainCollectionView {
            let photo = photos[indexPath.item]
            if photo.isVideo {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: videoCellReuseIdentifier, for: indexPath) as? VideoDetailCell {
                    return cell
                }
            } else {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellReuseIdentifier, for: indexPath) as? PhotoDetailCell {
                    cell.maximumZoomScale = 2
                    return cell
                }
            }
        } else { // thumbnails
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: selectedThumbnailsReuseIdentifier, for: indexPath) as? PBSelectedPhotosThumbnailCell {
                cell.photo = selectedPhotos[indexPath.item]
                if let selectedIdx = selectedThumbnailIndexPath {
                    cell.thumbnailIsSelected = indexPath == selectedIdx
                } else {
                    cell.thumbnailIsSelected = false
                }
                return cell
            }
        }
        
        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        stopPlayingVideoIfNeeded(at: currentDisplayedIndexPath)
        var photo = photos[indexPath.item]
        photo.targetSize = assetSize
        if photo.isVideo {
            if let videoCell = cell as? VideoDetailCell {
                videoCell.photo = photo
                // setup video player
                setupPlayer(photo: photo, for: videoCell.playerView)
            }
        } else {
            if let photoCell = cell as? PhotoDetailCell {
                photoCell.setPhoto(photo)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.thumbnailsCollectionView {
            isScrollingMainPhotos = false
            selectedThumbnailIndexPath = indexPath
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Device rotating
        // Instruct collection view how to handle changes in page size

        recalculateItemSize(inBoundingSize: size)
        if view.window == nil {
            view.frame = CGRect(origin: view.frame.origin, size: size)
            view.layoutIfNeeded()
        } else {
            let indexPath = self.mainCollectionView.indexPathsForVisibleItems.last
            coordinator.animate(alongsideTransition: { ctx in
                self.mainCollectionView.layoutIfNeeded()
                if let indexPath = indexPath {
                    self.mainCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                }
            }, completion: { _ in

            })
        }

        super.viewWillTransition(to: size, with: coordinator)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.mainCollectionView.frame != view.frame.insetBy(dx: -10.0, dy: 0.0) {
            self.mainCollectionView.frame = view.frame.insetBy(dx: -10.0, dy: 0.0)
        }
        if !resized && view.bounds.size != .zero {
            resized = true
            recalculateItemSize(inBoundingSize: view.bounds.size)
        }

        if (!self.initialScrollDone) {
            self.initialScrollDone = true
            self.mainCollectionView.scrollToItem(at: currentDisplayedIndexPath, at: .centeredHorizontally, animated: false)
            if isForSelection {
                updateAddBarItem(at: currentDisplayedIndexPath)
            }
            if supportCaption {
                updateCaption(at: currentDisplayedIndexPath)
            }
        }
    }

    // MARK: -Bar item actions
    @objc func doneBarButtonClicked(_ sender: UIBarButtonItem) {
        assert(!selectedPhotos.isEmpty, "photos shouldn't be empty")
        delegate?.photoBrowser(self, didCompleteSelected: selectedPhotos)
    }

    @objc func addPhotoBarItemClicked(_ sender: UIBarButtonItem) {
        defer {
            doneBarItem.isEnabled = !selectedPhotos.isEmpty
        }

        let photo = photos[currentDisplayedIndexPath.item]
        
        if let exsit = firstIndexOfPhoto(photo, in: selectedPhotos) {
            // already added, remove it from selections
            selectedPhotos.remove(at: exsit)
            addPhotoBarItem.title = addLocalizedString
            addPhotoBarItem.tintColor = .black
            return
        }

        // add photo
        selectedPhotos.append(photo)

        // update bar item: add, done
        if let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) {
            addPhotoBarItem.title = "\(firstIndex + 1)"
            addPhotoBarItem.tintColor = .systemBlue
        }

        // filter different media type
    }

    @objc func playVideoBarItemClicked(_ sender: UIBarButtonItem) {
        guard currentPhoto.isVideo else { return }
        if isPlaying {
            pausePlayback()
        } else {
            playVideo()
        }
    }

    // MARK: ToolBar updates
    func updateToolBar(shouldShowDone: Bool, shouldShowPlay: Bool) {
        var items = [UIBarButtonItem]()
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        if shouldShowPlay {
            items.append(spaceItem)
            items.append(playVideoBarItem)
            items.append(spaceItem)
        } else {
            items.append(spaceItem)
        }

        if shouldShowDone {
            items.append(doneBarItem)
        }
        self.setToolbarItems(items, animated: true)
    }

    func updateToolBarItems(isPlaying: Bool) {
        var toolbarItems = self.toolbarItems
        if isPlaying {
            if let index = toolbarItems?.firstIndex(of: playVideoBarItem) {
                toolbarItems?.remove(at: index)
                toolbarItems?.insert(pauseVideoBarItem, at: index)
            }
        } else {
            if let index = toolbarItems?.firstIndex(of: pauseVideoBarItem) {
                toolbarItems?.remove(at: index)
                toolbarItems?.insert(playVideoBarItem, at: index)
            }
        }
        self.setToolbarItems(toolbarItems, animated: true)
    }

    func updateAddBarItem(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        guard let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) else {
            addPhotoBarItem.title = addLocalizedString
            addPhotoBarItem.isEnabled = selectedPhotos.count < maximumCanBeSelected
            addPhotoBarItem.tintColor = .black
            return
        }
        addPhotoBarItem.isEnabled = true
        addPhotoBarItem.title = "\(firstIndex + 1)"
        addPhotoBarItem.tintColor = .systemBlue
    }

    func stopPlayingVideoIfNeeded(at oldIndexPath: IndexPath) {
        if isPlaying {
            stopPlayingIfNeeded()
        }
    }

    func updateCaption(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        captionView.setup(content: photo.captionContent, signature: photo.captionSignature)
    }

    func updateNavigationTitle(at indexPath: IndexPath) {
        if supportNavigationBar {
            if isForSelection {
                navigationItem.title = ""
            } else {
                navigationItem.title = "\(indexPath.item + 1) /\(photos.count)"
            }
        }
    }
    
    func updateThumbnails(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        
        if let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) {
            selectedThumbnailIndexPath = IndexPath(item: firstIndex, section: 0)
        } else {
            selectedThumbnailIndexPath = nil
        }
    }

    @objc func playerItemDidReachEnd(_ notification: Notification) {
        isPlaying = false
        seekToZeroBeforePlay = true
    }

    func recalculateItemSize(inBoundingSize size: CGSize) {
        guard let flowLayout = mainFlowLayout else { return }
        let itemSize = recalculateLayout(flowLayout,
                                         inBoundingSize: size)
        let scale = UIScreen.main.scale
        assetSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
    }

    @discardableResult
    func recalculateLayout(_ layout: UICollectionViewFlowLayout, inBoundingSize size: CGSize) -> CGSize {
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layout.scrollDirection = .horizontal;
        layout.minimumLineSpacing = 20
        layout.itemSize = size
        return size
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        stopPlayingIfNeeded()
        player = nil
    }
}

extension PhotoBrowserViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let pageWidth = view.bounds.size.width
//        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        if scrollView == mainCollectionView {
            isScrollingMainPhotos = true
            if let currentIndexPath = self.mainCollectionView.indexPathsForVisibleItems.last {
                currentDisplayedIndexPath = currentIndexPath
            } else {
                currentDisplayedIndexPath = IndexPath(row: 0, section: 0)
            }
            
        }
    }
}

// MARK: - Router event
extension PhotoBrowserViewController {
    override func routerEvent(name: String, userInfo: [AnyHashable : Any]?) {
        if let tap = ImageViewTap(rawValue: name) {
            switch tap {
            case .singleTap:
                hideOrShowTopBottom()
            case .doubleTap:
                handleDoubleTap(userInfo)
            }
        } else {
            // pass the event
            next?.routerEvent(name: name, userInfo: userInfo)
        }
    }

    fileprivate func hideOrShowTopBottom() {
        if supportNavigationBar {
            self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? true), animated: true)
        }

        if supportBottomToolBar {
            self.navigationController?.setToolbarHidden(!(self.navigationController?.isToolbarHidden ?? true), animated: true)
        }

        if supportCaption {
            hideCaptionView(!captionView.isHidden)
        }
    }

    fileprivate func handleDoubleTap(_ userInfo: [AnyHashable : Any]?) {
        if let userInfo = userInfo, let mediaType = userInfo["mediaType"] as? String {
            let cfstring = mediaType as CFString
            switch cfstring {
            case kUTTypeImage:
                if let touchPoint = userInfo["touchPoint"] as? CGPoint,
                   let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell  {
                    doubleTap(touchPoint, on: cell)
                }
            case kUTTypeVideo:
                if isPlaying {
                    pausePlayback()
                } else {
                    playVideo()
                }
            default: break

            }
        }
    }

    fileprivate func doubleTap(_ touchPoint: CGPoint, on cell: PhotoDetailCell) {
        let scale = min(cell.zoomingView.zoomScale * 2, cell.zoomingView.maximumZoomScale)
        if cell.zoomingView.zoomScale == 1 {
            let zoomRect = zoomRectForScale(scale: scale, center: touchPoint, for: cell.zoomingView)
            cell.zoomingView.zoom(to: zoomRect, animated: true)
        } else {
            cell.zoomingView.setZoomScale(1, animated: true)
        }
    }

    fileprivate func zoomRectForScale(scale: CGFloat, center: CGPoint, for scroolView: UIScrollView) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = scroolView.frame.size.height / scale
        zoomRect.size.width  = scroolView.frame.size.width  / scale

        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
}

// MARK: - Video
extension PhotoBrowserViewController {
//    fileprivate var currentVideoCell: VideoDetailCell? {
//        return collectionView.cellForItem(at: currentDisplayedIndexPath) as? VideoDetailCell
//    }

    fileprivate func setupPlayer(photo: PhotoProtocol, for playerView: PlayerView) {
        if let asset = photo.asset {
            setupPlayer(asset: asset, for: playerView)
        } else if let url = photo.url {
            setupPlayer(url: url, for: playerView)
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

    fileprivate func setupPlayer(url: URL, for playerView: PlayerView) {
        if url.isFileURL {
            // Create asset to be played
            let asset = AVAsset(url: url)
            // Create a new AVPlayerItem with the asset and an
            // array of asset keys to be automatically loaded
            let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
            let player = preparePlayer(with: playerItem)
            playerView.player = player
            self.player = player
        } else {
            VideoCache.fetchURL(key: url) { (filePath) in
                // Create a new AVPlayerItem with the asset and an
                // array of asset keys to be automatically loaded
                let asset = AVAsset(url: filePath)
                let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: self.assetKeys)
                let player = self.preparePlayer(with: playerItem)
                playerView.player = player
                self.player = player
            } failed: { (error) in
                print("FYPhoto fetch url error: \(error)")
            }
        }
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

    fileprivate func playVideo() {
        guard let player = player else { return }
        if seekToZeroBeforePlay {
            seekToZeroBeforePlay = false
            player.seek(to: .zero)
        }

        player.play()
        isPlaying = true
    }

    fileprivate func pausePlayback() {
        player?.pause()
        isPlaying = false
    }

    fileprivate func stopPlayingIfNeeded() {
        guard let player = player, isPlaying else {
            return
        }
        player.pause()
        player.seek(to: .zero)
        isPlaying = false
    }
}

// MARK: - PhotoDetailTransitionAnimatorDelegate
extension PhotoBrowserViewController: PhotoTransitioning {
    public func transitionWillStart() {
        guard let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) else { return }
        cell.isHidden = true
    }

    public func transitionDidEnd() {
        guard let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) else { return }
        cell.isHidden = false
    }

    public func referenceImage() -> UIImage? {
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell {
            return cell.image
        }
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? VideoDetailCell {
            return cell.image
        }
        return nil
    }

    public func imageFrame() -> CGRect? {
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell {
            return CGRect.makeRect(aspectRatio: cell.image?.size ?? .zero, insideRect: cell.bounds)
        }
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? VideoDetailCell {
            return CGRect.makeRect(aspectRatio: cell.image?.size ?? .zero, insideRect: cell.bounds)
        }
        return nil
    }
}

extension PhotoBrowserViewController {
    func firstIndexOfPhoto(_ photo: PhotoProtocol, in photos: [PhotoProtocol]) -> Int? {
        return photos.firstIndex { $0.isEqualTo(photo) }
    }
}
