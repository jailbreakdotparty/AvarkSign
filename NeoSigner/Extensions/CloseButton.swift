// bomberfish
// CloseButton.swift – Picasso
// created on 2023-12-14

//  Skidded from the OpenPicasso TabView, licensed under the MIT License.

import SwiftUI

struct CloseButton: View {
    @Environment(\.colorScheme) var cs
    var body: some View {
        Circle()
            .fill(cs == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color(UIColor.systemGray).opacity(0.8))
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(cs == .dark ? Color(UIColor.label) : Color(UIColor.systemBackground))
            )
    }
}
