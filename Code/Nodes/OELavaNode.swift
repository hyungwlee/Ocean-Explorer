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
        let texture = SKTexture(imageNamed: "OELava") // Initial lava texture
        super.init(texture: texture, color: .clear, size: size)
        
        self.zPosition = 0
        
        // Configure physics body
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.affectedByGravity = false // Disable gravity
        self.physicsBody?.categoryBitMask = PhysicsCategory.lava
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animate() {
        // Load lava textures
        let textures = [
            SKTexture(imageNamed: "OELava"),
            SKTexture(imageNamed: "OELAVA2"),
            SKTexture(imageNamed: "OELAVA3"),
            SKTexture(imageNamed: "OELAVA4"),
            SKTexture(imageNamed: "OELAVA5"),
            SKTexture(imageNamed: "OELAVA6"),
        ]
        
        // Create animation action
        let animation = SKAction.animate(with: textures, timePerFrame: 0.5)
        
        // Add a pause at the end of the animation
        let pause = SKAction.wait(forDuration: 0.00) // Adjust the duration of the pause as needed
        
        // Create a sequence of animation followed by pause
        let animationSequence = SKAction.sequence([animation, pause])
        
        // Repeat the sequence forever
        let repeatAnimation = SKAction.repeatForever(animationSequence)
        
        // Run the animation
        self.run(repeatAnimation)
    }
}
