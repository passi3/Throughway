//
//  DetailView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher
import MapKit

struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    
    init(activity: ActivitySummaryDTO) {
        _viewModel = StateObject(wrappedValue: DetailViewModel(summary: activity))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImage
                
                VStack(alignment: .leading, spacing: 20) {
                    titleSection
                    divider
                    infoSection
                    divider
                    priceSection
                    if !viewModel.schedule.isEmpty {
                        divider
                        scheduleSection
                    }
                    divider
                    Text("엑티비티 예약설정")
                        .font(.Pretendard.body1)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray90)
                    dateSection
                    divider
                    timeSection
                }
                .padding(16)
                
                Spacer().frame(height: 80)
            }
        }
        .background(Color.gray0)
        .overlay(alignment: .bottom) { bottomBar }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                } label: {
                    Image(systemName: viewModel.isKeep ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isKeep ? Color.rosyPunch : Color.gray90)
                }
            }
        }
        .task { viewModel.send(.onAppear) }
    }
}

// MARK: - Sections

private extension DetailView {
    
    var heroImage: some View {
        Group {
            if viewModel.thumbnails.isEmpty {
                heroPlaceholder
                    .frame(height: 300)
            } else {
                TabView {
                    ForEach(viewModel.thumbnails, id: \.self) { path in
                        KFImage(path.serverImageURL)
                            .requestModifier(AuthImageModifier())
                            .placeholder { heroPlaceholder }
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: viewModel.thumbnails.count > 1 ? .automatic : .never))
                .frame(height: 300)
                .clipped()
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
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.title)
                .font(.Pretendard.title1)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray90)
            
            HStack(spacing: 8) {
                Text(viewModel.country)
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray60)
                
                Text("|")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray30)
                
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.blackSeafoam)
                        .frame(width: 8, height: 8)
                    Text("\(viewModel.pointReward)P")
                        .font(.Pretendard.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.blackSeafoam)
                }
                
                if let rating = viewModel.rating {
                    Text("|")
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray30)
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.Pretendard.caption1)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gray90)
                        if let count = viewModel.reviewCount {
                            Text("(\(count))")
                                .font(.Pretendard.caption2)
                                .foregroundStyle(Color.gray45)
                        }
                    }
                }
            }
            
            if let desc = viewModel.state.detail?.description, !desc.isEmpty {
                Text(desc)
                    .font(.Pretendard.body3)
                    .foregroundStyle(Color.gray75)
                    .lineSpacing(4)
            }
            
            HStack(spacing: 16) {
                Label("누적 구매 \(viewModel.state.detail?.totalOrderCount ?? 0)회",
                      systemImage: "bag")
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray60)
                
                Label("KEEP \(viewModel.keepCount)회",
                      systemImage: viewModel.isKeep ? "heart.fill" : "heart")
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray60)
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
            infoItem(
                icon: "person.crop.circle.badge.checkmark",
                title: "연령제한",
                value: viewModel.restrictions?.minAge.map { "\($0)세" } ?? "없음"
            )
            Divider().frame(height: 40)
            infoItem(
                icon: "ruler",
                title: "신장제한",
                value: viewModel.restrictions?.minHeight.map { "\($0)cm" } ?? "없음"
            )
            Divider().frame(height: 40)
            infoItem(
                icon: "person.2",
                title: "최대참가인원",
                value: viewModel.restrictions?.maxParticipants.map { "\($0)명" } ?? "-"
            )
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
    
    var priceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if viewModel.price.original > viewModel.price.final {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.rosyPunch)
                    Text(viewModel.price.original.wonFormatted)
                        .font(.Pretendard.body3)
                        .foregroundStyle(Color.gray45)
                        .strikethrough(true, color: Color.gray45)
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("판매가")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
                
                Text(viewModel.price.final.wonFormatted)
                    .font(.Pretendard.body1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)
                
                if let pct = viewModel.discountPercent {
                    Text("\(pct)%")
                        .font(.Pretendard.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray0)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.rosyPunch)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
    
    var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("일정")
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.schedule.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Color.blackSeafoam)
                                .frame(width: 10, height: 10)
                                .padding(.top, 4)
                            Rectangle()
                                .fill(Color.gray30)
                                .frame(width: 1.5)
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.duration)
                                .font(.Pretendard.body3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.gray90)
                            Text(item.description)
                                .font(.Pretendard.caption1)
                                .foregroundStyle(Color.gray60)
                                .lineSpacing(3)
                        }
                        .padding(.bottom, 20)
                    }
                }

                // 마지막: 지도
                HStack(alignment: .top, spacing: 16) {
                    Circle()
                        .fill(Color.blackSeafoam)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                        .frame(width: 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("장소 위치 정보")
                            .font(.Pretendard.body3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gray90)

                        let coord = CLLocationCoordinate2D(
                            latitude: viewModel.geolocation.latitude,
                            longitude: viewModel.geolocation.longitude
                        )
                        Map(position: .constant(.region(MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        )))) {
                            Marker("", coordinate: coord)
                                .tint(Color.blackSeafoam)
                        }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(true)
                    }
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
            
            if viewModel.availableDates.isEmpty {
                Text("예약 가능한 날짜가 없습니다.")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(viewModel.availableDates.enumerated()), id: \.offset) { index, dateStr in
                            Button {
                                viewModel.send(.dateSelected(index))
                            } label: {
                                let display = AppFormatter.serverDate.date(from: dateStr)
                                    .map { AppFormatter.chipDate.string(from: $0) } ?? dateStr
                                Text(display)
                                    .font(.Pretendard.caption1)
                                    .fontWeight(viewModel.state.selectedDateIndex == index ? .semibold : .regular)
                                    .foregroundStyle(viewModel.state.selectedDateIndex == index ? Color.gray0 : Color.gray60)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(viewModel.state.selectedDateIndex == index ? Color.blackSeafoam : Color.gray15)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
    
    var timeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시간 선택")
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)

            if viewModel.availableTimes.isEmpty {
                Text("예약 가능한 시간이 없습니다.")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
            } else {
                if !amTimes.isEmpty {
                    timePeriodGrid(label: "오전", slots: amTimes)
                }
                if !pmTimes.isEmpty {
                    timePeriodGrid(label: "오후", slots: pmTimes)
                }
            }
        }
    }
    
    func timePeriodGrid(label: String, slots: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.Pretendard.caption1)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray60)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(slots, id: \.self) { time in
                    timeChip(time)
                }
            }
        }
    }
    
    func timeChip(_ time: String) -> some View {
        let isSelected = viewModel.state.selectedTime == time
        return Button {
            viewModel.send(.timeSelected(time))
        } label: {
            Text(displayTime(time))
                .font(.Pretendard.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.gray0 : Color.gray60)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.blackSeafoam : Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    var divider: some View {
        Rectangle()
            .fill(Color.gray15)
            .frame(height: 1)
    }
    
    var bottomBar: some View {
        HStack(spacing: 12) {
            Text(viewModel.price.final.wonFormatted)
                .font(.Pretendard.body2)
                .fontWeight(.bold)
                .frame(alignment: .leading)
                .foregroundStyle(Color.gray90)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
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

// MARK: - Time Helpers

private extension DetailView {
    var amTimes: [String] { viewModel.availableTimes.filter { hour(of: $0) < 12 } }
    var pmTimes: [String] { viewModel.availableTimes.filter { hour(of: $0) >= 12 } }
    
    func hour(of time: String) -> Int {
        Int(time.split(separator: ":").first ?? "0") ?? 0
    }
    
    func displayTime(_ time: String) -> String {
        guard let h = Int(time.split(separator: ":").first ?? ""),
              let m = Int(time.split(separator: ":").last ?? "") else { return time }
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d", h12, m)
    }
}

