//
//  OERockNode.swift
//  Ocean Explorer
//
//  Created by Haseeb Garfinkel on 12/2/24.
//

import Foundation
import SpriteKit

class OERockNode: SKSpriteNode {
    
    var rockSpeed: CGFloat = 0
    var direction: CGVector = .zero
    
    init(height: CGFloat) {
        
        let texture = SKTexture(imageNamed: "Rock")
                
        super.init(texture: texture, color: .gray, size: CGSize(width: texture.size().width * 0.6, height: texture.size().height * 0.5))
        
        self.zPosition = 1

        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: height))
        self.physicsBody?.isDynamic = false // Rocks won't be affected by physics
        self.physicsBody?.categoryBitMask = PhysicsCategory.rock
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startMoving(from start: CGPoint, to end: CGPoint, speed: CGFloat) {
        self.position = start
        self.rockSpeed = speed
        
        if end.x > start.x {
            self.direction = CGVector(dx: 1, dy: 0)
        } else {
            self.direction = CGVector(dx: -1, dy: 0)
        }
        
        let moveAction = SKAction.move(to: end, duration: speed)

        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])
        
        run(sequence)
    }
}
