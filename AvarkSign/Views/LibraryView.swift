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

struct AppCustomizationView: View {
    let app: LibraryApp
    
    @StateObject private var certManager = CertificateManager()
    
    @FocusState private var keyboardFocused: Bool
    
    @AppStorage("installMethod") private var installMethod: Int = 0
    
    @Environment(\.dismiss) var dismiss
    
    @State private var customAppName: String = ""
    @State private var customBundleID: String = ""
    @State private var customBundleVersion: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: HStack {
                        Image(systemName: "apps.iphone")
                        Text("Basic Info")
                    }, content: {
                        AvarkTextField(text: "App Name (\(app.name))", inputType: nil, fieldData: $customAppName)
                        AvarkTextField(text: "Identifier (\(app.bundleIdentifier))", inputType: nil, fieldData: $customBundleID)
                        AvarkTextField(text: "Version (\(app.bundleVersion))", inputType: nil, fieldData: $customBundleVersion)
//                        VStack {
//                            HStack {
//                                Spacer()
//                                if #available(iOS 26.0, *) {
//                                    URLImageView(url: app.iconURL.absoluteString)
//                                        .frame(width: 80, height: 80)
//                                        .cornerRadius(18)
//                                        .glassEffect(in: .rect(cornerRadius: 14))
//                                } else {
//                                    URLImageView(url: app.iconURL.absoluteString)
//                                        .frame(width: 80, height: 80)
//                                        .cornerRadius(18)
//                                }
//                                Spacer()
//                            }
//                            Text(app.name)
//                                .font(.title2)
//                        }
                    })
                    
                    Section(header: HStack {
                        Image(systemName: "document")
                        Text("Tweaks")
                    }, content: {
                        HStack {
                            Spacer()
                            Text("eta s0n")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    })
                    
                    Section(header: HStack {
                        Image(systemName: "person.text.rectangle")
                        Text("Certificate")
                    }, content: {
                        let cert = certManager.activeCertificate!
                        let certURL = cert.url
                        
                        let mpPath = certURL.appendingPathComponent("mp.mobileprovision")
                        HStack(spacing: 16) {
                            Image(systemName: "signature")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 54, height: 54)
                            
                            VStack(alignment: .leading) {
                                Text(cert.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text("Expires on \(certManager.parseExpirationDate(url: mpPath))")
                                    .font(.subheadline)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                        }
                    })
                    
                    Section {
                        AvarkButton(text: "Install", icon: "arrow.down", foregroundStyle: .accent, isDisabled: false, action: {
                            Task {
                                await Sideloading.shared.sideload(app: app, cert: certManager.activeCertificate!, customizationOptions: Sideloading.AppCustomizationOptions(appName: customAppName, bundleID: customBundleID, bundleVersion: customBundleVersion), installMethod: installMethod)
                            }
                        })
                    }
                }
            }
            .navigationTitle("Customize \(app.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        dismiss()
                    }, label: {
                        AvarkCloseButton()
                    })
                })
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
    @State private var showCustomizationView: Bool = false
    
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
                            let success = await Sideloading.shared.sideload(app: app, cert: cert, installMethod: installMethod)

                            await MainActor.run {
                                isLoading = false
                                if success {
//                                    openURL(url)
                                    dropDatConfetti()
                                } else {
                                    print("well damn")
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
                    if certManager.activeCertificate != nil {
                        showCustomizationView.toggle()
                    } else {
                        Alertinator.shared.alert(title: "No certificates!", body: "Please import a certificate in the Settings tab.")
                    }
                }) {
                    Label("Customize and Install", systemImage: "paintpalette")
                }
            }, label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "arrow.down")
                            .imageScale(.medium)
                            .frame(width: 42, height: 42)
                            .foregroundStyle(.primary)
                            .foregroundStyle(.accent)
                            .clipShape(.circle)
                            .glassEffect(.regular.interactive(), in: .circle)
                    } else {
                        Image(systemName: "arrow.down")
                            .imageScale(.medium)
                            .frame(width: 42, height: 42)
                            .foregroundStyle(.primary)
                            .foregroundStyle(.accent)
                            .clipShape(.circle)
                    }
                }
            })
        }
        .sheet(isPresented: $showCustomizationView) {
            AppCustomizationView(app: app)
        }
    }
}

#Preview {
    LibraryView()
}
