//
//  BannerWebView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import WebKit

struct BannerWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        var request = URLRequest(url: url)
        request.setValue(APIConstants.sesacKey, forHTTPHeaderField: "SeSACKey")
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

struct BannerWebViewController: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BannerWebView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("닫기") { dismiss() }
                            .foregroundStyle(Color.textPrimary)
                    }
                }
        }
    }
}
