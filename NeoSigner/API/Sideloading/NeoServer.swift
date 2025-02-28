//
//  OctopusServer.swift
//  Octopus
//
//  Created by Skadz on 11/17/24.
//  A lot of this was skidded from Feather 💀
//

import Foundation
import Vapor
import NIOSSL

class NeoServer: ObservableObject {
    static let shared = NeoServer()
    
    deinit {
        stopServer()
    }
    
    func setupServerFiles(ipaPath: URL, appIconPath: URL, manifestPath: URL) throws -> URL {
        let fileManager = FileManager.default
        do {
            let serverDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("server/")
            try fileManager.createDirectory(at: serverDirectory!, withIntermediateDirectories: true, attributes: nil)
            // Copy signed IPA to /signed.ipa
            try fileManager.copyItem(at: ipaPath, to: serverDirectory!.appendingPathComponent("signed.ipa"))
            try fileManager.removeItem(at: ipaPath)
            // Copy AppIcon to /appIcon.png
            try fileManager.copyItem(at: appIconPath, to: serverDirectory!.appendingPathComponent("appIcon.png"))
            // Copy install manifest to /install.plist
            try fileManager.copyItem(at: manifestPath, to: serverDirectory!.appendingPathComponent("install.plist"))
            try fileManager.removeItem(at: manifestPath)
            return serverDirectory!.absoluteURL
        } catch {
            print("[!] Failed to setup server files")
            print(error)
            throw error
        }
    }
    
    func setupTLSConfig() throws -> TLSConfiguration {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let certsDirectory = documentsDirectory.appendingPathComponent("certificates/")
        
        let certURL = certsDirectory.appendingPathComponent("ssl/")
        
        do {
            let crtURL = certURL.appendingPathComponent("server.crt").path
            let keyURL = certURL.appendingPathComponent("server.pem").path
            return try TLSConfiguration.makeServerConfiguration(
                certificateChain: NIOSSLCertificate
                    .fromPEMFile(crtURL)
                    .map { NIOSSLCertificateSource.certificate($0) },
                privateKey: .privateKey(try NIOSSLPrivateKey(file: keyURL, format: .pem))
            )
        } catch {
            print("[!] Failed to configure SSL")
            print(error)
            throw error
        }
    }
    
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "pdp_ip0" {
                        
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                       &hostname, socklen_t(hostname.count),
                                       nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: hostname)
                        }
                        
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    var installManifestURL: URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let certsDirectory = documentsDirectory.appendingPathComponent("certificates/")
        
        let certURL = certsDirectory.appendingPathComponent("ssl/")
        
        let serverHostnameThingy = getServerHostnameThingy(certURL: certURL)
        
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = serverHostnameThingy
        comps.path = "/install.plist"
        comps.port = 8080
        return comps.url!
    }
    
    var installURL: URL {
        var comps = URLComponents()
        comps.scheme = "itms-services"
        comps.path = "/"
        comps.queryItems = [
            URLQueryItem(name: "action", value: "download-manifest"),
            URLQueryItem(name: "url", value: installManifestURL.absoluteString),
        ]
        comps.port = nil
        return comps.url!
    }
    
    let app = Application(.development)
    
    func startServer(_ serverFilesPath: URL) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let certsDirectory = documentsDirectory.appendingPathComponent("certificates/")
        
        let certURL = certsDirectory.appendingPathComponent("ssl/")
        
        let serverHostnameThingy = getServerHostnameThingy(certURL: certURL)
        
        guard fileManager.fileExists(atPath: serverFilesPath.path) else {
            print("[!] Server files directory does not exist!")
            return
        }
        
        app.get("*") { req in
            switch req.url.path {
            case "/", "/index.html":
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "text/html",
                ], body: .init(string: "<html> <head> <meta http-equiv=\"refresh\" content=\"0;url=\(self.installURL)\"> </head> </html>"))
            case "/signed.ipa":
                if FileManager.default.fileExists(atPath: serverFilesPath.appendingPathComponent("signed.ipa").path) {
                    return req.fileio.streamFile(at: serverFilesPath.appendingPathComponent("signed.ipa").path)
                } else {
                    return Response(status: .notFound, body: .init(string: "404 Not Found"))
                }
            case "/appIcon.png":
                if fileManager.fileExists(atPath: serverFilesPath.appendingPathComponent("appIcon.png").path) {
                    let appIconData = try? Data(contentsOf: serverFilesPath.appendingPathComponent("appIcon.png"))
                    return Response(status: .ok, headers: ["Content-Type": "image/png",], body: .init(data: appIconData!))
                } else {
                    return Response(status: .notFound, body: .init(string: "404 Not Found"))
                }
            case self.installManifestURL.path:
                if fileManager.fileExists(atPath: serverFilesPath.appendingPathComponent("install.plist").path) {
                    let installManifestData = try? Data(contentsOf: serverFilesPath.appendingPathComponent("install.plist"))
                    return Response(status: .ok, headers: ["Content-Type": "text/xml",], body: .init(data: installManifestData!))
                } else {
                    return Response(status: .notFound, body: .init(string: "404 Not Found"))
                }
            default:
                return Response(status: .notFound)
            }
        }
        
        do {
            app.threadPool = .init(numberOfThreads: 1)
            app.http.server.configuration.tlsConfiguration = try setupTLSConfig()
            app.http.server.configuration.hostname = serverHostnameThingy
            app.http.server.configuration.tcpNoDelay = true
            app.http.server.configuration.address = .hostname("0.0.0.0", port: 8080)
            app.http.server.configuration.port = 8080
            app.routes.defaultMaxBodySize = "128mb"
            app.routes.caseInsensitive = false
            try app.server.start()
            print("[*] Successfully started server!")
        } catch {
            print("[!] Unable to start server!")
        }
    }
    
    func stopServer() {
        print("[*] Shutting down server...")
        let fileManager = FileManager.default
        let serverDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("server/")
        
        do {
            try fileManager.removeItem(at: serverDirectory!.appendingPathComponent("signed.ipa"))
            try fileManager.removeItem(at: serverDirectory!.appendingPathComponent("appIcon.png"))
            try fileManager.removeItem(at: serverDirectory!.appendingPathComponent("install.plist"))
            app.server.shutdown()
            app.shutdown()
        } catch {
            print("[!] Failed to stop server!")
            print(error)
            return
        }
    }
    
    func getServerHostnameThingy(certURL cert: URL) -> String {
        let installMethod = UserDefaults.standard.integer(forKey: "installMethod")
        if installMethod == 0 {
            return getLocalIPAddress() ?? "0.0.0.0"
        } else {
            do {
                let cmnName = try String(contentsOf: cert.appendingPathComponent("cmnName"), encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
                return cmnName
            } catch {
                print("[getServerHostnameThingy] epic fail! \(error)")
                return "0.0.0.0"
            }
        }
    }
}
