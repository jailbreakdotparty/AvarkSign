//
//  RepoDetailViews.swift
//  NeoSigner
//
//  Created by Skadz on 2/25/25.
//

import SwiftUI
import NukeUI

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
                                .font(.headline)
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
    
    var body: some View {
        List {
            HStack {
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
            .padding(.vertical, 3.5)
            .listRowBackground(Color.clear)
            
            Section(header: Text("Actions"), content: {
                Button("Install", action: {
                    var downloadURL = ""
                    
                    if let version = app.getLatestVersion() {
                        downloadURL = version.downloadURL
                    } else if let appDownloadURL = app.downloadURL, !appDownloadURL.isEmpty {
                        downloadURL = appDownloadURL
                    } else {
                        Alertinator.shared.alert(title: "Error downloading app", body: "Failed to get app download URL!")
                        return
                    }
                    
                    Alertinator.shared.alert(title: "Debug info", body: "Download URL: \(downloadURL)\n\n\(DeviceInfo.niceVersionString)")
                })
            })
        }
    }
}

