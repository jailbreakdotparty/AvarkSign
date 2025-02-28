//
//  CustomCertificateManager.swift
//  Octopus
//
//  Created by Skadz on 9/24/24.
//

import Foundation
import ZIPFoundation
import UIKit

struct Certificate: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var path: String
}

// TODO: We probably shouldn't compress the cert info to a ZIP and extract it every time we need it. If the user needs to share the cert, then we can compress it. This was overall a really stupid decision I made when making Octopus private alpha 2.

class CertificateManager: ObservableObject {
    @Published var certificates: [Certificate] = []
    
    private let fileManager = FileManager.default
    private let userDefaultsKey = "customCertificates"
    
    init() {
        loadCertificates()
    }
    
    func addCertificate(mpURL: URL, p12URL: URL, p12Pass: String) throws -> String {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let mpAccessing = mpURL.startAccessingSecurityScopedResource()
        defer {
            if mpAccessing {
                mpURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let certsDirectory = documentsDirectory.appendingPathComponent("certificates/")
        let teamName = parseTeamName(from: mpURL)
        let certPath = certsDirectory.appendingPathComponent("\(teamName)/")
        
        if !fileManager.fileExists(atPath: certPath.path()) {
            do {
                try fileManager.createDirectory(at: certPath, withIntermediateDirectories: true)
            } catch {
                throw "Failed to create certificate folder!"
            }
        }
        
        let p12Accessing = p12URL.startAccessingSecurityScopedResource()
        defer {
            if p12Accessing {
                p12URL.stopAccessingSecurityScopedResource()
            }
        }
        
        guard fileManager.fileExists(atPath: mpURL.path),
              fileManager.fileExists(atPath: p12URL.path) else {
            throw "One or both files do not exist."
        }
        
        guard mpURL.pathExtension.lowercased() == "mobileprovision",
              p12URL.pathExtension.lowercased() == "p12" else {
            throw "Invalid file types."
        }
        
        do {
            try fileManager.copyItem(at: mpURL, to: certPath.appendingPathComponent("mp.mobileprovision"))
            try fileManager.copyItem(at: p12URL, to: certPath.appendingPathComponent("cert.p12"))
            try p12Pass.write(to: certPath.appendingPathComponent("p12_password"), atomically: true, encoding: .utf8)
        } catch {
            throw "Failed to copy certificate files!"
        }
        
        certificates.append(Certificate(name: teamName, path: certPath.path()))
        saveCertificates()
        loadCertificates()
        
        return "Successfully added certificate \(teamName)!"
    }
    
    func loadCertificates() {
        if let savedCertificates = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedCertificates = try? JSONDecoder().decode([Certificate].self, from: savedCertificates) {
            certificates = decodedCertificates
        }
    }
    
    func saveCertificates() {
        if let encodedCertificates = try? JSONEncoder().encode(certificates) {
            UserDefaults.standard.set(encodedCertificates, forKey: userDefaultsKey)
        }
    }
    
    func deleteCert(at offsets: IndexSet) {
        for i in offsets.sorted(by: >) {
            if i < certificates.count {
                let certToDelete = certificates[i]
                do {
                    try FileManager.default.removeItem(atPath: certToDelete.path)
                    certificates.remove(at: i)
                } catch {
                    print("[!] Unable to delete certificate archive: \(error)")
                }
            }
        }
        saveCertificates()
    }

    func parseExpirationDate(url: URL) -> String {
        do {
            let mpData = try Data(contentsOf: url)
            let mpContent = String(data: mpData, encoding: .ascii) ?? ""
            
            let pattern = "<key>ExpirationDate</key>\\s*<date>(.*?)</date>"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(mpContent.startIndex..<mpContent.endIndex, in: mpContent)
            
            guard let match = regex.firstMatch(in: mpContent, options: [], range: nsRange),
                  let range = Range(match.range(at: 1), in: mpContent) else {
                return "<unknown>"
            }
            
            let dateString = String(mpContent[range])
            let isoFormatter = ISO8601DateFormatter()
            
            guard let date = isoFormatter.date(from: dateString) else {
                return "<unknown>"
            }
            
            let readableFormatter = DateFormatter()
            readableFormatter.dateFormat = "MMMM d, yyyy"
            
            return readableFormatter.string(from: date)
        } catch {
            return "<unknown>"
        }
    }

    func parseExpirationDate(from cert: Certificate) -> String {
        do {
            let mpPath = URL(fileURLWithPath: cert.path).appendingPathComponent("mp.mobileprovision")
            let mpData = try Data(contentsOf: mpPath)
            let mpContent = String(data: mpData, encoding: .ascii) ?? ""
            
            let pattern = "<key>ExpirationDate</key>\\s*<date>(.*?)</date>"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(mpContent.startIndex..<mpContent.endIndex, in: mpContent)
            
            guard let match = regex.firstMatch(in: mpContent, options: [], range: nsRange),
                  let range = Range(match.range(at: 1), in: mpContent) else {
                return "<unknown>"
            }
            
            let dateString = String(mpContent[range])
            let isoFormatter = ISO8601DateFormatter()
            
            guard let date = isoFormatter.date(from: dateString) else {
                return "<unknown>"
            }
            
            let readableFormatter = DateFormatter()
            readableFormatter.dateFormat = "MMMM d, yyyy"
            
            return readableFormatter.string(from: date)
        } catch {
            return "<unknown>"
        }
    }
        
    func parseTeamName(from url: URL) -> String {
        do {
            let mpData = try Data(contentsOf: url)
            let mpContent = String(data: mpData, encoding: .ascii) ?? ""
            
            let pattern = "<key>TeamName</key>\\s*<string>(.*?)</string>"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(mpContent.startIndex..<mpContent.endIndex, in: mpContent)
            
            guard let match = regex.firstMatch(in: mpContent, options: [], range: nsRange),
                  let range = Range(match.range(at: 1), in: mpContent) else {
                return "Vibrating Balls Hotel & Resort"
            }
            
            return String(mpContent[range])
        } catch {
            return "Vibrating Balls Hotel & Resort"
        }
    }
        
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: date)
    }
}
