//
//  URLImageView.swift
//  NeoSigner
//
//  Created by Skadz on 2/25/25.
//

import SwiftUI
import NukeUI

struct URLImageView: View {
    var url: String
    
    var body: some View {
        LazyImage(url: URL(string: url)) { state in
            if let image = state.image {
                image.resizable()
            } else if state.error != nil {
                MissingIconView()
            } else {
                ProgressView()
            }
        }
    }
}

struct MissingIconView: View {
    var body: some View {
        ZStack {
            Color(UIColor.tertiarySystemFill)
            
            Image(systemName: "questionmark.app")
                .font(.largeTitle)
                .padding(2)
                .foregroundStyle(.red)
        }
    }
}
