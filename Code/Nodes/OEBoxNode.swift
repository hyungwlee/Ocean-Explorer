//
//  OEBoxNode.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//

import Foundation
import SpriteKit

class OEBoxNode: SKSpriteNode {
    
    init() {
        let texture = SKTexture(imageNamed: "Smiley")
        super.init(texture: texture, color: .clear, size: texture.size())
        self.name = "character"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Make the character jump up
    func jump() {
        let jumpAction = SKAction.moveBy(x: 0, y: 100, duration: 0.2) // Adjust Y value for jump height
        self.run(jumpAction)
    }
}
