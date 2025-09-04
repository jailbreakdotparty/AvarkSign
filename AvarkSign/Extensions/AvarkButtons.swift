//
//  AvarkButtons.swift
//  AvarkSign
//
//  Created by Main on 8/29/25.
//

import SwiftUI

struct AvarkButton: View {
    let text: String
    let icon: String
    let foregroundStyle: Color
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: {
                if !isDisabled {
                    action()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .frame(minWidth: 22, minHeight: 22)
                    if text.isEmpty {
                        
                    } else {
                        Text(text)
                    }
                }
            }
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(isDisabled ? .gray.opacity(0.4) : foregroundStyle.opacity(0.2))
            .cornerRadius(14)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14.0))
            .foregroundStyle(isDisabled ? .gray : foregroundStyle)
            .buttonStyle(.plain)
            .opacity(isDisabled ? 0.8 : 1)
        } else {
            Button(action: {
                if !isDisabled {
                    action()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .frame(minWidth: 22, minHeight: 22)
                    if text.isEmpty {
                        
                    } else {
                        Text(text)
                    }
                }
            }
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(isDisabled ? .gray.opacity(0.4) : foregroundStyle.opacity(0.2))
            .cornerRadius(12)
            .foregroundStyle(isDisabled ? .gray : foregroundStyle)
            .buttonStyle(.plain)
            .opacity(isDisabled ? 0.8 : 1)
        }
    }
}

struct AvarkCloseButton: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Image(systemName: "xmark")
        } else {
            Image(systemName: "xmark")
                .frame(width: 28, height: 28)
                .background(Color(.secondarySystemBackground))
                .clipShape(.circle)
        }
    }
}

struct AvarkTextField: View {
    let text: String
    @Binding var fieldData: String
    
    var body: some View {
        SecureField("Certificate Password", text: $fieldData)
            .autocorrectionDisabled(true)
            .textContentType(.password)
            .multilineTextAlignment(.leading)
            .padding()
            .background(Color(.quaternarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
