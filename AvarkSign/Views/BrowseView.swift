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
                            if #available(iOS 26.0, *) {
                                VStack {
                                    Text("No sources added!")
                                        .font(.system(.title2, weight: .semibold))
                                    HStack(spacing: 0) {
                                        Text("Press the ")
                                            .opacity(0.6)
                                        Image(systemName: "plus")
                                        Text(" button to add a source URL.")
                                            .opacity(0.6)
                                    }
                                }
                                .listRowInsets(EdgeInsets())
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 26.0))
                            } else {
                                VStack {
                                    Text("No sources imported!")
                                        .font(.system(.title2, weight: .semibold))
                                    HStack(spacing: 0) {
                                        Text("Press the ")
                                            .opacity(0.6)
                                        Image(systemName: "plus")
                                        Text(" button to add a source URL.")
                                            .opacity(0.6)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color(.accent))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        Task {
                            Alertinator.shared.prompt(title: "Enter Source URL", placeholder: "URL") { urlString in
                                if let isEmpty = urlString, !urlString!.isEmpty {
                                    if let url = URL(string: urlString!) {
                                        do {
                                            try await repoManager.addRepo(url: url)
                                            dropDatConfetti()
                                        } catch {
                                            print(error)
                                            Alertinator.shared.alert(title: "Error adding source!", body: "Failed to add the source. \(error)")
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
