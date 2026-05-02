//
//  DetailView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI

struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    @Environment(\.dismiss) private var dismiss

    private let months = ["5월 가을", "1일 동수", "2사 1일"]
    private let times = ["8:00", "8:30", "9:00", "9:30", "10:00", "10:30", "1:00", "1:30", "2:00", "2:30"]

    init(activity: ActivitySummaryDTO) {
        _viewModel = StateObject(wrappedValue: DetailViewModel(summary: activity))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImage

                VStack(alignment: .leading, spacing: 20) {
                    titleSection
                    infoSection
                    divider
                    if let desc = viewModel.state.detail?.description, !desc.isEmpty {
                        descriptionSection(desc)
                        divider
                    }
                    if let schedule = viewModel.state.detail?.schedule {
                        scheduleSection(schedule)
                        divider
                    }
                    priceSection
                    divider
                    dateSection
                    divider
                    timeSection
                }
                .padding(16)

                Spacer().frame(height: 80)
            }
        }
        .background(Color.gray0)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) { navigationBar }
        .overlay(alignment: .bottom) { bottomBar }
        .navigationBarHidden(true)
        .task { viewModel.send(.onAppear) }
    }
}

// MARK: - Sections

private extension DetailView {

    var navigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Circle()
                    .fill(.white.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .overlay(
                        AppIcon.back
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Color.gray90)
                    )
            }
            Spacer()
            Button {} label: {
                Circle()
                    .fill(.white.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: viewModel.isKeep ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(viewModel.isKeep ? Color.rosyPunch : Color.gray90)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
    }

    var heroImage: some View {
        ZStack {
            if let thumbnail = viewModel.thumbnails.first, let url = URL(string: thumbnail) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    heroPlaceholder
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()
            } else {
                heroPlaceholder
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if viewModel.thumbnails.count > 1 {
                        VStack(spacing: 8) {
                            ForEach(viewModel.thumbnails.prefix(4), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray30)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.gray0)
                                    )
                            }
                        }
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }

    var heroPlaceholder: some View {
        Rectangle()
            .fill(Color.gray15)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.gray30)
            )
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.title)
                .font(.Pretendard.title1)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray90)

            HStack(spacing: 6) {
                Text(viewModel.category)
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray60)

                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.rosyPunch)

                Text("\(viewModel.keepCount)개")
                    .font(.Pretendard.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)
            }

            if !viewModel.tags.isEmpty {
                Text(viewModel.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(.Pretendard.body3)
                    .foregroundStyle(Color.gray60)
                    .lineSpacing(4)
            }
        }
    }

    var infoSection: some View {
        HStack(spacing: 0) {
            infoItem(icon: "mappin.circle", title: "국가", value: viewModel.country)
            Divider().frame(height: 40)
            infoItem(icon: "tag", title: "카테고리", value: viewModel.category)
            Divider().frame(height: 40)
            infoItem(icon: "dollarsign.circle", title: "포인트", value: "\(viewModel.pointReward)P")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray15, lineWidth: 1)
        )
    }

    func infoItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.blackSeafoam)
            Text(title)
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.gray45)
            Text(value)
                .font(.Pretendard.caption1)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("액티비티 소개")
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
            Text(text)
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray75)
                .lineSpacing(4)
        }
    }

    func scheduleSection(_ schedule: ActivityScheduleDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("일정 정보")
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)

            VStack(alignment: .leading, spacing: 8) {
                if let min = schedule.minParticipants, let max = schedule.maxParticipants {
                    scheduleRow(icon: "person.2", label: "참여 인원", value: "\(min) ~ \(max)명")
                }
                if let km = schedule.durationKm {
                    scheduleRow(icon: "figure.walk", label: "이동 거리", value: String(format: "%.1f km", km))
                }
            }
        }
    }

    func scheduleRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.blackSeafoam)
                .frame(width: 20)
            Text(label)
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray60)
            Spacer()
            Text(value)
                .font(.Pretendard.body3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
        }
    }

    var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("판매가")
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray45)

            HStack(alignment: .bottom, spacing: 8) {
                Text(viewModel.price.final.wonFormatted)
                    .font(.Pretendard.body1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)

                if viewModel.price.original > viewModel.price.final {
                    Text(viewModel.price.original.wonFormatted)
                        .font(.Pretendard.body3)
                        .foregroundStyle(Color.gray45)
                        .strikethrough()
                }
            }
        }
    }

    var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("날짜 선택")
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)

            HStack(spacing: 8) {
                ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                    Button {
                        viewModel.send(.monthSelected(index))
                    } label: {
                        Text(month)
                            .font(.Pretendard.caption1)
                            .fontWeight(viewModel.state.selectedMonth == index ? .semibold : .regular)
                            .foregroundStyle(viewModel.state.selectedMonth == index ? Color.gray0 : Color.gray60)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.state.selectedMonth == index ? Color.blackSeafoam : Color.gray15)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("시간 선택")
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(times, id: \.self) { time in
                    Button {
                        viewModel.send(.timeSelected(time))
                    } label: {
                        Text(time)
                            .font(.Pretendard.caption1)
                            .fontWeight(viewModel.state.selectedTime == time ? .semibold : .regular)
                            .foregroundStyle(viewModel.state.selectedTime == time ? Color.gray0 : Color.gray60)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(viewModel.state.selectedTime == time ? Color.blackSeafoam : Color.gray15)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Color.gray15)
            .frame(height: 1)
    }

    var bottomBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("판매가")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray45)
                Text(viewModel.price.final.wonFormatted)
                    .font(.Pretendard.body2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)
            }

            Button {
            } label: {
                Text("결제하기")
                    .font(.Pretendard.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.blackSeafoam)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray15)
                .frame(height: 1)
        }
    }
}

private extension Int {
    var wonFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: self)) ?? "\(self)") + "원"
    }
}
