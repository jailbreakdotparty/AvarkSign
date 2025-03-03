//
//  BrowseView.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI
import NukeUI

struct BrowseView: View {
    @StateObject private var repoManager = RepoManager()
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !repoManager.repos.isEmpty {
                        Section(header: Text("Repos"), content: {
                            ForEach(repoManager.repos) { repo in
                                NavigationLink(destination: RepoDetailView(repo: repo)) {
                                    HStack {
                                        if let iconURL = repo.iconURL, !iconURL.isEmpty {
                                            URLImageView(url: iconURL)
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(12)
                                        } else {
                                            MissingIconView()
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(12)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(repo.name)
                                                .font(.headline)
                                            if let subtitle = repo.subtitle {
                                                Text(subtitle)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: repoManager.deleteRepo)
                        })
                    } else {
                        Section {
                            VStack {
                                Text("No sources added!")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 24, weight: .medium))
                                HStack(spacing: 0) {
                                    Text("Press the ")
                                        .foregroundStyle(.tertiary)
                                        .font(.system(size: 18, weight: .medium))
                                    Image(systemName: "plus")
                                        .foregroundStyle(.accent)
                                        .imageScale(.medium)
                                    Text(" button to add a source URL.")
                                        .foregroundStyle(.tertiary)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        Task {
                            Alertinator.shared.prompt(title: "Enter Repo URL", placeholder: "URL") { urlString in
                                if let isEmpty = urlString, !urlString!.isEmpty {
                                    if let url = URL(string: urlString!) {
                                        do {
                                            try await repoManager.addRepo(url: url)
                                        } catch {
                                            print(error)
                                            Alertinator.shared.alert(title: "Error adding repo!", body: "Failed to add the repo. \(error)")
                                        }
                                    } else {
                                        Alertinator.shared.alert(title: "Invalid URL!", body: "Make sure the URL is typed correctly.")
                                    }
                                }
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                })
            })
        }
    }
}

#Preview {
    BrowseView()
}
