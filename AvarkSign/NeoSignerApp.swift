//
//  NeoSignerApp.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI
import WelcomeSheet

private var welcomeSheetPages = [
    WelcomeSheetPage(title: "Welcome to AvarkSign", rows: [
        WelcomeSheetPageRow(imageSystemName: "magnifyingglass",
                            title: "Browse Any Repo",
                            content: "Import your own IPAs or search through any AltStore source. (ESign and other formats coming soon.)"),
        
        WelcomeSheetPageRow(imageSystemName: "bolt.fill",
                            title: "Quick Signing",
                            content: "Powered by the open-source zsign library, apps are signed with lightning-fast speed."),
        
        WelcomeSheetPageRow(imageSystemName: "heart.fill",
                            title: "Free and Open-Source",
                            content: "AvarkSign is free and open-source software and collects zero user data. All source code is available on our GitHub for the community to improve and adapt.")
    ])
]

var weOnADebugBuild: Bool = false
var fileManager = FileManager.default

@main
struct NeoSignerApp: App {
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    @State private var showWelcomeSheet: Bool = false
    
    // Fix file picker (brought to you by Nugget-Mobile)
    init() {
        if let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, Selector(("fix_initForOpeningContentTypes:asCopy:"))), let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:))) {
            method_exchangeImplementations(origMethod, fixMethod)
        }
        
        #if DEBUG
        weOnADebugBuild = true
        #else
        weOnADebugBuild = false
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .welcomeSheet(isPresented: $showWelcomeSheet, preferredColorScheme: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light, pages: welcomeSheetPages)
                .onAppear(perform: {
                    if weOnADebugBuild { print("We're on a Debug build!") }
                    if isFirstLaunch {
                        showWelcomeSheet = true
                    } else {
                        showWelcomeSheet = false
                    }
                    isFirstLaunch = false
                })
        }
    }
}

extension String: Error {}
