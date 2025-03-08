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
        var bundleVersion: String?
    }
    
    var hasStartedServer: Bool = false
    var hasDoneRemoteInstallSoWeCanCloseTheFuckingServer: Bool = false
    
    func sideload(app: LibraryApp, cert: Certificate, customizationOptions: AppCustomizationOptions? = nil, installMethod: Int) -> Bool {
        let mpPath: URL
        let p12Path: URL
        let p12Pass: String
        
        var appURL = app.bundleURL
        
        print("[-] Sideloading started.")
        
        let fileManager = FileManager.default
        
        print("[-] Fetching MobileProvision and P12 details from selected certificate...")
        do {
            let certURL = cert.url
            
            let passwordData = try Data(contentsOf: certURL.appendingPathComponent("p12_password"))
            p12Pass = String(data: passwordData, encoding: .utf8) ?? ""
            
            mpPath = certURL.appendingPathComponent("mp.mobileprovision")
            p12Path = certURL.appendingPathComponent("cert.p12")
        } catch {
            print("Failed to get MobileProvision and P12 info! Make sure you've selected a certificate and that the certificate files are valid.")
            print(error)
            return false
        }
        
        guard let destinationPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("tmp/") else {
            print("[!] Documents directory not found")
            return false
        }
        
        print("[-] Clearing out old files...")
        cleanup()
        
        Task {
            let code = zsign(appURL.path, mpPath.path, p12Path.path, p12Pass, customizationOptions?.bundleID ?? "", customizationOptions?.appName ?? "", customizationOptions?.bundleVersion ?? "", true)
            if code == 0 {
                print("[*] zsign returned 0, this is good.")
                let signedIPAPath = destinationPath.appendingPathComponent("signed.ipa")
                
                let payloadPath = destinationPath.appendingPathComponent("Payload")
                
                if !fileManager.fileExists(atPath: payloadPath.path) {
                    do {
                        try fileManager.createDirectory(at: payloadPath, withIntermediateDirectories: true)
                        try fileManager.copyItem(at: appURL, to: payloadPath.appendingPathComponent(appURL.lastPathComponent))
                        appURL = payloadPath.appendingPathComponent(appURL.lastPathComponent)
                    } catch {
                        print("[!] Failed to repackage IPA!")
                        return false
                    }
                }
                
                do {
                    try fileManager.zipItem(at: payloadPath, to: signedIPAPath)
                    print("[*] Zipping Payload folder successful. Signed IPA path: \(signedIPAPath.path)")
                } catch {
                    print("[!] Failed to zip the Payload folder: \(error)")
                    return false
                }
                
                let infoPlistURL = appURL.appendingPathComponent("Info.plist")
                
                let bundleId = extractFieldFromPlist(at: infoPlistURL, field: "CFBundleIdentifier")
                
                let bundleVersion = extractFieldFromPlist(at: infoPlistURL, field: "CFBundleVersion")
                
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
                                    <string>\(installMethod == 1 ? "https://neosigner.backloop.dev:8080/signed.ipa" : "http://localhost:8080/signed.ipa")</string>
                                </dict>
                                <dict>
                                    <key>kind</key>
                                    <string>display-image</string>
                                    <key>needs-shine</key>
                                    <false/>
                                    <key>url</key>
                                    <string>\(installMethod == 1 ? "https://neosigner.backloop.dev:8080/appIcon.png" : "http://localhost:8080/appIcon.png")</string>
                                </dict>
                                <dict>
                                    <key>kind</key>
                                    <string>full-size-image</string>
                                    <key>needs-shine</key>
                                    <false/>
                                    <key>url</key>
                                    <string>\(installMethod == 1 ? "https://neosigner.backloop.dev:8080/appIcon.png" : "http://localhost:8080/appIcon.png")</string>
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
                                <string>\(extractFieldFromPlist(at: infoPlistURL, field: "CFBundleDisplayName"))</string>
                            </dict>
                        </dict>
                    </array>
                </dict>
            </plist>
        """
                if let plistPath = createPlistFile(content: plistContent, destinationPath: destinationPath) {
                    print("[*] Installation manifest created at path: \(plistPath)")
                    var server: HttpServer = HttpServer()
                    
//                    if hasStartedServer && hasDoneRemoteInstallSoWeCanCloseTheFuckingServer {
//                        print("[*] Stopping server for remote install...")
//                        server.stop()
//                        hasStartedServer = false
//                        hasDoneRemoteInstallSoWeCanCloseTheFuckingServer = false
//                    }
                    
                    if installMethod == 1 {
                        do {
                            let serverBundle = try NeoServer.shared.setupServerFiles(ipaPath: signedIPAPath, appIconPath: extractAppIcon(appFolderURL: appURL), manifestPath: URL(fileURLWithPath: plistPath))
                            NeoServer.shared.startServer(serverBundle)
                        } catch {
                            print("[!] Failed to start server!")
                            print(error)
                            return false
                        }
                        
                        print("[*] Installing...")
                        await UIApplication.shared.open(NeoServer.shared.installURL)
                    } else if installMethod == 0 {
                        if !hasStartedServer {
                            do {
                                try server.start(8080)
                                hasStartedServer = true
                                print("[*] HTTP server started")
                            } catch {
                                print("[!] Failed to start server.")
                                return false
                            }
                        }
                        
                        server["/" + "signed.ipa"] = shareFile(signedIPAPath.path)
                        server["" + "appIcon.png"] = shareFile(extractAppIcon(appFolderURL: appURL).path)
                        server["/install.plist"] = shareFile(plistPath)
                        
                        print("[*] Installing...")
                        _ = await MainActor.run {
                            Task {
                                await UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=https://jailbreak.party/install")!)
                                hasDoneRemoteInstallSoWeCanCloseTheFuckingServer = true
                            }
                        }
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
        let allowedPaths = ["certificates", "apps"]
        
        do {
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }

            let filePaths = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)

            for filePath in filePaths {
                if !allowedPaths.contains(filePath) {
                    let fullFilePath = documentsDirectory.appendingPathComponent(filePath).path
                    
                    do {
                        try fileManager.removeItem(atPath: fullFilePath)
                        print("[cleanup] successfully removed \(filePath).")
                    } catch {
                        print("[cleanup] failed to delete \(filePath): \(error)")
                    }
                }
            }
        } catch {
            print("[cleanup] epic fail!: \(error)")
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
    
    func extractFieldFromPlist(at url: URL, field: String) -> String {        
        guard let infoPlistData = try? Data(contentsOf: url),
              let infoPlist = try? PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any],
              let fieldValue = infoPlist[field] as? String else {
            print("Failed to extract field from \(url.lastPathComponent)")
            return "unknown"
        }
        
        return fieldValue
    }
}
