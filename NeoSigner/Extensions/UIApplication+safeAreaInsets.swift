// bomberfish
// UIApplication+safeAreaInsets.swift – Picasso
// created on 2023-12-30

//  this is from OpenPicasso, which is licensed under the MIT license.
//  all credits go to the Picasso Team
//  i'm just lazy and this code works well :skull:      - Skadz

import UIKit

extension UIApplication {
    static var safeAreaInsets: UIEdgeInsets  {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets ?? .zero
    }
}
