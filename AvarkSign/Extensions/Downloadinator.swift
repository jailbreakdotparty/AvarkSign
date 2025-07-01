//
//  Downloadinator.swift
//  NeoSigner
//
//  Created by Skadz on 6/30/25.
//

import Foundation

func Downloadinator(from src: URL, to dst: URL) async throws -> URL {
    let (data, response) = try await URLSession.shared.data(from: src)
    
    if let httpResponse = response as? HTTPURLResponse,
       !(200...299).contains(httpResponse.statusCode) {
        throw "http error: \(httpResponse.statusCode)"
    }
    
    guard !data.isEmpty else {
        throw "no data?"
    }
    
    let dstDir = dst.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: dstDir, withIntermediateDirectories: true)
    
    try data.write(to: dst)
    
    return dst
}
