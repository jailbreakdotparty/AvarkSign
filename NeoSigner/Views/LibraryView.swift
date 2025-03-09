//
//  LibraryView.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @StateObject private var libraryManager = LibraryManager()
    
    @State private var showImportSheet: Bool = false
    @State private var selectedIPAURL: URL?
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !libraryManager.apps.isEmpty {
                        Section(header: Text("Imported").foregroundStyle(.primary).font(.title2.weight(.bold)).textCase(nil), content: {
                            ForEach(libraryManager.apps) { app in
                                InlineAppCard(app: app)
                            }
                            .onDelete(perform: libraryManager.removeApp)
                        })
                    } else {
                        Section {
                            VStack {
                                Text("No apps imported!")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 24, weight: .medium))
                                HStack(spacing: 0) {
                                    Text("Press the ")
                                        .foregroundStyle(.tertiary)
                                        .font(.system(size: 18, weight: .medium))
                                    Image(systemName: "plus")
                                        .foregroundStyle(.accent)
                                        .imageScale(.medium)
                                    Text(" button to import an IPA.")
                                        .foregroundStyle(.tertiary)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Menu(content: {
                        Button(action: {
                            showImportSheet = true
                        }) {
                            Text("Import from Files")
                        }
                        
                        Button(action: {
                            Alertinator.shared.alert(title: "the heck??", body: "whar??")
                        }) {
                            Text("Import from URL")
                        }
                        .disabled(true)
                    }, label: {
                        Image(systemName: "plus")
                    })
                })
            })
            .fileImporter(
                isPresented: $showImportSheet,
                allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .archive]
            ) { result in
                switch result {
                case .success(let file):
                    selectedIPAURL = file.absoluteURL
                    do {
                        try libraryManager.importApp(ipaURL: selectedIPAURL!)
                    } catch {
                        print(error.localizedDescription)
                        Alertinator.shared.alert(title: "Error adding app!", body: "Failed to add app to library: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    Alertinator.shared.alert(title: "Error importing IPA!", body: "Failed to import IPA: \(error.localizedDescription)")
                }
            }
        }
    }
}

// didn't feel like moving these all into another big file, so all the library stuff shall be one
struct InlineAppCard: View {
    @StateObject private var certManager = CertificateManager()
    @AppStorage("installMethod") private var installMethod: Int = 0
    var app: LibraryApp
    @Environment(\.openURL) var openURL
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            HStack {
                URLImageView(url: app.iconURL.absoluteString)
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                
                VStack(alignment: .leading) {
                    Text(app.name)
                        .font(.headline)
                    Text(LocalizedStringKey("\(app.bundleVersion) • \(format(bytes: Double(folderSize(atPath: app.bundleURL.path))))"))
                        .font(.subheadline)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Menu(content: {
                Button(action: {
                    isLoading = true
                    
                    Task {
                        if let cert = certManager.activeCertificate {
                            let result = await Sideloading.shared.sideload(app: app, cert: cert, installMethod: installMethod)

                            await MainActor.run {
                                isLoading = false
                                if result.success, let url = result.installURL {
                                    openURL(url)
                                } else {
                                    Alertinator.shared.alert(title: "Error!", body: "Something went wrong. And I'm not sure what it was. 💀")
                                }
                            }
                        } else {
                            await MainActor.run {
                                isLoading = false
                                Alertinator.shared.alert(title: "No certificates!", body: "Please import a certificate in the Settings tab.")
                            }
                        }
                    }
                }) {
                    Label("Install", systemImage: "arrow.down")
                }
                
                Button(action: {
                    Alertinator.shared.alert(title: "the heck??", body: "whar??")
                }) {
                    Label("Customize and install", systemImage: "paintpalette")
                }
                .disabled(true)
            }, label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "arrow.down.app")
                        .imageScale(.large)
                }
            })
        }
    }
}

#Preview {
    LibraryView()
}
