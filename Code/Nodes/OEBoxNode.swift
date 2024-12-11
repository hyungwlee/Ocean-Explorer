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
    private var lastClickTime: TimeInterval = 0
    private var isMoving = false

    init(gridSize: CGSize) {
        self.gridSize = gridSize
        let texture = SKTexture(imageNamed: "Smiley")
      
        super.init(texture: texture, color: .clear, size: CGSize(width: texture.size().width * 0.4, height: texture.size().height * 0.4))
        self.zPosition = 2

        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask = PhysicsCategory.box
        self.physicsBody?.collisionBitMask = PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.rock | PhysicsCategory.lava | PhysicsCategory.rock2 | PhysicsCategory.rock3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func move(to position: CGPoint) -> Int {
        guard !isMoving else { return 0} // Prevents new movement while already moving
        isMoving = true
        
        // Define a movement animation with a duration
        let moveAction = SKAction.move(to: position, duration: 0.2)
        
        // Run the movement action and set up the completion block
        self.run(moveAction) {
            // Movement completed, allow the next move
            self.isMoving = false
        }
        return 1
    }
    
    // Call this function for handling double-clicks
    func handleDoubleClick(to position: CGPoint) {
        let currentTime = CACurrentMediaTime()
        let timeDifference = currentTime - lastClickTime
        
        if timeDifference <= 0.3 {  // Considered a double-click if within 0.3 seconds
            // If a double-click is detected, execute the second movement
            move(to: position)
        }
        
        lastClickTime = currentTime
    }
    
    func snapToGrid(xPosition: CGFloat) {
        let moveAction = SKAction.move(to: CGPoint(x: xPosition, y: self.position.y), duration: 0.01)
        self.run(moveAction)
    }
    

    func getIsMoving() -> Bool {
        return isMoving
    }
    
    func hop(to position: CGPoint, inQueue: CGPoint, up: Bool) {
        
        if !up && isMoving {
            return
        }
        else if isMoving {
            movementQueue.append(inQueue)
            print("QUEUED IT!")
        } else {
            
            isMoving = true
            let scaleDown = SKAction.scale(to: 0.8, duration: 0.05)
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.05)
            let scaleDownBack = SKAction.scale(to: 1, duration: 0.05)
            
            let move = SKAction.move(to: position, duration: 0.15)
            let hopAction = SKAction.sequence([scaleDown, scaleUp, scaleDownBack])
            self.run(SKAction.group([hopAction, move])) {
                print("NOW IM DONE MOVING")
                self.isMoving = false
                if let nextPosition = self.movementQueue.first {
                    self.movementQueue.removeFirst()
                    self.hop(to: nextPosition, inQueue: nextPosition, up: true)
                }
            }
        }
    }

}
