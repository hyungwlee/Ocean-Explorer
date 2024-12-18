import Foundation
import SpriteKit

class OECoralNode: SKSpriteNode {
    
    init(size: CGSize) {
        let texture = SKTexture(imageNamed: "Coral") // Initial coral texture
        super.init(texture: texture, color: .clear, size: size)
        
        // Set transparency
        self.alpha = 0.60 // Adjust value between 0.0 (fully transparent) and 1.0 (fully opaque)
        
        // Configure physics body
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = false // Stationary
        self.physicsBody?.categoryBitMask = PhysicsCategory.coral
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
        self.physicsBody?.collisionBitMask = PhysicsCategory.box
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
