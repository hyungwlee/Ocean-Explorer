//
//  OEEnemyNode3.swift
//  Ocean Explorer
//
//  Created by Haseeb Garfinkel on 11/13/24.
//

import Foundation
import SpriteKit

class OEEnemyNode3: SKSpriteNode {
    
    private let gridSize: CGSize
    
    init(gridSize: CGSize) {
        self.gridSize = gridSize
        super.init(texture: nil, color: .black, size: CGSize(width: 1000, height: 40))
        
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.affectedByGravity = false // Disable gravity for the enemy
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = PhysicsCategory.box
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startMoving(from start: CGPoint, to end: CGPoint) {
        self.position = start
        self.position.x = self.position.x + 2000

        let moveAction = SKAction.move(to: CGPoint(x: end.x - 2000, y: end.y), duration: 10) // Adjust the duration as necessary

        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])
        
        run(sequence)
    }
}
