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
    var url: URL
}

extension String {
    func scanUpTo(_ string: String) -> String.Index? {
        return self.range(of: string)?.lowerBound
    }
}

class CertificateManager: ObservableObject {
    @Published var certificates: [Certificate] = []
    @Published var activeCertificate: Certificate? {
        didSet {
            if let selectedID = activeCertificate?.id {
                UserDefaults.standard.set(selectedID.uuidString, forKey: "activeCertificateID")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeCertificateID")
            }
        }
    }

    func selectCertificate(_ certificate: Certificate) {
        activeCertificate = certificate
    }
    
    private let fileManager = FileManager.default
    private let userDefaultsKey = "customCertificates"
    
    init() {
        loadCertificates()
    }
    
    func addCertificate(mpURL: URL, p12URL: URL, p12Pass: String) throws {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let mpAccessing = mpURL.startAccessingSecurityScopedResource()
        defer {
            if mpAccessing {
                mpURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let certsDirectory = documentsDirectory.appendingPathComponent("certificates/")
        let teamName = parseTeamName(from: mpURL)
        let certUUID = UUID().uuidString
        let certPath = certsDirectory.appendingPathComponent("\(certUUID)/")
        
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
        
        certificates.append(Certificate(name: teamName, url: certPath))
        saveCertificates()
        loadCertificates()
        
        return
    }
    
    func saveCertificates() {
        if let encoded = try? JSONEncoder().encode(certificates) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func loadCertificates() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([Certificate].self, from: data) {
                self.certificates = decoded
            }
        }
        
        if let savedID = UserDefaults.standard.string(forKey: "activeCertificateID") {
            activeCertificate = certificates.first { $0.id.uuidString == savedID }
        }
    }
    
    func deleteCert(at offsets: IndexSet) {
        for i in offsets.sorted(by: >) {
            if i < certificates.count {
                let certToDelete = certificates[i]
                do {
                    try FileManager.default.removeItem(at: certToDelete.url)
                    certificates.remove(at: i)
                } catch {
                    print("[!] Unable to delete certificate archive: \(error)")
                }
            }
        }
        saveCertificates()
    }
    
    // MobileProvision parsing stuff
    
    func parseExpirationDate(url: URL) -> String {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let formatter = ISO8601DateFormatter()
        let fallbackDate = formatter.date(from: "2001-09-11T01:46:40-07:00")!
        
        let profile = MobileProvision.read(from: url.path)
        
        let readableFormatter = DateFormatter()
        readableFormatter.dateFormat = "MMMM d, yyyy"
        return readableFormatter.string(from: profile?.expirationDate ?? fallbackDate)
    }
        
    func parseTeamName(from url: URL) -> String {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let profile = MobileProvision.read(from: url.path)
        
        return profile?.name ?? profile?.teamName ?? "Vibrating Balls Hotel & Resort"
    }
    
    func parseTeamID(from url: URL) -> String {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let profile = MobileProvision.read(from: url.path)
        
        return profile?.teamIdentifier.first ?? "i forgor 💀"
    }
        
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: date)
    }
}
