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

struct ScreenshotImageView: View {
    var url: String
    
    var body: some View {
        LazyImage(url: URL(string: url)) { state in
            if let image = state.image {
                if let imageSource = CGImageSourceCreateWithURL(URL(string: url)! as CFURL, nil) {
                    if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                        let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as! Int
                        let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as! Int
                        if pixelHeight > pixelWidth {
                            image.resizable().scaledToFit().frame(height: 500)
                        } else {
                            image.resizable().scaledToFit().frame(height: 150)
                        }
                    }
                }
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
