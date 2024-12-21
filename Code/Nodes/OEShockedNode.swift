import Foundation
import SpriteKit

class OEShockedNode: SKSpriteNode {
    
    init(size: CGSize) {
        let textureShocked = SKTexture(imageNamed: "OEShocked")
        
        super.init(texture: textureShocked, color: .clear, size: CGSize(width: textureShocked.size().width * 0.4, height: textureShocked.size().height * 0.4))
        
        
        self.zPosition = 2
    }
    
    func animate() {
        // Load seaweed textures
        let textures = [
            SKTexture(imageNamed: "OEShocked"),
            SKTexture(imageNamed: "OEDog"),
        ]
        
        // Create animation action
        let animation = SKAction.animate(with: textures, timePerFrame: 0.20)
        let repeatAnimation = SKAction.repeatForever(animation)
        
        // Run the animation
        self.run(repeatAnimation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
