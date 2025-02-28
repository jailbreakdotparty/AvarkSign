//
//  CoolLoadingView.swift
//  poc19
//
//  Created by Skadz on 12/25/24.
//

import SwiftUI

struct CoolLoadingView: View {
    @State var progress: Double = 0.0
    @State var appName: String = "CatalogHelper (v2)"
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = "Signing"
    @State private var status: String = "Extracting IPA..."
    @State private var showText: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [
                        .accentColor.opacity(0.25),
                        .accentColor.opacity(0.05)
                    ]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(.all)
                    
                    ZStack {
                        Text("\(Int(progress * 100))%")
                            .contentTransition(.numericText())
                            .font(.system(size: 85, design: .rounded))
                        Circle()
                            .fill(RadialGradient(gradient: Gradient(colors: [.accentColor.opacity(0.6), Color.clear]), center: .center, startRadius: 50, endRadius: 200))
                            .blur(radius: 50)
                            .frame(width: 150, height: 150)
                            .blendMode(.screen)
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 18)
                            .opacity(0.5)
                            .frame(width: 300)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .frame(width: 300)
                            .rotationEffect(.degrees(-90))
                            .animation(.smooth, value: progress)
                    }
                    
                    VStack {
                        if showText {
                            Text(title)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                            Text(status)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 120)
                    .onAppear {
                        cycleSteps()
                    }
                }
                .ignoresSafeArea(.all, edges: .top)
                .buttonStyle(.plain)
                .navigationTitle("Installing \(appName)...")
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
    
    func cycleSteps() {
        let steps: [(title: String, status: String)] = [
            ("Success!", "Successfully installed \(appName)!"),
            ("Downloading", "Downloading \(appName)..."),
            ("Extracting", "Extracting IPA..."),
            ("Signing", "Calling zsign..."),
            ("Packaging", "Compressing IPA..."),
            ("Preparing", "Starting Vapor server..."),
            ("Installing", "Opening install manifest...")
        ]

        var index = 0

        func nextStep() {
            let duration = Double.random(in: 1.6...4.2)
            let startProgress = progress
            let targetProgress = Double(index + 1) / Double(steps.count)

            withAnimation(.easeInOut(duration: 0.65)) {
                showText = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                index = (index + 1) % steps.count
                title = steps[index].title
                status = steps[index].status
                
                showText = true
                
                Task {
                    let startTime = Date.now
                    while Date.now.timeIntervalSince(startTime) < duration {
                        let elapsedTime = Date.now.timeIntervalSince(startTime)
                        let progressFraction = elapsedTime / duration
                        await MainActor.run {
                            progress = startProgress + (targetProgress - startProgress) * progressFraction
                        }
                        try? await Task.sleep(nanoseconds: 16_000_000)
                    }
                    await MainActor.run {
                        progress = targetProgress
                        if index == 0 {
                            progress = 0
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    nextStep()
                }
            }
        }

        nextStep()
    }

}

#Preview {
    CoolLoadingView()
}
