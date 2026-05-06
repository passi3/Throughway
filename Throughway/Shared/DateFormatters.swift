//
//  DateFormatters.swift
//  Throughway
//
//  Created by passi on 5/6/26.
//

import Foundation

enum AppDateFormatter {
    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// "yyyy-MM-dd" — 날짜 변경 감지, 서버 날짜 파싱용
    static let serverDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    /// "yyyy-MM-dd HH:mm" — 같은 분 그루핑 키
    static let minuteKey: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    /// "yyyy년 M월 d일 EEEE" — 날짜 구분선 표시용
    static let dayLabel: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 EEEE"
        return f
    }()

    /// "M월 d일" — 칩/첨부 파일 날짜 표시용
    static let chipDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M월 d일"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()
}
