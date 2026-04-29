//
//  AppIcon.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import SwiftUI

// MARK: - General Icons
enum AppIcon {
    // Navigation
    static let back         = Image("icon_back")

    // Reaction
    static let heartOutline = Image("icon_heart")
    static let heartFill    = Image("icon_heart_fill")
    static let starOutline  = Image("icon_star")
    static let starFill     = Image("icon_star_fill")
    static let flame        = Image("icon_flame")

    // Action
    static let flower       = Image("icon_flower")
    static let search       = Image("icon_search")
    static let notification = Image("icon_notification")
    static let navigation   = Image("icon_navigation")
    static let stop         = Image("icon_stop")
    static let won          = Image("icon_won")
    static let sparkle      = Image("icon_sparkle")
    static let info         = Image("icon_info")
    static let location     = Image("icon_location")
    static let camera       = Image("icon_camera")
    static let menu         = Image("icon_menu")
    static let settings     = Image("icon_settings")
}

// MARK: - Tab Bar Icons
extension AppIcon {
    enum Tab {
        static let homeFill      = Image("icon_tab_home_fill")
        static let home          = Image("icon_tab_home")
        static let searchFill    = Image("icon_tab_search_fill")
        static let search        = Image("icon_tab_search")
        static let chatHeartFill = Image("icon_tab_chat_heart_fill")
        static let chatHeart     = Image("icon_tab_chat_heart")
        static let personFill    = Image("icon_tab_person_fill")
        static let person        = Image("icon_tab_person")
    }
}

// MARK: - Custom Icons
extension AppIcon {
    enum Custom {
        static let welcome = Image("icon_welcome")
        static let hand    = Image("icon_hand")
        static let paw     = Image("icon_paw")
    }
}

// MARK: - Country Flags
enum AppFlag: CaseIterable {
    case korea
    case japan
    case philippines
    case thailand
    case taiwan
    case argentina
    case australia

    var image: Image {
        switch self {
        case .korea:       return Image("flag_korea")
        case .japan:       return Image("flag_japan")
        case .philippines: return Image("flag_philippines")
        case .thailand:    return Image("flag_thailand")
        case .taiwan:      return Image("flag_taiwan")
        case .argentina:   return Image("flag_argentina")
        case .australia:   return Image("flag_australia")
        }
    }

    var countryName: String {
        switch self {
        case .korea:       return "Korea"
        case .japan:       return "Japan"
        case .philippines: return "Philippines"
        case .thailand:    return "Thailand"
        case .taiwan:      return "Taiwan"
        case .argentina:   return "Argentina"
        case .australia:   return "Australia"
        }
    }
}
