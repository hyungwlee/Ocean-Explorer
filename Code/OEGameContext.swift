//
//  OEGameContext.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//

import Foundation
import SpriteKit
import Combine
import GameplayKit

class OEGameContext: GameContext {
    var gameScene: OEGameScene? {
        scene as? OEGameScene
    }
    let gameMode: GameModeType
    let gameInfo: OEGameInfo
    var layoutInfo: OELayoutInfo = .init(screenSize: .zero)
    
    private(set) var stateMachine: GKStateMachine?
    
    init(dependencies: Dependencies, gameMode: GameModeType) {
        self.gameInfo = OEGameInfo()
        self.gameMode = gameMode
        super.init(dependencies: dependencies)
    }
    
    func updateLayoutInfo(withScreenSize size: CGSize) {
        layoutInfo = OELayoutInfo(screenSize: size)
    }
    
    func configureStates() {
        guard let gameScene else { return }
        print("did configure states")
        stateMachine = GKStateMachine(states: [
            OEGameIdleState(scene: gameScene, context: self)
        ])
    }
}
