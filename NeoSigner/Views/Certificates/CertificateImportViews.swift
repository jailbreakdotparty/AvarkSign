//
//  CertificateImportViews.swift
//  NeoSigner
//
//  Created by Skadz on 2/26/25.
//

import SwiftUI

struct AddCertificateCard: View {
    @State private var isImportSheetPresented: Bool = false
    
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
            .sheet(isPresented: $isImportSheetPresented, content: {
                ImportCertificateView()
            })
            .frame(height: 80)
            .background(.quinary)
            .overlay(content: {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.tertiary, style: StrokeStyle(lineWidth: 2, dash: [15, 5]))
            })
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
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                appIconImage
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .cornerRadius(20)
                Text("Coming soon!")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Spacer()
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

#Preview {
    ImportCertificateView()
}
