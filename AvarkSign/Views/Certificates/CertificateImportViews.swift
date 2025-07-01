//
//  CertificateImportViews.swift
//  NeoSigner
//
//  Created by Skadz on 2/26/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddCertificateCard: View {
    @State private var isImportSheetPresented: Bool = false
    @ObservedObject var certManager: CertificateManager

    var body: some View {
        Button(action: {
            isImportSheetPresented = true
        }) {
            HStack {
                Spacer()
                Image(systemName: "plus")
                    .foregroundStyle(.accent)
                    .imageScale(.large)
                Spacer()
            }
            .frame(height: 80)
            .overlay(content: {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.tertiary, style: StrokeStyle(lineWidth: 4, dash: [15, 5]))
            })
            .background(.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .sheet(isPresented: $isImportSheetPresented, content: {
            ImportCertificateView(certManager: certManager)
        })
    }
}

struct CertificatePreviewCard: View {
    @StateObject private var certManager = CertificateManager()
    
    var mobileProvisionURL: URL?
    var showDetails: Bool
    var allowSelection: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "signature")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)
            
            VStack(alignment: .leading) {
                Text(certManager.parseTeamName(from: mobileProvisionURL!))
                    .font(.headline)
                    .lineLimit(1)
                Text("Expires on \(certManager.parseExpirationDate(url: mobileProvisionURL!))")
                    .font(.subheadline)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
        }
        
        if showDetails {
            HStack {
                Text("Team ID")
                Spacer()
                CredentialTextView(text: certManager.parseTeamID(from: mobileProvisionURL!))
            }
        }
    }
}

struct CertificateSelectionCard: View {
    @ObservedObject var certManager: CertificateManager
    var certificate: Certificate
    @State private var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "signature")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)
            
            VStack(alignment: .leading) {
                Text(certificate.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("Expires on \(certManager.parseExpirationDate(url: certificate.url.appendingPathComponent("mp.mobileprovision")))")
                    .font(.subheadline)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            
            Image(systemName: certManager.activeCertificate == certificate ? "checkmark.circle.fill" : "circle")
                .imageScale(.large)
                .tint(.primary)
                .padding(12)
        }
        .onTapGesture {
            certManager.selectCertificate(certificate)
            isSelected.toggle()
        }
    }
}

struct FileImportCard: View {
    var name: String
    var fileExtension: String
    
    @Binding var isPresented: Bool
    @Binding var isImported: Bool
    @Binding var selectedFileURL: URL?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            HStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(".\(fileExtension)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        Text(LocalizedStringKey("*\(isImported ? "\(selectedFileURL!.lastPathComponent), \(fileSize(at: selectedFileURL!))" : "Required")*"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 0.45)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    Spacer()
                    
                    if isImported {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                            .tint(.primary)
                            .padding(12)
                    } else {
                        Image(systemName: "circle")
                            .imageScale(.large)
                            .tint(.primary)
                            .padding(12)
                    }
                }
                .tint(.primary)
            }
            .frame(width: 340, height: 80)
            .background(Color(UIColor.quaternarySystemFill)).cornerRadius(10)
        }
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [UTType(filenameExtension: fileExtension)!]
        ) { result in
            switch result {
            case .success(let file):
                isImported = true
                selectedFileURL = file.absoluteURL
            case .failure(let error):
                print(error.localizedDescription)
                Alertinator.shared.alert(title: "Error importing file!", body: "Failed to import: \(error.localizedDescription)")
            }
        }
    }
}

struct ImportCertificateView: View {
    @State private var isMobileProvisionFilePickerPresented: Bool = false
    @State private var mobileProvisionImported: Bool = false
    @State private var selectedMobileProvisionURL: URL?
    
    @State private var isP12FilePickerPresented: Bool = false
    @State private var p12Imported: Bool = false
    @State private var selectedP12URL: URL?
    @State private var p12PasswordInput: String = ""
    
    @FocusState private var keyboardFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var certManager: CertificateManager
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("Files"), content: {
                        FileImportCard(name: "Provisioning File", fileExtension: "mobileprovision", isPresented: $isMobileProvisionFilePickerPresented, isImported: $mobileProvisionImported, selectedFileURL: $selectedMobileProvisionURL)
                            .frame(maxWidth: .infinity)
                        
                        VStack {
                            FileImportCard(name: "Signing Certificate", fileExtension: "p12", isPresented: $isP12FilePickerPresented, isImported: $p12Imported, selectedFileURL: $selectedP12URL)
                                .frame(maxWidth: .infinity)
                            SecureField("Enter Certificate Password", text: $p12PasswordInput)
                                .modifier(fancyInputViewModifier())
                                .autocorrectionDisabled(true)
                                .textContentType(.password)
                                .padding(.top, 2)
                                .multilineTextAlignment(.center)
                                .focused($keyboardFocused)
                        }
                    })
                    
                    if selectedMobileProvisionURL != nil {
                        Section(header: Text("Details"), content: {
                            CertificatePreviewCard(mobileProvisionURL: selectedMobileProvisionURL!, showDetails: true, allowSelection: false)
                        })
                    }
                    
                    Section {
                        Button(action: {
                            do {
                                Haptic.shared.play(.light)
                                _ = try certManager.addCertificate(mpURL: selectedMobileProvisionURL!, p12URL: selectedP12URL!, p12Pass: p12PasswordInput)
                                certManager.activeCertificate = certManager.certificates.last!
                                dropDatConfetti()
                                dismiss()
                            } catch {
                                Alertinator.shared.alert(title: "Error adding certificate!", body: "An error occurred while adding the certificate: \(error.localizedDescription)")
                                return
                            }
                        }) {
                            Text("Add certificate")
                                .font(.system(size: 22, weight: .medium))
                                .padding(6)
                                .foregroundStyle(Color(UIColor.systemBackground))
                                .background((selectedMobileProvisionURL == nil || selectedP12URL == nil || p12PasswordInput.isEmpty) ? Color(UIColor.secondarySystemFill) : .accent).cornerRadius(8)
                        }
                        .disabled(selectedMobileProvisionURL == nil || selectedP12URL == nil || p12PasswordInput.isEmpty)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Add a certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        dismiss()
                    }, label: {
                        CloseButton()
                    })
                })
            }
        }
    }
}

struct CredentialTextView: View {
    var text: String
    @State private var hide: Bool = true
    
    var body: some View {
        Text(hide ? String(repeating: "•", count: text.count) : text)
            .padding(4)
            .font(.system(size: 16, design: .monospaced))
            .foregroundStyle(.tertiary)
            .background(.quaternary)
            .cornerRadius(8)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    Haptic.shared.play(.soft)
                    hide.toggle()
                }
            }
            .contextMenu {
                if !hide {
                    Button(action: {
                        UIPasteboard.general.string = text
                    }) {
                        Label("Copy to clipboard", systemImage: "doc.on.doc")
                    }
                }
            }
    }
}
