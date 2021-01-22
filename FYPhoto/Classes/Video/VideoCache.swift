//
//  VideoCache.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/10/14.
//

import Foundation
import Alamofire
import SDWebImage
import Cache

protocol CacheProtocol {
    func cachePath(forKey key: String) -> String?
    
    func setData(_ data: Data?, forKey key: String)
    
    func data(forKey key: String) -> Data?
    
    func removeAllData()
}

/// Cache remote videos, expired in 3 days
public class VideoCache {
    // Cache framework
    private static let storageDiskConfig = DiskConfig(name: "VideoReourceCache", expiry: .seconds(3600*24*3))
    private static let storageMemoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    private static let storage = try? Storage.init(diskConfig: VideoCache.storageDiskConfig, memoryConfig: VideoCache.storageMemoryConfig, transformer: TransformerFactory.forData())
    
    // SDWebImage framework
    static var sdDiskConfig: SDImageCacheConfig  {
        let config = SDImageCacheConfig()
        config.diskCacheExpireType = .accessDate
        config.maxDiskSize = 1024 * 1024 * 512 // 500M
        return config
    }
    
    static var videoCacheTmpDirectory: URL? {
        return try? FileManager.tempDirectory(with: "FYPhotoVideoCache")
    }
    
    static var diskCache: SDDiskCache? {
        if let temp = videoCacheTmpDirectory {
            print("Video cached at: \(temp.path)")
            return SDDiskCache(cachePath: temp.path, config: sdDiskConfig)
        } else {
            return nil
        }
    }
    
    public static let shared: VideoCache? = VideoCache()
    
    private var cache: CacheProtocol?
    private var task: URLSessionDataTask?
    
    private static let movieTypes: [String] = ["mp4", "m4v", "mov"]
    
    private init?(cache: CacheProtocol? = VideoCache.diskCache) {
        self.cache = cache
    }
    
    public func clearAll() {
        cache?.removeAllData()
    }
    
    public func save(data: Data, key: URL) {
        let cKey = getCacheKey(with: key)
        cache?.setData(data, forKey: cKey)
    }
    
    public func fetchDataWith(key: URL, completion: @escaping ((Swift.Result<Data, Error>) -> Void)) {
        let cKey = getCacheKey(with: key)
        if let data = cache?.data(forKey: cKey) {
            completion(.success(data))
        } else {
            AF.request(key).responseData { (response: DataResponse<Data, AFError>) in
                switch response.result {
                case .success(let data):
                    self.save(data: data, key: key)
                    completion(.success(data))
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    public func fetchFilePathWith(key: URL, completion: @escaping ((Swift.Result<URL, Error>) -> Void)) {
        guard !key.isFileURL else {
            completion(.success(key))
            return
        }
        guard let cache = cache else { return }
        
        // Use the code below to get the real video suffix.
        // "http://client.gsup.sichuanair.com/file.php?9bfc3b16aec233d025c18042e9a2b45a.mp4", this url will get `php` as it's path extension
        let keyString = getCacheKey(with: key)
                        
        if cache.data(forKey: keyString) != nil,
           let filePath = cache.cachePath(forKey: keyString) {
            let url = URL(fileURLWithPath: filePath)
            completion(.success(url))
        } else {
            AF.request(key).responseData { (response: DataResponse<Data, AFError>) in
                switch response.result {
                case .success(let data):
                    self.save(data: data, key: key)
                    if let path = cache.cachePath(forKey: keyString) {
                        let url = URL(fileURLWithPath: path)
                        DispatchQueue.main.async {
                            completion(.success(url))
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func cancelTask() {
        switch task?.state {
        case .running, .suspended:
            task?.cancel()
        default:
            break
        }        
    }
    
    func getCacheKey(with url: URL) -> String {
        let pathExtension = url.pathExtension
        if VideoCache.movieTypes.contains(pathExtension) {
            return url.absoluteString
        } else {
            let fileURL = URL(fileURLWithPath: url.absoluteString)
            let filePathExtension = fileURL.pathExtension
            if VideoCache.movieTypes.contains(filePathExtension) {
                return url.query ?? url.absoluteString
            } else {
                return url.absoluteString
            }
        }
    }
}


extension SDDiskCache: CacheProtocol {
}

extension Storage: CacheProtocol where T == Data {
    func setData(_ data: Data?, forKey key: String) {
        guard let data = data else { return }
        do {
            try setObject(data, forKey: key)
        } catch {
            print("store data error: \(error)")
        }
    }
        
    func data(forKey key: String) -> Data? {
        do {
            return try object(forKey: key)
        } catch {
            print("get data error: \(error)")
            return nil
        }
    }
    
    func removeAllData() {
        do {
            try removeAll()
        } catch {
            print("get data error: \(error)")
        }
    }
    
    func cachePath(forKey key: String) -> String? {
        do {
            let en = try entry(forKey: key)
            return en.filePath
        } catch {
            #if DEBUG
            print("❌ error: \(error)")
            #endif
            return nil
        }
    }
}
