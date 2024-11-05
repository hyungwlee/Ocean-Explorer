//
//  OEGameIdleState.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//

import Foundation
import GameplayKit


class OEGameIdleState: GKState {
    weak var scene: OEGameScene?
    weak var context: OEGameContext?
    
    init(scene: OEGameScene, context: OEGameContext) {
        self.scene = scene
        self.context = context
        super.init()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    
    override func didEnter(from previousState: GKState?) {
        print("did enter idle state")
    }
    
    func handleTouch(_ touch: UITouch) {
        guard let scene, let context else { return }
        print("touched \(touch)")
        let touchLocation = touch.location(in: scene)
        let newBoxPos = CGPoint(x: touchLocation.x - context.layoutInfo.boxSize.width / 2.0,
                                y: touchLocation.y - context.layoutInfo.boxSize.height / 2.0)
        scene.box?.position = newBoxPos
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene, let context else { return }
        let touchLocation = touch.location(in: scene)
        let newBoxPos = CGPoint(x: touchLocation.x - context.layoutInfo.boxSize.width / 2.0,
                                y: touchLocation.y - context.layoutInfo.boxSize.height / 2.0)
        scene.box?.position = newBoxPos
    }
    //....
}
