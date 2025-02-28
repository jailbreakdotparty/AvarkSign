//
//  LibraryView.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI

struct LibraryView: View {
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
            .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryView()
}
