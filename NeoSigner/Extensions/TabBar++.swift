////
////  TabBar++.swift
////  SSC25
////
////  Created by Skadz on 2/18/25.
////  Adapted from the OpenPicasso TabView, licensed under the MIT License.
////
//
//import Foundation
//import SwiftUI
//
//enum SelectableTab: String, CaseIterable {
//    case browse = "Browse"
//    case library = "Library"
//    case settings = "Settings"
//
//    var icon: String {
//        switch self {
//        case .browse: return "magnifyingglass"
//        case .library: return "square.grid.2x2.fill"
//        case .settings: return "gear"
//        }
//    }
//}
//
//struct TabPreferenceKey: PreferenceKey {
//    static var defaultValue: CGFloat = 0
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//        value = nextValue()
//    }
//}
//
//struct TabBar: View {
//    @Binding var allowedTabs: [SelectableTab]
//    @Binding var selectedTab: SelectableTab
//    @State var tabItemWidth: CGFloat = 0
//    @State var color: Color = .accentColor
//    
//    var body: some View {
//        GeometryReader { proxy in
//            let hasHomeIndicator = proxy.safeAreaInsets.bottom - 88 > 20
//            
//            HStack {
//                ForEach(allowedTabs, id:\.hashValue) { item in
//                    Button {
//                        if UIAccessibility.isReduceMotionEnabled {
//                            withAnimation(.easeInOut(duration: 0.3)) {
//                                selectedTab = item
//                                Haptic.shared.play(.rigid)
//                            }
//                        } else {
//                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                selectedTab = item
//                                Haptic.shared.play(.rigid)
//                            }
//                        }
//                    } label: {
//                        VStack(spacing: 0) {
//                            Image(systemName: item.icon)
//                                .symbolVariant(.fill)
//                                .font(.body.bold())
//                                .frame(width: 45, height: 30)
//                            Text(item.rawValue)
//                                .font(.caption2)
//                                .lineLimit(1)
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    .foregroundStyle(selectedTab == item ? .primary : .secondary)
//                    .blendMode(selectedTab == item ? .overlay : .normal)
//                    .overlay(
//                        GeometryReader { proxy in
//                            Color.clear.preference(key: TabPreferenceKey.self, value: proxy.size.width)
//                        }
//                    )
//                    .onPreferenceChange(TabPreferenceKey.self) { value in
//                        tabItemWidth = value
//                    }
//                }
//            }
//            .padding(.horizontal, 8)
//            .padding(.top, 14)
//            
//            .frame(height: hasHomeIndicator ? 88 : 62, alignment: .top)
//            .background(Material.bar, in: RoundedRectangle(cornerRadius: hasHomeIndicator ? 34 : 0, style: .continuous))
//            .background(
//                HStack {
//                    let idx = (allowedTabs.firstIndex(of: selectedTab) ?? 0)
//                    let left = allowedTabs.count == 0 ? 1 : allowedTabs.distance(from: 0, to: idx)
//                    let right =  allowedTabs.count == 0 ? 1 : allowedTabs.distance(from: idx, to: allowedTabs.count - 1)
//                    
//                    ForEach(Array(0...left).filter { $0 != 0 }, id: \.self) { i in Spacer() }
//                    Circle().fill(color).frame(width: tabItemWidth)
//                    ForEach(Array(0...right).filter { $0 != 0 }, id: \.self) { i in Spacer() }
//                }        .padding(.horizontal, 8)
//            )
//            .overlay(
//                HStack {
//                    let idx = (allowedTabs.firstIndex(of: selectedTab) ?? 0)
//                    let left = allowedTabs.count == 0 ? 1 : allowedTabs.distance(from: 0, to: idx)
//                    let right =  allowedTabs.count == 0 ? 1 : allowedTabs.distance(from: idx, to: allowedTabs.count - 1)
//                    let t_width = allowedTabs.count > 5 ? 16 : (allowedTabs.count > 4 ? 22 : 28)
//                    
//                    
//                    ForEach(Array(0...left).filter { $0 != 0 }, id: \.self) { i in Spacer() }
//                    Rectangle()
//                        .fill(color)
//                        .frame(width: CGFloat(t_width), height: 5)
//                        .cornerRadius(3)
//                        .frame(width: tabItemWidth)
//                        .frame(maxHeight: .infinity, alignment: .top)
//                    ForEach(Array(0...right).filter { $0 != 0 }, id: \.self) { i in Spacer() }
//                }        .padding(.horizontal, 8)
//
//            )
//            .frame(maxHeight: .infinity, alignment: .bottom)
//            .ignoresSafeArea()
//        }
//    }
//}
