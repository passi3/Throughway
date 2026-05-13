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
/// - paths + initialIndex 를 넘기면 전체화면에서 갤러리 순회 가능
struct MediaThumbnailView: View {
    let path: String
    var height: CGFloat = 180
    var cornerRadius: CGFloat = 12
    /// 갤러리 전체 경로 목록 (없으면 path 단독 표시)
    var paths: [String] = []
    /// 이 썸네일이 갤러리에서 몇 번째인지
    var initialIndex: Int = 0
    /// false 이면 탭/풀스크린 비활성 (피드 카드처럼 부모가 탭을 처리하는 경우)
    var allowsFullscreen: Bool = true

    @State private var isFullscreen = false

    private var galleryPaths: [String] { paths.isEmpty ? [path] : paths }
    private var galleryIndex: Int  { paths.isEmpty ? 0 : initialIndex }

    var body: some View {
        Group {
            if path.isVideoPath {
                if let url = path.serverImageURL {
                    ControlledVideoView(
                        url: url,
                        height: height,
                        cornerRadius: cornerRadius,
                        allowsFullscreen: allowsFullscreen
                    ) {
                        isFullscreen = true
                    }
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
                    .onTapGesture { if allowsFullscreen { isFullscreen = true } }
            } else {
                mediaPlaceholder
            }
        }
        .fullScreenCover(isPresented: $isFullscreen) {
            FullscreenGalleryView(paths: galleryPaths, initialIndex: galleryIndex)
        }
    }

    private var mediaPlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.bgTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.textTertiary)
            )
    }
}

// MARK: - ControlledVideoView

private struct ControlledVideoView: View {
    let url: URL
    let height: CGFloat
    let cornerRadius: CGFloat
    var allowsFullscreen: Bool = true
    let onFullscreen: () -> Void

    @State private var player: AVPlayer? = nil
    @State private var isPlaying = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var showControls = false
    @State private var isSeeking = false
    @State private var timeObserver: Any? = nil
    @State private var hideTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let player {
                    LoopingPlayerViewController(player: player, showsControls: false)
                } else {
                    Color.black
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showControls)
        .contentShape(Rectangle())
        .onTapGesture { toggleControls() }
        .task { await setupPlayer() }
        .onDisappear { teardown() }
    }

    // MARK: Controls Overlay

    private var controlsOverlay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 32) {
                if allowsFullscreen {
                    Button { onFullscreen() } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                Button { seek(by: -10) } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }

                Button { togglePlayback() } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }

                Button { seek(by: 10) } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: "speaker.slash.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 8) {
                Text(timeString(currentTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)

                Slider(
                    value: Binding(
                        get: { currentTime },
                        set: { newValue in
                            currentTime = newValue
                            isSeeking = true
                            player?.seek(to: CMTime(seconds: newValue, preferredTimescale: 600)) { _ in
                                isSeeking = false
                            }
                            scheduleHide()
                        }
                    ),
                    in: 0...max(duration, 1)
                )
                .tint(.white)

                Text(timeString(duration))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: 0
                )
            )
        )
    }

    // MARK: Actions

    private func toggleControls() {
        if showControls {
            hideTask?.cancel()
            showControls = false
        } else {
            showControls = true
            scheduleHide()
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { showControls = false }
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        scheduleHide()
    }

    private func seek(by seconds: Double) {
        guard let player else { return }
        let target = max(0, min(currentTime + seconds, duration))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
        scheduleHide()
    }

    private func setupPlayer() async {
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

        if let cmDuration = try? await asset.load(.duration), cmDuration.isNumeric {
            duration = cmDuration.seconds
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        let observer = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak p] time in
            guard !isSeeking else { return }
            currentTime = time.seconds
            if let p { isPlaying = p.timeControlStatus == .playing }
        }
        timeObserver = observer
        player = p
    }

    private func teardown() {
        hideTask?.cancel()
        if let player, let timeObserver { player.removeTimeObserver(timeObserver) }
        player?.pause()
        player = nil
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - FullscreenGalleryView

private struct FullscreenGalleryView: View {
    let paths: [String]
    let initialIndex: Int

    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(paths: [String], initialIndex: Int) {
        self.paths = paths
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(paths.indices, id: \.self) { index in
                    Group {
                        if paths[index].isVideoPath {
                            FullscreenVideoView(path: paths[index])
                        } else {
                            FullscreenImageView(path: paths[index])
                        }
                    }
                    .tag(index)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // 상단 바
            VStack {
                HStack {
                    if paths.count > 1 {
                        Text("\(currentIndex + 1) / \(paths.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.4))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                Spacer()

                // 하단 점 인디케이터
                if paths.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(paths.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.top, 56)
        }
    }
}

// MARK: - Fullscreen Image

private struct FullscreenImageView: View {
    let path: String

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        if let url = path.serverImageURL {
            KFImage(url)
                .requestModifier(AuthImageModifier())
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in scale = lastScale * value }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1 { withAnimation { scale = 1; lastScale = 1 } }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation { scale = 1; lastScale = 1 }
                }
        }
    }
}

// MARK: - Fullscreen Video

private struct FullscreenVideoView: View {
    let path: String
    @State private var player: AVPlayer? = nil

    var body: some View {
        Group {
            if let player {
                LoopingPlayerViewController(player: player, showsControls: true)
                    .ignoresSafeArea()
            } else {
                Color.black
            }
        }
        .task { await setupPlayer() }
        .onDisappear { player?.pause(); player = nil }
    }

    private func setupPlayer() async {
        guard let url = path.serverImageURL else { return }
        let token = await TokenClient.live.loadAccessToken()
        var headers: [String: String] = ["SeSACKey": APIConstants.sesacKey]
        if let token { headers["Authorization"] = token }

        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let p = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        p.play()
        player = p
    }
}

// MARK: - LoopingPlayerViewController

private struct LoopingPlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer
    var showsControls: Bool = false

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = showsControls
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.showsPlaybackControls = showsControls
    }
}

// MARK: - LoopingVideoView (하위 호환)

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
                    .fill(Color.bgTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.textTertiary)
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
