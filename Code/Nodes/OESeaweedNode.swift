//
//  OERockNode.swift
//  Ocean Explorer
//
//  Created by Kaleb Ho Ching on 12/4/24.
//

import Foundation
import SpriteKit

class OESeaweedNode: SKSpriteNode {
    
    init(height: CGFloat) {
        
        let texture = SKTexture(imageNamed: "Rock")
                
        super.init(texture: texture, color: .gray, size: CGSize(width: texture.size().width * 1.5, height: texture.size().height * 1.4))
        
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
    
}
