import Foundation
import SpriteKit

class OESeaweedNode: SKSpriteNode {
    
    init(size: CGSize) {
        let texture = SKTexture(imageNamed: "Seaweed") // Initial seaweed texture
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
    
    func animate() {
        // Load seaweed textures
        let textures = [
            SKTexture(imageNamed: "Seawee"),
            SKTexture(imageNamed: "Seaweed"),
            SKTexture(imageNamed: "Seaweed2"),
            SKTexture(imageNamed: "Seaweed3"),
            SKTexture(imageNamed: "Seaweed4"),
            SKTexture(imageNamed: "Seaweed3"),
            SKTexture(imageNamed: "Seaweed2"),
            SKTexture(imageNamed: "Seaweed"),
        ]
        
        // Create animation action
        let animation = SKAction.animate(with: textures, timePerFrame: 0.20)
        let repeatAnimation = SKAction.repeatForever(animation)
        
        // Run the animation
        self.run(repeatAnimation)
    }
}
