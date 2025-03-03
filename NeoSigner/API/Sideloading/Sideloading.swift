//
//  Sideloading.swift
//  Octopus
//
//  Created by Skadz on 9/23/24.
//

import Foundation
import UIKit
import ZIPFoundation
import Swifter

public class Sideloading: ObservableObject {
    static let shared = Sideloading()
    
    struct AppCustomizationOptions: Codable, Hashable {
        var appName: String?
        var bundleID: String?
        var bundleVersion: Double?
    }
    
    class AppInfo: ObservableObject, Identifiable {
        var id = UUID()
        
        @Published var displayName: String
        @Published var bundleID: String
        @Published var bundleVersion: String
        @Published var iconURL: URL
        
        init(displayName: String, bundleID: String, bundleVersion: String, iconURL: URL) {
            self.displayName = displayName
            self.bundleID = bundleID
            self.bundleVersion = bundleVersion
            self.iconURL = iconURL
        }
    }
    
    func getAppInfo(ipaPath: URL) throws -> AppInfo {
        let accessing = ipaPath.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                ipaPath.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileManager = FileManager.default
        
        do {
            let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            
            try fileManager.unzipItem(at: ipaPath, to: tempDirectory)
            
            let enumerator = fileManager.enumerator(at: tempDirectory, includingPropertiesForKeys: nil, options: [], errorHandler: nil)
            let appFolderURL = enumerator!.allObjects.first(where: { ($0 as? URL)?.pathExtension == "app" }) as? URL
            
            let displayName = extractInfoPlistField(appFolderURL: appFolderURL!, field: "CFBundleDisplayName")
            let bundleID = extractInfoPlistField(appFolderURL: appFolderURL!, field: "CFBundleIdentifier")
            let bundleVersion = extractInfoPlistField(appFolderURL: appFolderURL!, field: "CFBundleVersion")
            let iconURL = extractAppIcon(appFolderURL: appFolderURL!)
            
            return AppInfo(displayName: displayName, bundleID: bundleID, bundleVersion: bundleVersion, iconURL: iconURL)
        } catch {
            print("Failed to extract app bundle to temporary folder! Check Xcode logs for more details.")
            throw error
        }
    }
    
    func sideload(ipaPath: URL, cert: Certificate, customizationOptions: AppCustomizationOptions, installMethod: Int) -> Bool {
        let mpPath: URL
        let p12Path: URL
        let p12Pass: String
        
        print("[-] Sideloading started.")
        
        print("[-] Attempting to access selected IPA...")
        let accessing = ipaPath.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                ipaPath.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileManager = FileManager.default
        
        print("[-] Fetching MobileProvision and P12 details from selected certificate...")
        do {
            let certURL = URL(fileURLWithPath: cert.path)
                    
            let passwordData = try Data(contentsOf: certURL.appendingPathComponent("p12_password"))
            p12Pass = String(data: passwordData, encoding: .utf8) ?? ""
                    
            mpPath = certURL.appendingPathComponent("mp.mobileprovision")
            p12Path = certURL.appendingPathComponent("cert.p12")
        } catch {
            print("Failed to get MobileProvision and P12 info! Make sure you've selected a certificate and that the certificate files are valid.")
            print(error)
            return false
        }
        
        guard let destinationPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[!] Documents directory not found")
            return false
        }
        
        print("[-] Destination path for extraction: \(destinationPath.path)")
        
        print("[-] Clearing out old files...")
        cleanup()
        
        do {
            try fileManager.unzipItem(at: ipaPath, to: destinationPath)
            print("[*] Extraction successful at \(destinationPath.path)")
            
            guard let enumerator = fileManager.enumerator(at: destinationPath, includingPropertiesForKeys: nil, options: [], errorHandler: nil),
                  let appFolderURL = enumerator.allObjects.first(where: { ($0 as? URL)?.pathExtension == "app" }) as? URL else {
                print("[!] Info.plist does not fucking exist. The .app folder doesn't exist either. What the fuck?")
                
                return false
            }
            
            let infoPlistURL = appFolderURL.appendingPathComponent("Info.plist")
            
            guard fileManager.fileExists(atPath: infoPlistURL.path) else {
                print("[!] Info.plist does not fucking exist.")
                return false
            }
            
            Task {
                let code = zsign(appFolderURL.path, mpPath.path, p12Path.path, p12Pass, customizationOptions.bundleID ?? "", customizationOptions.appName ?? "", customizationOptions.bundleVersion != nil ? String(format: "%.1f", customizationOptions.bundleVersion!) : "", true)
                if code == 0 {
                    print("[*] zsign returned 0, this is good.")
                    let signedIPAPath = destinationPath.appendingPathComponent("signed.ipa")
                    
                    let payloadPath = destinationPath.appendingPathComponent("Payload")
                    
                    if !fileManager.fileExists(atPath: payloadPath.path) {
                        print("[!] Payload directory not found.")
                        return false
                    }
                    
                    do {
                        try fileManager.zipItem(at: payloadPath, to: signedIPAPath)
                        print("[*] Zipping Payload folder successful. Signed IPA path: \(signedIPAPath.path)")
                    } catch {
                        print("[!] Failed to zip the Payload folder: \(error)")
                        return false
                    }
                    
                    let bundleId = extractInfoPlistField(appFolderURL: appFolderURL, field: "CFBundleIdentifier")
                    
                    let bundleVersion = extractInfoPlistField(appFolderURL: appFolderURL, field: "CFBundleVersion")
                    
                    let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
            "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
                <dict>
                    <key>items</key>
                    <array>
                        <dict>
                            <key>assets</key>
                            <array>
                                <dict>
                                    <key>kind</key>
                                    <string>software-package</string>
                                    <key>url</key>
                                    <string>\(installMethod == 1 ? "https://neosigner.localhost.direct:8080/signed.ipa" : "http://localhost:8080/signed.ipa")</string>
                                </dict>
                                <dict>
                                    <key>kind</key>
                                    <string>display-image</string>
                                    <key>needs-shine</key>
                                    <false/>
                                    <key>url</key>
                                    <string>\(installMethod == 1 ? "https://octopus.localhost.direct:8080/appIcon.png" : "http://localhost:8080/appIcon.png")</string>
                                </dict>
                                <dict>
                                    <key>kind</key>
                                    <string>full-size-image</string>
                                    <key>needs-shine</key>
                                    <false/>
                                    <key>url</key>
                                    <string>\(installMethod == 1 ? "https://octopus.localhost.direct:8080/appIcon.png" : "http://localhost:8080/appIcon.png")</string>
                                </dict>
                            </array>
                            <key>metadata</key>
                            <dict>
                                <key>bundle-identifier</key>
                                <string>\(String(describing: bundleId))</string>
                                <key>bundle-version</key>
                                <string>\(String(describing: bundleVersion))</string>
                                <key>kind</key>
                                <string>software</string>
                                <key>title</key>
                                <string>\(extractInfoPlistField(appFolderURL: appFolderURL, field: "CFBundleDisplayName"))</string>
                            </dict>
                        </dict>
                    </array>
                </dict>
            </plist>
        """
                    if let plistPath = createPlistFile(content: plistContent, destinationPath: destinationPath) {
                        print("[*] Installation manifest created at path: \(plistPath)")
                        
                        if installMethod == 1 {
                            do {
                                let serverBundle = try NeoServer.shared.setupServerFiles(ipaPath: signedIPAPath, appIconPath: extractAppIcon(appFolderURL: appFolderURL), manifestPath: URL(fileURLWithPath: plistPath))
                                NeoServer.shared.startServer(serverBundle)
                            } catch {
                                print("[!] Failed to start server!")
                                print(error)
                                return false
                            }
                            
                            print("[*] Installing...")
                            await UIApplication.shared.open(NeoServer.shared.installURL)
                        } else if installMethod == 0 {
                            var server: HttpServer = HttpServer()
                            do {
                                try server.start(8080)
                                print("[*] HTTP server started")
                            } catch {
                                print("[!] Failed to start server.")
                                return false
                            }
                            
                            server["/" + "signed.ipa"] = shareFile(signedIPAPath.path)
                            server["" + "appIcon.png"] = shareFile(extractAppIcon(appFolderURL: appFolderURL).path)
                            server["/install.plist"] = shareFile(plistPath)
                            
                            print("[*] Installing...")
                            await UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=https://jailbreak.party/install")!)
                        } else {
                            print("what the sigma")
                        }
                        print("[*] Success!")
                        return true
                    }
                } else if (code == -1) {
                    print("[!] zsign exited with code -1. This is bad. Check Xcode logs for more details.")
                    return false
                } else {
                    print("[!] zsign exited with code \(code)")
                    return false
                }
                return true
            }
        } catch {
            print("[!] Sideloading failed. Check Xcode logs for more details. \(error)")
            return false
        }
        
        return false
    }
    
    func createPlistFile(content: String, destinationPath: URL) -> String? {
        let plistFilePath = destinationPath.appendingPathComponent("install.plist")
        
        guard let data = content.data(using: .utf8) else {
            print("Failed to convert string to Data")
            return nil
        }
        
        do {
            try data.write(to: plistFilePath, options: .atomic)
            print("Plist file created at: \(plistFilePath.path)")
            return plistFilePath.path
        } catch {
            print("Error writing plist file: \(error)")
            return nil
        }
    }
    
    func cleanup() {
        let fileManager = FileManager.default
        do {
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Documents directory not found")
                return
            }

            let filePaths = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)

            for filePath in filePaths {
                let fullFilePath = documentsDirectory.appendingPathComponent(filePath).path
                
                if filePath != "certificates" {
                    do {
                        try fileManager.removeItem(atPath: fullFilePath)
                        print("[cleanup] \(filePath) has been deleted.")
                    } catch {
                        print("Error deleting \(filePath): \(error)")
                    }
                }
            }
        } catch {
            print("Error accessing documents directory: \(error)")
        }
    }
    
    func updateLocalInstallCertificate() async throws {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let certsDirectory = documentsDirectory.appendingPathComponent("certificates/")
        
        let certURL = certsDirectory.appendingPathComponent("ssl/")
        if !fileManager.fileExists(atPath: certURL.path()) {
            do {
                try fileManager.createDirectory(at: certURL, withIntermediateDirectories: true)
            } catch {
                throw "Failed to create certificate folder!"
            }
        }
        
        struct SSLCertificatePack: Decodable {
            var cert: String
            var ca: String
            var key: String
            var info: SSLCertificateInfo
            
            private enum CodingKeys: String, CodingKey {
                case cert, ca, key1, key2, info
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.cert = try container.decode(String.self, forKey: .cert)
                self.ca = try container.decode(String.self, forKey: .ca)
                let key1 = try container.decode(String.self, forKey: .key1)
                let key2 = try container.decode(String.self, forKey: .key2)
                self.key = key1 + key2
                info = try container.decode(SSLCertificateInfo.self, forKey: .info)
            }
        }
        
        struct SSLCertificateInfo: Decodable {
            var domains: SSLCertificateDomains
        }
        
        struct SSLCertificateDomains: Decodable {
            var commonName: String
        }
        
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://backloop.dev/pack.json")!)
        
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let cert = try decoder.decode(SSLCertificatePack.self, from: data)
            
            try cert.key.write(to: certURL.appendingPathComponent("server.pem"), atomically: true, encoding: .utf8)
            try cert.cert.write(to: certURL.appendingPathComponent("server.crt"), atomically: true, encoding: .utf8)
            try cert.info.domains.commonName.write(to: certURL.appendingPathComponent("cmnName"), atomically: true, encoding: .utf8)
            
            Alertinator.shared.alert(title: "Success!", body: "Successfully fetched SSL certificates!")
        } catch {
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    throw "[updateLocalInstallCertificate] we're missing something. \(key), \(context)"
                case .typeMismatch(let type, let context):
                    throw "[updateLocalInstallCertificate] great. we fucked the types. \(type), \(context)"
                default:
                    throw "[updateLocalInstallCertificate] ??? \(decodingError)"
                }
            }
            throw "Error while writing SSL certificate files! \(error.localizedDescription)"
        }
    }
    
    @discardableResult
    func extractAppIcon(appFolderURL: URL) -> URL {
        let fileManager = FileManager.default
        
        guard let appBundleContents = try? fileManager.contentsOfDirectory(at: appFolderURL, includingPropertiesForKeys: nil, options: []) else {
            return Bundle.main.url(forResource: "empty", withExtension: "png")!
        }
        
        let iconFiles = appBundleContents.filter { $0.lastPathComponent.hasPrefix("AppIcon") }
        
        let sortedIconFiles = iconFiles.sorted { (url1, url2) -> Bool in
            let resolution1 = url1.lastPathComponent.components(separatedBy: "-").last?.components(separatedBy: "x").first.flatMap { Int($0) } ?? 0
            let resolution2 = url2.lastPathComponent.components(separatedBy: "-").last?.components(separatedBy: "x").first.flatMap { Int($0) } ?? 0
            
            return resolution1 > resolution2
        }
        
        guard let iconFileURL = sortedIconFiles.first,
              fileManager.fileExists(atPath: iconFileURL.path) else {
            return Bundle.main.url(forResource: "empty", withExtension: "png")!
        }
        
        return iconFileURL
    }
    
    func extractInfoPlistField(appFolderURL: URL, field: String) -> String {
        let fileManager = FileManager.default
        
        let infoPlistURL = appFolderURL.appendingPathComponent("Info.plist")
        
        guard fileManager.fileExists(atPath: infoPlistURL.path) else {
            print("Info.plist not found in the app bundle.")
            return ""
        }
        
        guard let infoPlistData = try? Data(contentsOf: infoPlistURL),
              let infoPlist = try? PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any],
              let fieldValue = infoPlist[field] as? String else {
            print("Could not get field from the Info.plist.")
            return ""
        }
        
        return fieldValue
    }
}
