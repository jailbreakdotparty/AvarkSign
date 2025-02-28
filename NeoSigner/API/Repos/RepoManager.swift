//
//  RepoManager.swift
//  Octopus
//
//  Created by Skadz on 12/26/24.
//

import Foundation
import SwiftUI
import UIKit

// AltStore repo format stuff
struct Repo: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var subtitle: String?
    var description: String?
    var iconURL: String?
    var headerURL: String?
    var website: String?
    var tintColor: String?
    var apps: [RepoApp] = []

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.iconURL = try container.decodeIfPresent(String.self, forKey: .iconURL)
        self.headerURL = try container.decodeIfPresent(String.self, forKey: .headerURL)
        self.website = try container.decodeIfPresent(String.self, forKey: .website)
        self.tintColor = try container.decodeIfPresent(String.self, forKey: .tintColor)
        self.apps = try container.decodeIfPresent([RepoApp].self, forKey: .apps) ?? []
        
        if (self.iconURL == nil || self.iconURL?.isEmpty == true), let appIconURL = self.apps.first?.iconURL {
            self.iconURL = appIconURL
        }
    }
}

struct RepoApp: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var bundleIdentifier: String
    var developerName: String
    var subtitle: String?
    var description: String?
    var localizedDescription: String
    var iconURL: String
    var tintColor: String?
    var category: String?
    
    var version: String?
    var versionDate: String?
    var downloadURL: String?
    var size: Int?
    
    var versions: [RepoAppVersion]
    
    enum CodingKeys: String, CodingKey {
        case name
        case bundleIdentifier
        case developerName
        case subtitle
        case description
        case localizedDescription
        case iconURL
        case tintColor
        case category
        case version
        case versionDate
        case downloadURL
        case size
        case versions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.developerName = try container.decode(String.self, forKey: .developerName)
        
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        
        if let locDesc = try container.decodeIfPresent(String.self, forKey: .localizedDescription) {
            self.localizedDescription = locDesc
        } else if let desc = self.description {
            self.localizedDescription = desc
        } else {
            self.localizedDescription = "*No description provided.*"
        }
        
        self.iconURL = try container.decode(String.self, forKey: .iconURL)
        self.tintColor = try container.decodeIfPresent(String.self, forKey: .tintColor)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.versionDate = try container.decodeIfPresent(String.self, forKey: .versionDate)
        self.downloadURL = try container.decodeIfPresent(String.self, forKey: .downloadURL)
        self.size = try container.decodeIfPresent(Int.self, forKey: .size)
        
        self.versions = try container.decodeIfPresent([RepoAppVersion].self, forKey: .versions) ?? []
        
        if self.versions.isEmpty && self.version != nil && self.downloadURL != nil {
            self.versions.append(RepoAppVersion(
                version: self.version ?? "Unknown",
                date: self.versionDate ?? "Unknown",
                downloadURL: self.downloadURL ?? "",
                size: self.size ?? 0
            ))
        }
    }
    
    func getLatestVersion() -> RepoAppVersion? {
        return versions.first
    }
}

struct RepoAppVersion: Codable, Identifiable, Hashable {
    var id = UUID()
    var version: String
    var buildVersion: String?
    var marketingVersion: String?
    var date: String
    var localizedDescription: String?
    var downloadURL: String
    var size: Int?
    
    enum CodingKeys: String, CodingKey {
        case version
        case buildVersion
        case marketingVersion
        case date
        case localizedDescription
        case downloadURL
        case size
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.version = try container.decode(String.self, forKey: .version)
        self.buildVersion = try container.decodeIfPresent(String.self, forKey: .buildVersion)
        self.marketingVersion = try container.decodeIfPresent(String.self, forKey: .marketingVersion)
        self.date = try container.decode(String.self, forKey: .date)
        self.localizedDescription = try container.decodeIfPresent(String.self, forKey: .localizedDescription)
        self.downloadURL = try container.decode(String.self, forKey: .downloadURL)
        self.size = try container.decodeIfPresent(Int.self, forKey: .size)
    }
    
    init(version: String, date: String, downloadURL: String, size: Int? = nil) {
        self.id = UUID()
        self.version = version
        self.date = date
        self.downloadURL = downloadURL
        self.size = size
    }
}

class RepoManager: ObservableObject {
    @Published var repos: [Repo] = []
    private let userDefaultsKey = "savedRepos"
    
    init() {
        loadRepos()
    }
    
    func addRepo(url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let repo = try decoder.decode(Repo.self, from: data)
            DispatchQueue.main.async {
                if !self.repos.contains(where: { $0.name == repo.name }) {
                    self.repos.append(repo)
                    self.saveRepos()
                }
            }
        } catch {
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("[RepoManager] we're missing something. \(key),\(context)")
                case .typeMismatch(let type, let context):
                    print("[RepoManager] great. we fucked the types. \(type),\(context)")
                default:
                    print("[RepoManager] ??? \(decodingError)")
                }
            }
            throw error
        }
    }
    
    private func saveRepos() {
        if let encoded = try? JSONEncoder().encode(repos) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadRepos() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([Repo].self, from: data) {
                self.repos = decoded
            }
        }
    }
    
    func deleteRepo(at offsets: IndexSet) {
        repos.remove(atOffsets: offsets)
        saveRepos()
    }
    
    // This is extremely overkill for getting the repo accent color. We really don't need all this but it's kinda cool so I guess it stays.
    func getRepoColor(_ repo: Repo) async -> Color {
        if let tintColor = repo.tintColor, !tintColor.isEmpty {
            return Color(hex: tintColor)
        } else {
            do {
                guard let iconURL = repo.iconURL, repo.iconURL != nil else {
                    print("[!] Repo is missing an icon!")
                    return .accent
                }
                let (data, _) = try await URLSession.shared.data(from: URL(string: iconURL)!)
                let dataUiImage = UIImage(data: data)
                let color = await averageColor(from: Image(uiImage: dataUiImage!))!
                return .init(uiColor: color)
            } catch {
                print("[!] Failed to get average repo color from icon! \(error.localizedDescription)")
                return .accent
            }
        }
    }
}
