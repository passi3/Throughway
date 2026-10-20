# Throughway
Throughway는 여행 액티비티 탐색부터 예약·결제, 여행 경험 공유와 사용자 간 채팅까지 제공하는 SwiftUI 기반 iOS 앱입니다.
- 개인 프로젝트
- 개발 기간: 2026.04 ~ 2026.05
- 지원: iOS 26.0+ / iPhone 세로

## 주요 기능
| 기능 | 설명 |
| --- | --- |
| 로그인·회원가입 | 이메일 기반 인증 및 토큰 갱신을 통한 로그인 유지 |
| 액티비티 탐색 | 국가·카테고리별 조회, 검색, 상세 정보 확인 및 찜 |
| 예약·결제 | 예약 날짜·시간·참여 인원 선택, PG 결제 및 서버 영수증 검증 API 연동 |
| 위치 기반 커뮤니티 | 주변 게시글 조회, 거리·정렬 필터, 게시글 작성 및 댓글·좋아요 |
| 실시간 채팅 | 1:1 메시지, 파일 첨부, 전송 실패 시 재시도 |
| 프로필 | 프로필 수정, 구매 내역 조회 및 리뷰 작성 |
| 푸시 알림 | 채팅 알림 수신 및 해당 채팅방으로 이동 |
## 기술 스택
| 영역 | 사용 기술 |
| --- | --- |
| 언어·UI | Swift, SwiftUI, UIKit 연동 |
| 상태 관리·비동기 처리 | Combine, Swift Concurrency, AsyncStream |
| 네트워크 | Alamofire |
| 로컬 저장소 | Realm, Keychain, UserDefaults |
| 실시간 통신·알림 | Socket.IO, Firebase Cloud Messaging |
| 이미지 | Kingfisher |
| 결제 | iamport-ios |
| 위치·지도 | CoreLocation, MapKit |
## 프로젝트 구조
Throughway/
├── ThroughwayApp.swift   # 앱 진입점 및 알림·외부 URL 처리
├── Feature/              # 기능별 View, ViewModel, State·Intent
├── Services/
│   ├── Network/          # Router, APIClient, DTO, 공통 네트워크
│   ├── LocalDB/          # Realm 채팅 저장소
│   ├── Socket/           # 실시간 메시지 수신
│   ├── Payment/          # 결제 SDK 연동 및 미완료 결제 저장
│   └── Cache/            # 사용자 상호작용 캐시
├── Shared/               # 공통 컴포넌트, 디자인 및 유틸리티
└── Resources/            # 폰트 등 리소스
