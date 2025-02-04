//
//  FileManager+TempDirectory.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/20.
//

import Foundation

extension FileManager {
    public enum CreateTempDirectoryError: Error, LocalizedError {
        case fileExsisted
        
        public var errorDescription: String? {
            switch self {
            case .fileExsisted:
                return "File exsisted"
            }
        }
    }
    /// create temp directory. `xxx/pathComponent/`
    /// - Parameter pathComponent: path to append to temp directory
    /// - Throws: error when create temp url
    /// - Returns: temp directory location
    public static func tempDirectory(with pathComponent: String? = nil) throws -> URL {
        let cacheURL = FileManager.default.temporaryDirectory
        do {
            // Only the volume(卷) of cache url is used.
            let temp = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: cacheURL, create: true)
            var compressedDirectory = temp
            if let component = pathComponent {
                compressedDirectory.appendPathComponent(component)
            }
            if !FileManager.default.fileExists(atPath: compressedDirectory.absoluteString) {
                do {
                    try FileManager.default.createDirectory(at: compressedDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    throw error
                }
            } else {
                throw CreateTempDirectoryError.fileExsisted
            }
            #if DEBUG
            print("temp directory path👉\(temp)👈")
            #endif
            return compressedDirectory
        } catch {
            throw error
        }
    }
}
