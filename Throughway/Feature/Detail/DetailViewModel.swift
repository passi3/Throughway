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

    var rating: Double? { state.detail?.rating }
    var reviewCount: Int? { state.detail?.reviewCount }
    var restrictions: ActivityRestrictionsDTO? { state.detail?.restrictions }

    var discountPercent: Int? {
        let orig = price.original, fin = price.final
        guard orig > 0, fin < orig else { return nil }
        return Int(round(Double(orig - fin) / Double(orig) * 100))
    }

    var availableDates: [Date] {
        guard let startRaw = state.detail?.startDate,
              let endRaw   = state.detail?.endDate else { return [] }
        guard let start = AppFormatter.serverDate.date(from: startRaw),
              let end   = AppFormatter.serverDate.date(from: endRaw),
              start <= end else { return [] }
        var dates: [Date] = []
        var cur = start
        let cal = Calendar.current
        while cur <= end {
            dates.append(cur)
            cur = cal.date(byAdding: .day, value: 1, to: cur)!
        }
        return dates
    }

    override func send(_ intent: DetailFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchDetail() }

        case .dateSelected(let index):
            reduce { $0.selectedDateIndex = index }

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
