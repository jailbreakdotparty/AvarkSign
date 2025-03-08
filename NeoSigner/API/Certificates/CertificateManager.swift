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
        guard let index = self.range(of: string)?.lowerBound else {
            return nil
        }
        
        return index
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
    
    // MobileProvision parsing stuff (skidded from whatever this is: https://github.com/junkpiano/MobileProvision)
    
    public struct MobileProvisionPlist: Decodable {
        public let appIDName: String
        public let expirationDate: Date
        public let teamName: String
        public let teamIdentifier: [String]
        public let provisionedDevices: [String]?
        public let name: String
        
        enum CodingKeys: String, CodingKey {
            case appIDName = "AppIDName"
            case expirationDate = "ExpirationDate"
            case teamName = "TeamName"
            case provisionedDevices = "ProvisionedDevices"
            case name = "Name"
            case teamIdentifier = "TeamIdentifier"
        }
    }
    
    func parseMobileProvision(at url: URL) -> MobileProvisionPlist {
        do {
            let mpData = try Data(contentsOf: url)
            let fileContents = String(data: mpData, encoding: .ascii)!
            let startIndex = fileContents.scanUpTo("<plist")!
            let endIndex = fileContents.scanUpTo("</plist>")!
            
            let from = fileContents.index(startIndex, offsetBy: 0)
            let to = fileContents.index(endIndex, offsetBy: "</plist>".count)
            
            return try PropertyListDecoder().decode(MobileProvisionPlist.self, from: String(fileContents[from..<to]).data(using: .ascii)!)
        } catch {
            return MobileProvisionPlist(appIDName: "appID", expirationDate: try! Date("2001-09-11T01:46:40-07:00", strategy: .iso8601), teamName: "Vibrating Balls Hotel & Resort", teamIdentifier: ["unknown"], provisionedDevices: [], name: "Vibrating Balls Hotel & Resort")
        }
    }
    
    func parseExpirationDate(url: URL) -> String {
        let mobileProvision = parseMobileProvision(at: url)
        let isoFormatter = ISO8601DateFormatter()
        
        let readableFormatter = DateFormatter()
        readableFormatter.dateFormat = "MMMM d, yyyy"
        
        return readableFormatter.string(from: mobileProvision.expirationDate)
    }
        
    func parseTeamName(from url: URL) -> String {
        let mobileProvision = try parseMobileProvision(at: url)
        return mobileProvision.name
    }
        
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: date)
    }
}
