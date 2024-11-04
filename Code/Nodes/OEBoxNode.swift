//
//  OEBoxNode.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//

import Foundation
import SpriteKit

class OEBoxNode: SKSpriteNode {
    
    private let gridSize: CGSize

    init(gridSize: CGSize) {
        self.gridSize = gridSize
        let texture = SKTexture(imageNamed: "Smiley")
        super.init(texture: texture, color: .clear, size: CGSize(width: texture.size().width / 2, height: texture.size().height / 2))  // Scaled down by 50%
        self.name = "character"
        
        // Set up physics body with no gravity
        self.physicsBody = SKPhysicsBody(texture: texture, size: size)
        self.physicsBody?.isDynamic = false  // No dynamic movement, only for collision detection
        self.physicsBody?.categoryBitMask = PhysicsCategory.box
        self.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = PhysicsCategory.enemy
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Moves the character to a specified position
    func move(to position: CGPoint) {
        let moveAction = SKAction.move(to: position, duration: 0.2)
        self.run(moveAction)
    }
}
