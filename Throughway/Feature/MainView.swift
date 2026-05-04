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
    @State private var banner: ChatBannerInfo? = nil
    @State private var bannerTask: Task<Void, Never>? = nil
    @State private var deepLinkRoomId: String? = nil
    @Environment(\.scenePhase) private var scenePhase

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

            ChatListView(deepLinkRoomId: $deepLinkRoomId)
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
        .overlay(alignment: .top) {
            if let info = banner {
                ChatBannerView(info: info) {
                    dismissBanner()
                    selectedTab = 2
                    deepLinkRoomId = info.roomId
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
        }
        .animation(.spring(duration: 0.35), value: banner != nil)
        .onReceive(NotificationCenter.default.publisher(for: .chatRoomDeepLink)) { notif in
            selectedTab = 2
            deepLinkRoomId = notif.object as? String
        }
        .onAppear {
            consumePendingDeepLink()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            consumePendingDeepLink()
        }
        .onReceive(NotificationCenter.default.publisher(for: .inAppChatBanner)) { notif in
            guard let info = notif.userInfo,
                  let title  = info["title"]  as? String,
                  let body   = info["body"]   as? String,
                  let roomId = info["roomId"] as? String else { return }
            showBanner(.init(title: title, body: body, roomId: roomId))
        }
    }

    private func consumePendingDeepLink() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate,
              let roomId = delegate.pendingDeepLinkRoomId else { return }
        delegate.pendingDeepLinkRoomId = nil
        selectedTab = 2
        deepLinkRoomId = roomId
    }

    private func showBanner(_ info: ChatBannerInfo) {
        bannerTask?.cancel()
        banner = info
        bannerTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run { dismissBanner() }
        }
    }

    private func dismissBanner() {
        bannerTask?.cancel()
        bannerTask = nil
        withAnimation { banner = nil }
    }
}

// MARK: - Banner Model

private struct ChatBannerInfo {
    let title: String
    let body: String
    let roomId: String
}

// MARK: - Banner View

private struct ChatBannerView: View {
    let info: ChatBannerInfo
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.blackSeafoam)
                    .frame(width: 36, height: 36)
                    .background(Color.blackSeafoam.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title)
                        .font(.Pretendard.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                        .lineLimit(1)
                    Text(info.body)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
