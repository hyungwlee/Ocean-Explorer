//
//  OEGameContext.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//

import SpriteKit
import GameplayKit

/// Context class: game state, layout, scene
class OEGameContext: GameContext {
    
    // MARK: - Properties
    let gameMode: GameModeType
    let gameInfo: OEGameInfo
    var layoutInfo: OELayoutInfo = .init(screenSize: .zero)
    private(set) var stateMachine: GKStateMachine?
    
    var gameScene: OEGameScene? {
        scene as? OEGameScene
    }

    // MARK: - Initialization
    init(dependencies: Dependencies, gameMode: GameModeType) {
        self.gameInfo = OEGameInfo()
        self.gameMode = gameMode
        super.init(dependencies: dependencies)
    }

    // MARK: - Layout Management
    func updateLayoutInfo(withScreenSize size: CGSize) {
        layoutInfo = OELayoutInfo(screenSize: size)
    }

    // MARK: - State Management
    func configureStates() {
        guard let gameScene = gameScene else { return }
        
        print("States have been configured.")
        
        stateMachine = GKStateMachine(states: [
            OEGameIdleState(scene: gameScene, context: self)
        ])
    }
}
