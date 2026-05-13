//
//  ActivityCard.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI

struct ActivityCard: View {
    let activity: ActivitySummaryDTO
    var onKeepTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            activityThumbnail
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(activity.title)
                        .font(.Pretendard.body4)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        onKeepTapped?()
                    } label: {
                        Image(systemName: activity.isKeep ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.error)
                    }
                    .buttonStyle(.borderless)
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.error)
                    Text("\(activity.keepCount)개")
                        .font(.Pretendard.caption3)
                        .foregroundStyle(Color.textTertiary)
                }

                Text(activity.country)
                    .font(.Pretendard.caption3)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)

                Text(activity.price.final.wonFormatted)
                    .font(.Pretendard.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(12)
        .background(Color.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var activityThumbnail: some View {
        if let thumbnail = activity.thumbnails.first {
            MediaThumbnailView(path: thumbnail, height: 100, cornerRadius: 10)
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.bgTertiary)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(Color.textTertiary)
                )
        }
    }
}
