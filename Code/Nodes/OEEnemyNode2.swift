//
//  OEEnemyNode2.swift
//  Ocean Explorer
//
//  Created by Haseeb Garfinkel on 11/11/24.
//

import Foundation
import SpriteKit

class OEEnemyNode2: SKSpriteNode {

    private let gridSize: CGSize
    
    private let detectionRadius: CGFloat = 100.0
    private var isPuffed: Bool = false
    
    init(gridSize: CGSize) {
        self.gridSize = gridSize
        let texture = SKTexture(imageNamed: "Pufferfish")
        super.init(texture: texture, color: .clear, size: CGSize(width: texture.size().width / 2, height: texture.size().height / 2))
        
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.affectedByGravity = false // Disable gravity for the enemy
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = PhysicsCategory.box
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Determine if player is close to pufferfish
    func checkProximityToPlayer(playerPosition:CGPoint) {
        let distance = hypot(playerPosition.x - position.x, playerPosition.y - position.y)
        
        if distance < detectionRadius {
            if !isPuffed {
                puff()
            } else {
                deflate()
            }
        }
        
    }
    
    // Expand size of pufferfish
    func puff() {
        isPuffed = true
        
        let puffUp = SKAction.scale(to: CGFloat(2.0), duration: 1)
        run(puffUp)
    }
    
    // Decrease size of pufferfish
    func deflate() {
        isPuffed = false
        
        let deflate = SKAction.scale(to: CGFloat(1.0), duration: 1)
        run(deflate)
    }
}
