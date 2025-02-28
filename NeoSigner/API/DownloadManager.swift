//
//  DownloadManager.swift
//  NeoSigner
//
//  Created by Skadz on 2/25/25.
//

import Foundation
import SwiftUI
import UIKit

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    var downloadProgress: Double = 0.0
    
    func download(from url: URL) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let downloadTask = session.downloadTask(with: url)
        downloadTask.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percentDownloaded = totalBytesWritten / totalBytesExpectedToWrite
        
        DispatchQueue.main.async {
            self.downloadProgress = Double(percentDownloaded * 100)
        }
    }
}
