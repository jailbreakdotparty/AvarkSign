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
