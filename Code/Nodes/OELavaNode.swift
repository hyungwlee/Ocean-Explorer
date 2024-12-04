//
//  OELavaNode.swift
//  Ocean Explorer
//
//  Created by Haseeb Garfinkel on 12/2/24.
//

import Foundation
import SpriteKit

class OELavaNode: SKSpriteNode {
    
    init(size: CGSize) {
        
        let texture = SKTexture(imageNamed: "Lava")

        super.init(texture: texture, color: .clear, size: size)
        
        self.zPosition = 0
        
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.affectedByGravity = false // Disable gravity for the enemy
        self.physicsBody?.categoryBitMask = PhysicsCategory.lava
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
