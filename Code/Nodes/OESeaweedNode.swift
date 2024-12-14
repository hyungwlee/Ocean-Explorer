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
        
        // Define different animation orders
        let animationOrders = [
            [textures[0], textures[1], textures[2], textures[3], textures[4], textures[5], textures[6], textures[7]], // Default order
            [textures[7], textures[6], textures[5], textures[4], textures[3], textures[2], textures[1], textures[0]], // Reverse order
            [textures[3], textures[4], textures[5], textures[6], textures[7], textures[0], textures[1], textures[2]],
            [textures[6], textures[7], textures[0], textures[1], textures[2], textures[3], textures[4], textures[5]],
            [textures[0], textures[0], textures[0], textures[0], textures[0], textures[0], textures[0], textures[0]],
        ]
        
        // Randomly select an animation order
        let randomOrder = animationOrders.randomElement() ?? animationOrders[0]
        
        // Create animation action
        let animation = SKAction.animate(with: randomOrder, timePerFrame: 0.20)
        let repeatAnimation = SKAction.repeatForever(animation)
        
        // Run the animation
        self.run(repeatAnimation)
    }
}
