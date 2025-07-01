//
//  RepoDetailViews.swift
//  NeoSigner
//
//  Created by Skadz on 2/25/25.
//

import SwiftUI
import NukeUI
import ZIPFoundation

struct RepoDetailView: View {
    let repo: Repo
    @State private var repoManager = RepoManager()
    @State private var repoColor: Color = .accentColor
    
    var body: some View {
        VStack {
            List {
                HStack {
                    HStack {
                        if let iconURL = repo.iconURL, repo.iconURL != nil {
                            URLImageView(url: iconURL)
                                .frame(width: 75, height: 75)
                                .cornerRadius(16)
                        } else {
                            AnyView(appIconImage)
                                .frame(width: 75, height: 75)
                                .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(repo.name)
                                .font(.system(size: 34, weight: .bold))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                                .foregroundStyle(repoColor)
                                .multilineTextAlignment(.leading)
                            Text(LocalizedStringKey((repo.subtitle ?? repo.description) ?? "*No description provided.*"))
                                .minimumScaleFactor(0.6)
                                .lineLimit(2)
                                .opacity(0.6)
                                .foregroundStyle(repoColor)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .onAppear(perform: {
                        Task {
                            repoColor = await repoManager.getRepoColor(repo)
                        }
                    })
                }
                .padding(.vertical, 3.5)
                .listRowBackground(Color.clear)
                
                Section(header: Text("Apps")) {
                    ForEach(repo.apps) { app in
                        NavigationLink(destination: AppDetailView(app: app, repoColor: repoColor)) {
                            HStack {
                                URLImageView(url: app.iconURL)
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading) {
                                    Text(app.name)
                                        .font(.headline)
                                    Text(LocalizedStringKey(app.subtitle ?? app.developerName))
                                        .lineLimit(1)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if let website = repo.website {
                        Link(destination: URL(string: website)!) {
                            Image(systemName: "globe")
                                .foregroundStyle(repoColor)
                        }
                    }
                }
            }
        }
    }
}

struct AppDetailView: View {
    let app: RepoApp
    let repoColor: Color
    
    @StateObject private var certManager = CertificateManager()
    @StateObject private var libraryManager = LibraryManager()
    
    @AppStorage("installMethod") private var installMethod: Int = 0
    
    @Environment(\.openURL) var openURL
    
    @State private var showShareSheet: Bool = false
    @State private var shareURL: String = ""
    
    var body: some View {
        VStack {
            List {
                HStack {
                    VStack {
                        HStack {
                            URLImageView(url: app.iconURL)
                                .frame(width: 75, height: 75)
                                .cornerRadius(16)
                            
                            VStack(alignment: .leading) {
                                Text(app.name)
                                    .font(.system(size: 34, weight: .bold))
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                                    .foregroundStyle(repoColor)
                                    .multilineTextAlignment(.leading)
                                Text(LocalizedStringKey(app.subtitle ?? app.localizedDescription))
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                    .opacity(0.6)
                                    .foregroundStyle(repoColor)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                .padding(.top, 3.5)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                HStack {
                    Button(action: {
                        do {
                            Haptic.shared.play(.rigid)
                            var downloadURL = ""
                            
                            if let version = app.getLatestVersion() {
                                downloadURL = version.downloadURL
                            } else if let appDownloadURL = app.downloadURL, !appDownloadURL.isEmpty {
                                downloadURL = appDownloadURL
                            } else {
                                Alertinator.shared.alert(title: "Error downloading app", body: "Failed to get app download URL!")
                                return
                            }
                            
                            Task {
                                let tmpDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("tmp/")
                                let ipaURL = try await Downloadinator(from: URL(string: downloadURL)!, to: tmpDirURL!.appendingPathComponent("downloadTmp.ipa"))
                                try libraryManager.importApp(ipaURL: ipaURL, fromRepo: true)
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .padding(8)
                    }
                    .background(Color(UIColor.tertiarySystemFill))
                    .clipShape(.circle)
                }
                .listRowBackground(Color.clear)
                
                if !app.screenshotURLs.isEmpty {
                    Section(header: Text("Screenshots"), content: {
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(spacing: 10) {
                                ForEach(app.screenshotURLs, id: \.self) { screenshotURL in
                                    ScreenshotImageView(url: screenshotURL)
                                        .cornerRadius(8)
                                }
                            }
                            Spacer()
                        }
                    })
                    .listRowBackground(Color.clear)
                }
            }
        }
        .tint(repoColor)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        Haptic.shared.play(.rigid)
                        var downloadURL = ""
                        
                        if let version = app.getLatestVersion() {
                            downloadURL = version.downloadURL
                        } else if let appDownloadURL = app.downloadURL, !appDownloadURL.isEmpty {
                            downloadURL = appDownloadURL
                        } else {
                            Alertinator.shared.alert(title: "Error sharing IPA", body: "Failed to get app download URL!")
                            return
                        }
                        
                        presentShareSheet(with: URL(string: downloadURL)!)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(repoColor)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RepoDetailView(repo: RepoManager().repos[1])
    }
}
