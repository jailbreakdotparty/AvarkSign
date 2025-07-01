//
//  formatBytes.swift
//  NeoSigner
//
//  Created by Skadz on 2/27/25.
//  Skidded from https://gist.github.com/mminer/d0a043b0b6054f428a8ed1f505bfe1b0 (not sure of any license)
//

import Foundation

func format(bytes: Double) -> String {
    guard bytes > 0 else {
        return "0 bytes"
    }

    // Adapted from http://stackoverflow.com/a/18650828
    let suffixes = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
    let k: Double = 1000
    let i = floor(log(bytes) / log(k))

    // Format number with thousands separator and everything below 1 GB with no decimal places.
    let numberFormatter = NumberFormatter()
    numberFormatter.maximumFractionDigits = i < 3 ? 0 : 1
    numberFormatter.numberStyle = .decimal

    let numberString = numberFormatter.string(from: NSNumber(value: bytes / pow(k, i))) ?? "Unknown"
    let suffix = suffixes[Int(i)]
    return "\(numberString) \(suffix)"
}

// thx chatgpt
func folderSize(atPath path: String) -> Int {
    let fileManager = FileManager.default
    var totalSize = 0

    if let enumerator = fileManager.enumerator(atPath: path) {
        for case let file as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file)
            do {
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                if let fileSize = attributes[.size] as? Int {
                    totalSize += fileSize
                }
            } catch {
                print("Error getting size of file: \(filePath), error: \(error)")
            }
        }
    }
    return totalSize
}

// not chatgpt
func fileSize(at url: URL) -> String {
    let fileManager = FileManager.default
    
    do {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? Double {
            return format(bytes: fileSize)
        }
    } catch {
        return "Unknown"
    }
    
    return "Unknown"
}
