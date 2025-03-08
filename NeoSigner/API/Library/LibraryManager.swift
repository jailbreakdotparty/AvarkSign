//
//  LibraryManager.swift
//  NeoSigner
//
//  Created by Skadz on 3/4/25.
//

import Foundation
import SwiftUI
import ZIPFoundation

struct LibraryApp: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var subtitle: String?
    var bundleIdentifier: String
    var bundleVersion: String
    var iconURL: URL
    var bundleURL: URL
    var cameFromRepo: Bool
}

class LibraryManager: ObservableObject {
    @Published var apps: [LibraryApp] = []
    
    init() {
        loadApps()
    }
    
    func importApp(ipaURL: URL) throws {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appsDirectory = documentsDirectory.appendingPathComponent("apps/")
        
        let appUUID = UUID().uuidString
        let bundleURL = appsDirectory.appendingPathComponent("\(appUUID)/")
        if !fileManager.fileExists(atPath: bundleURL.path()) {
            do {
                try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)
            } catch {
                throw "[LibraryManager-importApp] Failed to create folder for app bundle!"
            }
        }
        
        print("[LibraryManager-importApp] Requesting access to IPA...")
        let accessing = ipaURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                ipaURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let archive = try Archive(url: ipaURL, accessMode: .read)
        
        print("[LibraryManager-importApp] Archive listing:")
        archive.forEach { entry in
            if entry.type == .directory {
                print("[LibraryManager-importApp] 📁 \(entry.path)")
            } else if entry.type == .file {
                print("[LibraryManager-importApp] 📄 \(entry.path), \(format(bytes: Double(entry.uncompressedSize)))")
            } else if entry.type == .symlink {
                print("[LibraryManager-importApp] aight why tf is there a symlink in here")
            }
        }
        
        try fileManager.unzipItem(at: ipaURL, to: bundleURL)
        
        // all this stuff is here just to move the .app to the root of our funny app folder cause having a payload folder is ass
        guard let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: nil),
              var appFolderURL = enumerator.allObjects.first(where: { ($0 as? URL)?.pathExtension == "app" }) as? URL else {
            throw "[LibraryManager-importApp] Unable to find .app folder in archive! Make sure the IPA is properly structured."
        }
        
        let stupidDumbPayloadFolder = appFolderURL.deletingLastPathComponent()
        try fileManager.moveItem(at: appFolderURL, to: bundleURL.appendingPathComponent(appFolderURL.lastPathComponent))
        appFolderURL = bundleURL.appendingPathComponent(appFolderURL.lastPathComponent)
        try fileManager.removeItem(at: stupidDumbPayloadFolder)
        
        let infoPlistURL = appFolderURL.appendingPathComponent("Info.plist")
        
        guard fileManager.fileExists(atPath: infoPlistURL.path) else {
            throw "[LibraryManager-importApp] Info.plist does not fucking exist."
        }
        
        // all this stupid shit to prepare for the LibraryApp object
        var appName = Sideloading().extractFieldFromPlist(at: infoPlistURL, field: "CFBundleDisplayName")
        if appName == "unknown" {
            appName = Sideloading().extractFieldFromPlist(at: infoPlistURL, field: "CFBundleName")
        }
        var bundleVersion = Sideloading().extractFieldFromPlist(at: infoPlistURL, field: "CFBundleShortVersionString")
        if bundleVersion == "unknown" {
            bundleVersion = Sideloading().extractFieldFromPlist(at: infoPlistURL, field: "CFBundleVersion")
        }
        let bundleID = Sideloading().extractFieldFromPlist(at: infoPlistURL, field: "CFBundleIdentifier")
        let iconURL = Sideloading().extractAppIcon(appFolderURL: appFolderURL)
        
        apps.append(LibraryApp(name: appName, bundleIdentifier: bundleID, bundleVersion: bundleVersion, iconURL: iconURL, bundleURL: appFolderURL, cameFromRepo: false))
        
        saveApps()
        loadApps()
        
        return
    }
    
    func saveApps() {
        if let encoded = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(encoded, forKey: "libraryApps")
        }
    }
    
    func loadApps() {
        if let data = UserDefaults.standard.data(forKey: "libraryApps") {
            if let decoded = try? JSONDecoder().decode([LibraryApp].self, from: data) {
                self.apps = decoded
            }
        }
    }
    
    func removeApp(at offsets: IndexSet) {
        for i in offsets.sorted(by: >) {
            if i < apps.count {
                let appToDelete = apps[i]
                try? FileManager.default.removeItem(at: appToDelete.bundleURL.deletingLastPathComponent())
                apps.remove(at: i)
            }
        }
        saveApps()
    }
}
