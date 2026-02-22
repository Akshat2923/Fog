//
//  ContentView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/21/26.
//

import SwiftUI

struct FogTabs: View {
    @SceneStorage("selectedTab") var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Canvas", systemImage: "pencil", value: 0) {
                Text("Canvas")
            }
            
            Tab("Clusters", systemImage: "bubbles.and.sparkles.fill", value: 1) {
                Text("Clusters")
            }
            if selectedTab == 1 {
                Tab("Search", systemImage: "magnifyingglass", value: 2, role: .search) {
                    Text("Search")
                }
                
            }
            
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    FogTabs()
}
