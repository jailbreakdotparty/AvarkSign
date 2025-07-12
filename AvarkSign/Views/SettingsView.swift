//
//  SettingsView.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("installMethod") private var installMethod: Int = 0 // 0 = Remote, 1 = Local
    @AppStorage("hasLocalInstallCert") private var hasLocalInstallCert: Bool = false
    @AppStorage("confettiModeActivated") private var confettiModeActivated: Bool = false
    
    @State private var showCertImportSheet: Bool = false
    @StateObject private var certManager = CertificateManager()
    @State private var nonSuspiciousIntName: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Text("AvarkSign")
                                    .font(.system(size: 50, weight: .medium))
                                    .lineLimit(1)
                                    .onLongPressGesture {
                                        // trolley
                                        Alertinator.shared.alert(title: "Disclaimer", body: "jailbreak.party and its team members are not affilated with any iOS signing certificate distribution companies. Any resemblance to distributors naughty or nice is purely coincidental.")
                                    }
                                Text("Made by Skadz")
                                    .font(.system(size: 20, weight: .regular))
                                    .lineLimit(1)
                                Text("\nSpecial thanks to:\nzhlynn    loyahdev    khcrysalis\nLrdsnow   lunginspector   bebebole")
                                    .font(.system(size: 12.5, weight: .light))
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                    }
                    
                    Section(header: Text("Sideloading"), footer: Text("Remote: Relies on an external online server to provide HTTPS for the app installation.\n\nLocal: Uses the public backloop.dev SSL certificate to host an HTTPS server completely on-device."), content: {
                        Picker("Install Method", selection: $installMethod) {
                            Text("Remote")
                                .tag(0)
                            Text("Local")
                                .tag(1)
                        }
                        .pickerStyle(.menu)
                        Button(action: {
                            Task {
                                do {
                                    try await Sideloading.shared.updateLocalInstallCertificate()
                                    hasLocalInstallCert = true
                                } catch {
                                    print(error)
                                    Alertinator.shared.alert(title: "Error while fetching SSL certificates!", body: "Failed to fetch SSL certificates: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text(hasLocalInstallCert ? "SSL certificates found!" : "Download SSL certificates")
                                Text(hasLocalInstallCert ? "Local installation should be working now." : "Required for local installation.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(hasLocalInstallCert)
                    })
                    .onChange(of: installMethod, perform: { new in
                        if new == 1 && !hasLocalInstallCert {
                            Alertinator.shared.alert(title: "Missing SSL certificates!", body: "Local installation requires HTTPS SSL certificates pointing to localhost (backloop.dev by default). Press the big download button to download the certificate.")
                            installMethod = 0
                            return
                        }
                    })
                    
                    Section(header: Text("Certificates"), content: {
                        if certManager.certificates.isEmpty {
                            AddCertificateCard(certManager: certManager)
                        } else {
                            ForEach(certManager.certificates) { cert in
                                CertificateSelectionCard(certManager: certManager, certificate: cert)
                            }
                            .onDelete(perform: certManager.deleteCert)
                            
                            Button(action: {
                                showCertImportSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .imageScale(.large)
                                    Text("Add new certificate")
                                }
                            }
                        }
                    })
                    
                    Section(header: Text("Debug"), content: {
                        Button(action: {
                            let fileManager = FileManager.default
                            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let libraryManager = LibraryManager()
                            let repoManager = RepoManager()

                            do {
                                let filePaths = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
                                
                                for filePath in filePaths {
                                    let fullFilePath = documentsDirectory.appendingPathComponent(filePath).path
                                    try fileManager.removeItem(atPath: fullFilePath)
                                }
                                
                                libraryManager.apps = []
                                libraryManager.saveApps()
                                
                                repoManager.repos = []
                                repoManager.saveRepos()
                                
                                certManager.certificates = []
                                certManager.saveCertificates()
                                
                                Alertinator.shared.alert(title: "Success!", body: "Successfully cleared all backend data. Please restart the app.", action: {
                                    exitApp()
                                })
                            } catch {
                                print(error)
                                Alertinator.shared.alert(title: "Error!", body: "Failed to clear backend data: \(error.localizedDescription).")
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text("Clear all backend data")
                                Text("This will remove all imported repos, apps, and certificates.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    })
                    
                    Section(header: Text("Logs"), content: {
                        HStack {
                            Spacer()
                            ZStack {
                                LogView()
                                    .padding(0.25)
                                    .frame(width: 340, height: 340)
                            }
                            Spacer()
                        }
                    })
                    
                    Section(header: Text("Socials"), content: {
                        Text("[Join our Discord!](https://discord.gg/XPj66zZ4gT)")
                        Text("[View the GitHub!](https://github.com/jailbreakdotparty/AvarkSign)")
                    })
                    
                    Section(footer: Text("AvarkSign v0.1 (\(weOnADebugBuild ? "Debug" : "Release"))\n[\"It won't give you a $1 discount code...\"](https://tikolu.net/i/llkvb)").onTapGesture(perform: {
                        nonSuspiciousIntName += 1
                        
                        if nonSuspiciousIntName == 8 {
                            if confettiModeActivated {
                                Alertinator.shared.alert(title: "Nice try.", body: "Did you really think doing that again would somehow disable Confetti Mode? You'll have to try harder than that.")
                            } else {
                                confettiModeActivated = true
                                Alertinator.shared.alert(title: "🎉", body: "Confetti Mode activated! You'll find out what it does in due time. No, you can't turn it off. You did this to yourself.")
                            }
                        }
                    }), content: {})
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCertImportSheet, content: {
                ImportCertificateView(certManager: certManager)
            })
        }
    }
}

#Preview {
    SettingsView()
}
