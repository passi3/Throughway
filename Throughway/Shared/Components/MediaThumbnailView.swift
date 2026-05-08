//
//  MediaThumbnailView.swift
//  Throughway
//
//  Created by passi on 5/7/26.
//

import SwiftUI
import AVKit
import Kingfisher

/// 서버 상대경로를 받아 이미지/비디오를 자동 분기해 표시하는 공통 썸네일 컴포넌트
struct MediaThumbnailView: View {
    let path: String
    var height: CGFloat = 180
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if path.isVideoPath {
                if let url = path.serverImageURL {
                    LoopingVideoView(url: url)
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                } else {
                    mediaPlaceholder
                }
            } else if let url = path.serverImageURL {
                KFImage(url)
                    .requestModifier(AuthImageModifier())
                    .placeholder { mediaPlaceholder }
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                mediaPlaceholder
            }
        }
    }

    private var mediaPlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray15)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.gray30)
            )
    }
}

/// AVPlayer 기반 무음 루프 재생 비디오 뷰 (컨트롤 없음)
struct LoopingVideoView: View {
    let url: URL
    @State private var player: AVPlayer? = nil

    var body: some View {
        Group {
            if let player {
                LoopingPlayerViewController(player: player)
            } else {
                Color.black
            }
        }
        .task {
            let token = await TokenClient.live.loadAccessToken()
            var headers: [String: String] = ["SeSACKey": APIConstants.sesacKey]
            if let token { headers["Authorization"] = token }

            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            let item = AVPlayerItem(asset: asset)
            let p = AVPlayer(playerItem: item)
            p.isMuted = true
            p.play()

            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak p] _ in
                p?.seek(to: .zero)
                p?.play()
            }

            player = p
        }
    }
}

// MARK: - VideoThumbnailView

/// 비디오 첫 프레임을 정적 이미지로 표시 (인증 헤더 포함, NSCache 캐싱)
struct VideoThumbnailView: View {
    let path: String
    var height: CGFloat = 180
    var cornerRadius: CGFloat = 12

    @State private var thumbnail: UIImage? = nil

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray15)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.gray30)
                    )
            }
        }
        .task(id: path) {
            thumbnail = await VideoThumbnailCache.shared.thumbnail(for: path)
        }
    }
}

private actor VideoThumbnailCache {
    static let shared = VideoThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()

    func thumbnail(for path: String) async -> UIImage? {
        let key = path as NSString
        if let cached = cache.object(forKey: key) { return cached }

        guard let url = path.serverImageURL else { return nil }

        let token = await TokenClient.live.loadAccessToken()
        var headers: [String: String] = ["SeSACKey": APIConstants.sesacKey]
        if let token { headers["Authorization"] = token }

        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 320, height: 320)

        do {
            let (image, _) = try await generator.image(at: .zero)
            let uiImage = UIImage(cgImage: image)
            cache.setObject(uiImage, forKey: key)
            return uiImage
        } catch {
            return nil
        }
    }
}

// MARK: - LoopingPlayerViewController

private struct LoopingPlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
