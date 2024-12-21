import Foundation
import SpriteKit

class OESeaweedNode: SKSpriteNode {
    
    init(size: CGSize) {
        let texture = SKTexture(imageNamed: "OESeaweed") // Initial seaweed texture
        super.init(texture: texture, color: .clear, size: size)
        
        // Configure physics body
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = false // Stationary
        self.physicsBody?.categoryBitMask = PhysicsCategory.seaweed
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
        self.physicsBody?.collisionBitMask = PhysicsCategory.box
        
        self.zPosition = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OESeaweedNode: AnimatableSeaweed {
    func animate() {
        // Load seaweed textures
        let textures = [
            SKTexture(imageNamed: "OESeawee"),
            SKTexture(imageNamed: "OESeaweed"),
            SKTexture(imageNamed: "OESeaweed2"),
            SKTexture(imageNamed: "OESeaweed3"),
            SKTexture(imageNamed: "OESeaweed4"),
            SKTexture(imageNamed: "OESeaweed3"),
            SKTexture(imageNamed: "OESeaweed2"),
            SKTexture(imageNamed: "OESeaweed"),
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
