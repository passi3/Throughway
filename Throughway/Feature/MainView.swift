//
//  MainView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI

struct MainView: View {
    let onLogout: () -> Void
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("홈", image: selectedTab == 0 ? "icon_tab_home_fill" : "icon_tab_home")
                }
                .tag(0)

            ActivityView()
                .tabItem {
                    Label("검색", image: selectedTab == 1 ? "icon_tab_search_fill" : "icon_tab_search")
                }
                .tag(1)

            ChatListView()
                .tabItem {
                    Label("채팅", image: selectedTab == 2 ? "icon_tab_chat_heart_fill" : "icon_tab_chat_heart")
                }
                .tag(2)

            ProfileView(onLogout: onLogout)
                .tabItem {
                    Label("프로필", image: selectedTab == 3 ? "icon_tab_person_fill" : "icon_tab_person")
                }
                .tag(3)
        }
        .tint(Color.blackSeafoam)
    }
}
