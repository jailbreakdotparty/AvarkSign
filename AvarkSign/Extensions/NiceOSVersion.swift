//
//  NiceOSVersion.swift
//  AvarkSign
//
//  Created by lunginspector on 8/27/25.
//

import UIKit
import SwiftUI

func niceOSVersion() -> Double {
    let systemVersionString = UIDevice.current.systemVersion
    let systemVersionDouble = systemVersionString.split(separator: ".").prefix(2).joined(separator: ".")
    
    return Double(systemVersionDouble) ?? 0.0
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
