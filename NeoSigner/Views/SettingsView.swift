//
//  SettingsView.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("installMethod") private var installMethod: Int = 1 // 0 = Remote, 1 = Local
    @AppStorage("hasLocalInstallCert") private var hasLocalInstallCert: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Text("NeoSigner")
                                    .font(.system(size: 50, weight: .medium))
                                    .lineLimit(1)
                                Text("Made by Skadz")
                                    .font(.system(size: 20, weight: .regular))
                                    .lineLimit(1)
                                Text("\nSpecial thanks to:\nzhlynn    loyahdev    neoarz\nLrdsnow   lunginspector   bebebole")
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
                                    try await Sideloading.shared.updateLocalInstallCertificate(hasCert: hasLocalInstallCert)
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
                        AddCertificateCard()
                    })
                    
                    Section(header: Text("Debug"), content: {
                        NavigationLink(destination: CoolLoadingView()) {
                            VStack(alignment: .leading) {
                                Text("Open cool loading view")
                                Text("(the animations are fucked rn)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    })
                    
                    Section(header: Text("Socials"), content: {
                        Text("[Join our Discord!](https://discord.gg/neosign)")
                        Text("[View the GitHub!](https://github.com/NeoSigniOS/NeoSigner)")
                    })
                    
                    Section(footer: Text("NeoSigner Public Alpha v0.0.6\n[\"It actually signs!\"](https://www.idownloadblog.com/2024/12/29/mysign/)"), content: {})
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
