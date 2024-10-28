//
//  GameType.swift
//  Test
//
//  Created by Hyung Lee on 10/20/24.
//

import SwiftUI

enum GameType: String, Codable {
    case none
    case test
    
    var miniIconName: String {
        switch self {
        case .test:
            return "cubecube-chat-bg"
        default:
            return ""
        }
    }
    static func type(withGameId id: String) -> GameType? {
        switch id {
        case "none":
            return nil
        case "testgame":
            return .test
        default:
            return nil
        }
    }
    
    var gameId: String { //[TODO] for now just hard coding game id for creating room and stuff
        switch self {
        case .none:
            return "none"
        case .test:
            return "testgame"
        }
    }
    
    var display: String {
        switch self {
        case .none:
            return "Unknown"
        case .test:
            return "TestGame"
        }
    }

    var maxPlayerCount: Int {
        switch self {
        case .none:
            return 0
        case .test:
            return 1
        }
    }

    var themeColor: Color {
        switch self {
        case .test:
            return .black
        default:
            return .black
        }
    }

    var iconColor: Color {
        switch self {
        case .test:
            return .black
        default:
            return .clear
        }
    }

    var leaderboardTitleColor: Color {
        switch self {
        case .test:
            return .black
        default:
            return .clear
        }
    }
    // TODO: cubeCube need image
    var waitRoomBGImageName: String {
        return "wr_bg_\(self.rawValue)"
    }
    
    var waitRoomTitleImageName: String {
        return "wr_title_\(self.rawValue)"
    }
    // TODO: cubeCube need image
    var scoreBGImageName: String {
        return "\(self.rawValue)_score_bg_tile"
    }
    
    var raffleRainbowTicketCount: Int {
        return 3 //TODO: need to implement actual handling
    }
    
    var waitRoomHighlightedIconColor: Color {
        switch self {
        case .test:
            return .white
        default:
            return .white
        }
    }
    
    var ticketsToPlay: Int {
        switch self {
        case .test:
            return 1
        default:
            return 0
        }
    }

    var backgroundImageName: String {
        switch self {
        case .test:
            return "test-chat-bg"
        default:
            return ""
        }
    }
}
