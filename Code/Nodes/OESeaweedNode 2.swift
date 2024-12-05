//
//  OERockNode.swift
//  Ocean Explorer
//
//  Created by Kaleb Ho Ching on 12/4/24.
//

import Foundation
import SpriteKit

class OESeaweedNode: SKSpriteNode {
    
    init(size: CGSize) {
        let texture = SKTexture(imageNamed: "Seaweed") // Use your seaweed asset name
        super.init(texture: texture, color: .clear, size: size)
        
        // Configure physics body
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = false // Stationary
        self.physicsBody?.categoryBitMask = PhysicsCategory.seaweed
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
        self.physicsBody?.collisionBitMask = PhysicsCategory.box
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
