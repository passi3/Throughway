//
//  DetailViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class DetailViewModel: BaseViewModel<DetailFeature.State, DetailFeature.Intent> {
    let summary: ActivitySummaryDTO

    private let activityClient: ActivityAPIClient

    init(summary: ActivitySummaryDTO, activityClient: ActivityAPIClient = .live) {
        self.summary = summary
        self.activityClient = activityClient
        super.init(initialState: .init())
    }

    // 상세 조회 전까지 summary 데이터로 fallback
    var title: String { state.detail?.title ?? summary.title }
    var country: String { state.detail?.country ?? summary.country }
    var category: String { state.detail?.category ?? summary.category }
    var thumbnails: [String] { state.detail?.thumbnails ?? summary.thumbnails }
    var tags: [String] { state.detail?.tags ?? summary.tags }
    var price: ActivityPriceDTO { state.detail?.price ?? summary.price }
    var keepCount: Int { state.detail?.keepCount ?? summary.keepCount }
    var isKeep: Bool { state.detail?.isKeep ?? summary.isKeep }
    var pointReward: Int { state.detail?.pointReward ?? summary.pointReward }

    override func send(_ intent: DetailFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchDetail() }

        case .monthSelected(let month):
            reduce { $0.selectedMonth = month }

        case .timeSelected(let time):
            reduce { $0.selectedTime = time }
        }
    }

    private func fetchDetail() async {
        reduce { $0.isLoading = true }
        do {
            let detail = try await activityClient.fetchDetail(summary.activityId)
            reduce { $0.detail = detail }
        } catch {
            print("[Detail] fetchDetail failed: \(error.localizedDescription)")
        }
        reduce { $0.isLoading = false }
    }
}
