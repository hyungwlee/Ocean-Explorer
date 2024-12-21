import Foundation
import SpriteKit

class OESeaweedNode2: SKSpriteNode {
    
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

extension OESeaweedNode2: AnimatableSeaweed {
    func animate() {
        // Load seaweed textures
        let textures = [
            SKTexture(imageNamed: "OESeaweed2-0"),
            SKTexture(imageNamed: "OESeaweed2-1"),
            SKTexture(imageNamed: "OESeaweed2-2"),
            SKTexture(imageNamed: "OESeaweed2-3"),
            SKTexture(imageNamed: "OESeaweed2-4"),
        ]
        
        // Define different animation orders
        let animationOrders = [
            [textures[0], textures[1], textures[2], textures[3], textures[4], textures[3], textures[2], textures[1], textures[0]], // Default order
            [textures[4], textures[3], textures[2], textures[1], textures[0], textures[1], textures[2], textures[3], textures[4]], // Reverse order
            [textures[2], textures[3], textures[4], textures[0], textures[1], textures[2], textures[3], textures[4], textures[0]],
            [textures[0], textures[0], textures[0], textures[0], textures[0], textures[0], textures[0], textures[0], textures[0]],
            [textures[1], textures[3], textures[2], textures[1], textures[0], textures[1], textures[2], textures[3], textures[4]],
        ]
        
        // Randomly select an animation order
        let randomOrder = animationOrders.randomElement() ?? animationOrders[0]
        
        // Create animation action
        let animation = SKAction.animate(with: randomOrder, timePerFrame: 0.2)
        let repeatAnimation = SKAction.repeatForever(animation)
        
        // Run the animation
        self.run(repeatAnimation)
    }
}
