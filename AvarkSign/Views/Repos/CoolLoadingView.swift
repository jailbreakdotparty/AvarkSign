//
//  CoolLoadingView.swift
//  poc19
//
//  Created by Skadz on 12/25/24.
//

import SwiftUI

//struct CoolLoadingView: View {
//    @ObservedObject var downloadManager: DownloadManager
//    @State private var showText: Bool = true
//    @State private var isSpinning: Bool = false
//    @State private var rotationDegrees: Double = 0
//    @Environment(\.dismiss) var dismiss
//    
//    var appName: String
//    var onDownloadComplete: ((URL) throws -> Void)?
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                ZStack {
//                    LinearGradient(gradient: Gradient(colors: [
//                        .accentColor.opacity(0.25),
//                        .accentColor.opacity(0.05)
//                    ]), startPoint: .top, endPoint: .bottom)
//                    .ignoresSafeArea(.all)
//                    
//                    ZStack {
//                        Text("\(Int(downloadManager.downloadProgress * 100))%")
//                            .contentTransition(.numericText())
//                            .font(.system(size: 85, design: .rounded))
//                            .opacity(isSpinning ? 0 : 1)
//                        
//                        Circle()
//                            .fill(RadialGradient(gradient: Gradient(colors: [.accentColor.opacity(0.6), Color.clear]), center: .center, startRadius: 50, endRadius: 200))
//                            .blur(radius: 50)
//                            .frame(width: 150, height: 150)
//                            .blendMode(.screen)
//                        
//                        if isSpinning {
//                            Circle()
//                                .trim(from: 0, to: 0.7)
//                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
//                                .frame(width: 300)
//                                .rotationEffect(.degrees(rotationDegrees))
//                                .onAppear {
//                                    withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
//                                        rotationDegrees = 360
//                                    }
//                                }
//                        } else {
//                            Circle()
//                                .stroke(Color.accentColor, lineWidth: 18)
//                                .opacity(0.5)
//                                .frame(width: 300)
//                        }
//                    }
//                    
//                    VStack {
//                        if showText {
//                            Text(getTitle())
//                                .font(.system(size: 28, weight: .semibold, design: .rounded))
//                                .animation(.easeInOut, value: downloadManager.downloadState)
//                            
//                            Text(getStatus())
//                                .font(.system(size: 16, weight: .regular, design: .rounded))
//                                .animation(.easeInOut, value: downloadManager.downloadStatusText)
//                        }
//                    }
//                    .multilineTextAlignment(.center)
//                    .frame(maxHeight: .infinity, alignment: .bottom)
//                    .padding(.bottom, 120)
//                }
//                .ignoresSafeArea(.all, edges: .top)
//                .buttonStyle(.plain)
//                .navigationTitle("\(getTitle()) \(appName)...")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing, content: {
//                        Button(action: {
//                            if case .downloading = downloadManager.downloadState {
//                                downloadManager.cancelAllDownloads()
//                            }
//                            dismiss()
//                        }, label: {
//                            Image(systemName: "xmark.circle.fill")
//                                .foregroundColor(.gray)
//                                .imageScale(.large)
//                        })
//                    })
//                }
//                .background(Color.black)
//            }
//            .onChange(of: downloadManager.downloadState) { newState in
//                if case .finished = newState {
//                    withAnimation {
//                        isSpinning = true
//                    }
//                }
//            }
//        }
//    }
//    
//    private func getTitle() -> String {
//        switch downloadManager.downloadState {
//        case .notStarted:
//            return "Preparing"
//        case .downloading:
//            return "Downloading"
//        case .finished:
//            return isSpinning ? "Installing" : "Processing"
//        case .failed:
//            return "Failed"
//        }
//    }
//    
//    private func getStatus() -> String {
//        switch downloadManager.downloadState {
//        case .notStarted:
//            return "Preparing to download \(appName)..."
//        case .downloading:
//            return downloadManager.downloadStatusText.isEmpty ?
//            "Downloading \(appName)..." : downloadManager.downloadStatusText
//        case .finished:
//            return isSpinning ? "Installing \(appName)..." : "Processing \(appName)..."
//        case .failed(let error):
//            return "Error: \(error.localizedDescription)"
//        }
//    }
//}
