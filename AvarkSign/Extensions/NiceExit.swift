//
//  NiceExit.swift
//  NeoSigner
//
//  Created by Skadz on 3/5/25.
//  Skidded from OpenPicasso, licensed under the MIT License.
//

import Foundation
import UIKit

public func exitApp() {
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        exit(0)
    }
}
