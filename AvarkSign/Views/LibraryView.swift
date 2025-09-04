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
                        let remoteAppData = libraryManager.apps.filter { $0.cameFromRepo }
                        
                        if !remoteAppData.isEmpty {
                            Section {
                                ForEach(remoteAppData) { app in
                                    InlineAppCard(app: app)
                                }
                                .onDelete(perform: libraryManager.removeApp)
                            } header: {
                                HStack {
                                    Image(systemName: "wifi")
                                    Text("Remote")
                                }
                            }
                        }
                        
                        let importedAppData = libraryManager.apps.filter { !$0.cameFromRepo }
                        
                        if !importedAppData.isEmpty {
                            Section {
                                ForEach(importedAppData) { app in
                                    InlineAppCard(app: app)
                                }
                                .onDelete(perform: libraryManager.removeApp)
                            } header: {
                                HStack {
                                    Image(systemName: "plus.square.fill")
                                    Text("Imported")
                                }
                            }
                        }
                        
                    } else {
                        Section {
                            if #available(iOS 26.0, *) {
                                VStack {
                                    Text("No apps imported!")
                                        .font(.system(.title2, weight: .semibold))
                                    HStack(spacing: 0) {
                                        Text("Press the ")
                                            .opacity(0.6)
                                        Image(systemName: "plus")
                                        Text(" button to import an IPA.")
                                            .opacity(0.6)
                                    }
                                }
                                .listRowInsets(EdgeInsets())
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 26.0))
                                .listRowBackground(Color(.accent))
                            } else {
                                VStack {
                                    Text("No apps imported!")
                                        .font(.system(.title2, weight: .semibold))
                                    HStack(spacing: 0) {
                                        Text("Press the ")
                                            .opacity(0.6)
                                        Image(systemName: "plus")
                                        Text(" button to import an IPA.")
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
            .navigationTitle("Library")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Menu(content: {
                        Button(action: {
                            showImportSheet = true
                        }) {
                            Image(systemName: "folder")
                            Text("Import from Files")
                        }
                        
                        Button(action: {
                            Task {
                                Alertinator.shared.prompt(title: "Enter IPA URL", placeholder: "URL") { urlString in
                                    if let isEmpty = urlString, !urlString!.isEmpty {
                                        if let url = URL(string: urlString!) {
                                            do {
                                                let tmpDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("tmp/")
                                                let ipaURL = try await Downloadinator(from: url, to: tmpDirURL!.appendingPathComponent("downloadTmp.ipa"))
                                                try libraryManager.importApp(ipaURL: ipaURL, fromRepo: true)
                                                dropDatConfetti()
                                            } catch {
                                                print(error)
                                                Alertinator.shared.alert(title: "Error downloading IPA!", body: "Failed to import app from URL. \(error)")
                                            }
                                        } else {
                                            Alertinator.shared.alert(title: "Invalid URL!", body: "Make sure the URL is typed correctly.")
                                        }
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "link")
                            Text("Import from URL")
                        }
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
                        try libraryManager.importApp(ipaURL: selectedIPAURL!, fromRepo: false)
                        dropDatConfetti()
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
                if #available(iOS 26.0, *) {
                    HStack(spacing: 12) {
                        URLImageView(url: app.iconURL.absoluteString)
                            .frame(width: 50, height: 50)
                            .cornerRadius(14)
                            .glassEffect(in: .rect(cornerRadius: 14))
                        
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
                } else {
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
//                                    openURL(url)
                                    dropDatConfetti()
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
                    if #available(iOS 26.0, *) {
                        HStack {
                            Text("Install")
                                .foregroundStyle(.white)
                        }
                        .padding(8)
                        .background(.accent)
                        .cornerRadius(50)
                        .glassEffect(.regular.interactive())
                    } else {
                        HStack {
                            Text("Install")
                                .foregroundStyle(.white)
                        }
                        .padding(8)
                        .background(.accent)
                        .cornerRadius(50)
                    }
                }
            })
        }
    }
}

#Preview {
    LibraryView()
}
