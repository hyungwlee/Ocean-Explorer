import Foundation
import SpriteKit

class OEBoxNode: SKSpriteNode {
    
    private let gridSize: CGSize
    private var lastClickTime: TimeInterval = 0
    private var isMoving = false

    init(gridSize: CGSize) {
        self.gridSize = gridSize
        let texture = SKTexture(imageNamed: "Smiley")
        super.init(texture: texture, color: .clear, size: CGSize(width: texture.size().width / 2, height: texture.size().height / 2))
        self.zPosition = 1
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask = PhysicsCategory.box
        self.physicsBody?.collisionBitMask = PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func move(to position: CGPoint) {
        guard !isMoving else { return } // Prevents new movement while already moving
        isMoving = true
        
        // Define a movement animation with a duration
        let moveAction = SKAction.move(to: position, duration: 0.2)
        
        // Run the movement action and set up the completion block
        self.run(moveAction) {
            // Movement completed, allow the next move
            self.isMoving = false
        }
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
}
