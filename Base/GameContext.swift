//
//  GameContext.swift
//  Test
//
//  Created by Hyung Lee on 10/20/24.
//

import Combine
import GameplayKit
import SwiftUI

protocol GameContextDelegate: AnyObject {
    var gameMode: GameModeType { get }
    var gameType: GameType { get }

    func exitGame()
    func transitionToScore(_ score: Int)
}

class GameContext: ObservableObject {
    // MARK: - Properties
    @Published var opacity: Double = 0.0
    @Published var isShowingSettings = false
    var shouldResetPlayback = false
    var scene: SKScene?
    var subs = Set<AnyCancellable>()
    private(set) var dependencies: Dependencies
    weak var delegate: GameContextDelegate?
    
    var gameType: GameType? {
        delegate?.gameType
    }

    // MARK: - Initialization
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Exit
    func exit() {
        // Exit code if applicable
    }
}
