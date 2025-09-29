//
//  SettingsView.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI
import UIKit
import DeviceKit
import ZsignSwift

struct SettingsView: View {
    @AppStorage("installMethod") private var installMethod: Int = 0 // 0 = Remote, 1 = Local
    @AppStorage("hasLocalInstallCert") private var hasLocalInstallCert: Bool = false
    @AppStorage("confettiModeActivated") private var confettiModeActivated: Bool = false
    
    @State private var showCertImportSheet: Bool = false
    @StateObject private var certManager = CertificateManager()
    @State private var nonSuspiciousIntName: Int = 0
    @State private var showLogsView: Bool = false
    
    @Environment(\.openURL) var openURL
    
    let device = Device.current
    let splashes: [String] = [ // feeling like Ryan Price (without the cow)
        "The signer of today! Tomorrow Update coming soon.",
        "ZipGod approved!",
        "Not your regular SwiftUI zsign wrapper!",
        "IPAs not included.",
        "Some assembly required.",
        "Certificates sold seperately.",
        "Do NOT tap the credit text 8 times!!",
        ":3"
    ]
    @State private var splashIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: HStack {
                        Image(systemName: "info.circle")
                        Text("About")
                    }, footer: VStack(alignment: .leading) {
                        Text("Made by jailbreak.party. Special thanks to zhylynn, loyahdev, khcrysalis, Lrdsnow, and bebebole.\n")
                            .onTapGesture(perform: {
                                nonSuspiciousIntName += 1
                                
                                if nonSuspiciousIntName == 8 {
                                    if confettiModeActivated {
                                        Alertinator.shared.alert(title: "Nice try.", body: "Did you really think doing that again would somehow disable Confetti Mode? You'll have to try harder than that.")
                                        nonSuspiciousIntName = 0
                                    } else {
                                        confettiModeActivated = true
                                        Alertinator.shared.alert(title: "🎉", body: "Confetti Mode activated! You'll find out what it does in due time. No, you can't turn it off. You did this to yourself.")
                                        nonSuspiciousIntName = 0
                                    }
                                }
                            })
                        Text("\(splashes[splashIndex])")
                    }) {
                        VStack {
                            HStack(spacing: 12) {
                                Image("AvarkSign")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(14)
                                VStack(alignment: .leading) {
                                    Text("AvarkSign")
                                        .font(.system(.title2, weight: .semibold))
                                    Text("Version \(UIApplication.appVersion!) (\(weOnADebugBuild ? "Debug" : "Release"))")
                                        .font(.callout)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onLongPressGesture {
                                // trolley
                                Alertinator.shared.alert(title: "Disclaimer", body: "jailbreak.party and its team members are not affilated with any iOS signing certificate distribution companies. Any resemblance to distributors naughty or nice is purely coincidental.")
                            }
                            
                            HStack {
                                AvarkButton(text: "Discord", icon: "message", foregroundStyle: .blue, isDisabled: false, action: {
                                    openURL(URL(string: "https://jailbreak.party/discord")!)
                                })
                                AvarkButton(text: "GitHub", icon: "apple.terminal", foregroundStyle: .accent, isDisabled: false, action: {
                                    openURL(URL(string: "https://github.com/jailbreakdotparty/AvarkSign")!)
                                })
                            }
                        }
                    }
                    
                    Section(header: HStack {
                        Image(systemName: "plus.app")
                        Text("Sideloading")
                    }, footer: HStack {
                        Text("Remote: Relies on an external online server to provide HTTPS for the app installation.\n\nLocal: Uses the public backloop.dev SSL certificate to host an HTTPS server completely on-device.")
                    }) {
                        VStack(spacing: 14) {
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
                                if #available(iOS 26.0, *) {
                                    HStack {
                                        Image(systemName: hasLocalInstallCert ? "checkmark.circle" : "arrow.down.doc")
                                        
                                        VStack(alignment: .leading) {
                                            Text(hasLocalInstallCert ? "SSL certificates found!" : "Download SSL certificates")
                                        }
                                    }
                                    .padding(.vertical, 13)
                                    .frame(maxWidth: .infinity)
                                    .background(hasLocalInstallCert ? .green.opacity(0.2) : .accent.opacity(0.2))
                                    .cornerRadius(14)
                                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14.0))
                                    .foregroundStyle(hasLocalInstallCert ? .green : .accent)
                                    .buttonStyle(.plain)
                                } else {
                                    HStack {
                                        Image(systemName: hasLocalInstallCert ? "checkmark.circle" : "arrow.down.doc")
                                        
                                        VStack(alignment: .leading) {
                                            Text(hasLocalInstallCert ? "SSL certificates found!" : "Download SSL certificates")
                                        }
                                    }
                                    .padding(.vertical, 13)
                                    .frame(maxWidth: .infinity)
                                    .background(hasLocalInstallCert ? .green.opacity(0.2) : .accent.opacity(0.2))
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                    .foregroundStyle(hasLocalInstallCert ? .green : .accent)
                                    .buttonStyle(.plain)
                                }
                                
                                //Text(hasLocalInstallCert ? "Local installation should be working now." : "Required for local installation.")
                                    //.font(.footnote)
                                    //.foregroundStyle(.primary)
                            }
                            .disabled(hasLocalInstallCert)
                        }
                    }
                    .onChange(of: installMethod, perform: { new in
                        if new == 1 && !hasLocalInstallCert {
                            Alertinator.shared.alert(title: "Missing SSL certificates!", body: "Local installation requires HTTPS SSL certificates pointing to localhost (backloop.dev by default). Press the big download button to download the certificate.")
                            installMethod = 0
                            return
                        }
                    })
                    
                    Section(header: HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Certificates")
                    }, content: {
                        if certManager.certificates.isEmpty {
                            AddCertificateCard(certManager: certManager)
                        } else {
                            ForEach(certManager.certificates) { cert in
                                CertificateSelectionCard(certManager: certManager, certificate: cert)
                                    .contextMenu {
                                        Button(action: {
                                            Alertinator.shared.prompt(title: "Rename Certificate", placeholder: cert.name, completion: { newName in
                                                if newName == nil {
                                                    Alertinator.shared.alert(title: "Invalid Name", body: "Please enter a new certificate name.")
                                                } else {
                                                    certManager.renameCertificate(cert: cert, to: newName!)
                                                }
                                            })
                                        }, label: {
                                            Label("Rename", systemImage: "pencil")
                                        })
                                        
                                        Button(action: {
                                            do {
                                                let certURL = cert.url
                                                let passwordData = try Data(contentsOf: certURL.appendingPathComponent("p12_password"))
                                                let p12Pass = String(data: passwordData, encoding: .utf8) ?? ""
                                                
                                                let mpPath = certURL.appendingPathComponent("mp.mobileprovision")
                                                let p12Path = certURL.appendingPathComponent("cert.p12")
                                                
                                                Zsign.checkRevokage(provisionPath: mpPath.path(), p12Path: p12Path.path(), p12Password: p12Pass, completionHandler: { (status, date, _) in
                                                    let formatter = ISO8601DateFormatter()
                                                    let fallbackDate = formatter.date(from: "2001-09-11T01:46:40-07:00")!
                                                    
                                                    let readableFormatter = DateFormatter()
                                                    readableFormatter.dateFormat = "MMMM d, yyyy"
                                                    let expirationDate = readableFormatter.string(from: date ?? fallbackDate)
                                                    
                                                    if status == 1 {
                                                        Alertinator.shared.alert(title: ":(", body: "Your certificate has been revoked or is expired.")
                                                    } else if status == 0 {
                                                        Alertinator.shared.alert(title: ":)", body: "Your certificate is valid! \(cert.name) expires on \(expirationDate).")
                                                    }
                                                })
                                            } catch {
                                                print(error)
                                                Alertinator.shared.alert(title: "Error checking certificate status", body: "An error occurred while checking your certificate status. Please ensure you are connected to the internet and try again later.")
                                                return
                                            }
                                        }, label: {
                                            Label("Check Status", systemImage: "person.text.rectangle")
                                        })
                                    }
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
                    
                    Section(header: HStack {
                        Image(systemName: "ant")
                        Text("Debugging")
                    }, content: {
                        VStack {
                            HStack {
                                AvarkButton(text: "Reset", icon: "trash", foregroundStyle: .red, isDisabled: false, action: {
                                    Alertinator.shared.alert(title: "Reset", body: "Are you sure you'd like to reset AvarkSign? This will remove all certificates and applications.", showCancel: true, action: {
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
                                            
                                            Alertinator.shared.alert(title: "Success!", body: "Successfully cleared all backend data. AvarkSign will close shortly.", action: {
                                                exitApp()
                                            })
                                        } catch {
                                            print(error)
                                            Alertinator.shared.alert(title: "Error!", body: "Failed to clear backend data: \(error.localizedDescription).")
                                        }
                                    })
                                })
                                
                                AvarkButton(text: "View Logs", icon: "apple.terminal", foregroundStyle: .blue, isDisabled: false, action: {
                                    showLogsView = true
                                })
                            }
                            AvarkButton(text: "Instant Gratification", icon: "party.popper", foregroundStyle: .accent, isDisabled: false, action: {
                                Haptic.shared.play(.soft)
                                dropDatConfetti(true)
                            })
                        }
                    })
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: {
                splashIndex = Int.random(in: 0..<splashes.count)
            })
            .sheet(isPresented: $showCertImportSheet, content: {
                ImportCertificateView(certManager: certManager)
            })
            .sheet(isPresented: $showLogsView, content: {
                LogSheetView()
            })
        }
    }
}

#Preview {
    SettingsView()
}
