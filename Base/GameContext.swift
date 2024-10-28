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

class GameContext {
    var shouldResetPlayback: Bool = false

    @Published var opacity: Double = 0.0
    @Published var isShowingSettings = false

    var subs = Set<AnyCancellable>()
    
    var scene: SKScene?

    private(set) var dependencies: Dependencies
    
    var gameType: GameType? {
        delegate?.gameType
    }

    weak var delegate: GameContextDelegate?

    init(dependencies deps: Dependencies) {
        dependencies = deps
    }
    
    func exit() {
    }
}

extension GameContext: ObservableObject {}
