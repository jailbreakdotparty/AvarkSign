//
//  DownloadManager.swift
//  NeoSigner
//
//  Created by Skadz on 2/25/25.
//

// This is some stupid vibe-coded garbage.
// Just use Downloadinator.swift for now.
// - Skadz, 6/30/25

//import Foundation
//import SwiftUI
//import Combine
//
//class DownloadManager: NSObject, ObservableObject {
//    static let shared = DownloadManager()
//    
//    @Published var downloadProgress: Double = 0.0
//    @Published var downloadState: DownloadState = .notStarted
//    @Published var currentFileName: String = ""
//    @Published var downloadStatusText: String = ""
//    
//    private var session: URLSession!
//    private var downloadTasks: [URL: URLSessionDownloadTask] = [:]
//    private var progressObservers: [URL: NSKeyValueObservation] = [:]
//    private var downloadCompletions: [URL: (Result<URL, Error>) -> Void] = [:]
//    
//    let fileManager = FileManager.default
//    
//    enum DownloadState: Equatable {
//        case notStarted
//        case downloading
//        case finished
//        case failed(Error)
//        
//        static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
//            switch (lhs, rhs) {
//            case (.notStarted, .notStarted),
//                (.downloading, .downloading),
//                (.finished, .finished),
//                (.failed, .failed):
//                return true
//            default:
//                return false
//            }
//        }
//    }
//    
//    override init() {
//        super.init()
//        let configuration = URLSessionConfiguration.default
//        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//    }
//    
//    func download(from url: URL, fileName: String? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
//        downloadProgress = 0.0
//        downloadState = .downloading
//        
//        let urlFileName = url.lastPathComponent
//        currentFileName = fileName ?? urlFileName
//        downloadStatusText = "Downloading \(currentFileName)..."
//        
//        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let tmpDirectory = documentsDirectory.appendingPathComponent("tmp", isDirectory: true)
//        
//        do {
//            try FileManager.default.createDirectory(at: tmpDirectory, withIntermediateDirectories: true)
//        } catch {
//            downloadState = .failed(error)
//            completion(.failure(error))
//            return
//        }
//        
//        let downloadTask = session.downloadTask(with: url)
//        
//        downloadCompletions[url] = completion
//        
//        let observation = downloadTask.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
//            DispatchQueue.main.async {
//                self?.downloadProgress = progress.fractionCompleted
//            }
//        }
//        
//        downloadTasks[url] = downloadTask
//        progressObservers[url] = observation
//        
//        downloadTask.resume()
//    }
//    
//    func cancelDownload(for url: URL) {
//        downloadTasks[url]?.cancel()
//        cleanupTask(for: url)
//    }
//    
//    func cancelAllDownloads() {
//        for (url, _) in downloadTasks {
//            cancelDownload(for: url)
//        }
//    }
//    
//    private func cleanupTask(for url: URL) {
//        progressObservers[url]?.invalidate()
//        progressObservers.removeValue(forKey: url)
//        downloadTasks.removeValue(forKey: url)
//        downloadCompletions.removeValue(forKey: url)
//    }
//}
//
//extension DownloadManager: URLSessionDownloadDelegate {
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        guard let sourceURL = downloadTask.originalRequest?.url else { return }
//        
//        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let tmpDirectory = documentsDirectory.appendingPathComponent("tmp", isDirectory: true)
//        let destinationURL = tmpDirectory.appendingPathComponent(sourceURL.lastPathComponent)
//        
//        do {
//            if FileManager.default.fileExists(atPath: destinationURL.path) {
//                try FileManager.default.removeItem(at: destinationURL)
//            }
//            
//            try FileManager.default.moveItem(at: location, to: destinationURL)
//            
//            DispatchQueue.main.async { [weak self] in
//                self?.downloadState = .finished
//                self?.downloadStatusText = "Download complete!"
//                self?.downloadCompletions[sourceURL]?(.success(destinationURL))
//                self?.cleanupTask(for: sourceURL)
//            }
//        } catch {
//            DispatchQueue.main.async { [weak self] in
//                self?.downloadState = .failed(error)
//                self?.downloadStatusText = "Download failed: \(error.localizedDescription)"
//                self?.downloadCompletions[sourceURL]?(.failure(error))
//                self?.cleanupTask(for: sourceURL)
//            }
//        }
//    }
//    
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        guard let error = error, let sourceURL = task.originalRequest?.url else { return }
//        
//        DispatchQueue.main.async { [weak self] in
//            self?.downloadState = .failed(error)
//            self?.downloadStatusText = "Download failed: \(error.localizedDescription)"
//            self?.downloadCompletions[sourceURL]?(.failure(error))
//            self?.cleanupTask(for: sourceURL)
//        }
//    }
//}
