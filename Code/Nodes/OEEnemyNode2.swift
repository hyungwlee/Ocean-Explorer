//
//  OEEnemyNode2.swift
//  Ocean Explorer
//
//  Created by Haseeb Garfinkel on 11/11/24.
//

import Foundation
import SpriteKit
import AVFoundation

class OEEnemyNode2: SKSpriteNode {
    
    private let gridSize: CGSize
    
    private let detectionRadius: CGFloat = 100.0
    private var isPuffed: Bool = false
    

    var audioPlayer: AVAudioPlayer? // Audio player
    
    private var flipped: Bool
    
    init(gridSize: CGSize, flipped: Bool) {

        self.gridSize = gridSize
        self.flipped = flipped
        let texture = SKTexture(imageNamed: "Pufferfish")
        super.init(texture: texture, color: .clear, size: CGSize(width: texture.size().width * 0.4, height: texture.size().height * 0.4))
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.affectedByGravity = false // Disable gravity for the enemy
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = PhysicsCategory.box
        self.physicsBody?.contactTestBitMask = PhysicsCategory.box
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playPufferfishInflateSound() {
        if let soundURL = Bundle.main.url(forResource: "pufferfish", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.55 // Set to maximum volume
                audioPlayer?.play()
            } catch {
                print("Error playing pufferfish inflate sound: \(error.localizedDescription)")
            }
        } else {
            print("Pufferfish sound file not found.")
        }
    }
    
    // Determine if player is close to pufferfish
    func checkProximityToPlayer(playerPosition:CGPoint) {
        let distance = hypot(playerPosition.x - position.x, playerPosition.y - position.y)
        
        if distance < detectionRadius {
            if !isPuffed {
                puff()
                playPufferfishInflateSound()
            }
        } else {
            if isPuffed {
                deflate()
            }
        }
        
    }
    
    // Expand size of pufferfish
    func puff() {
        isPuffed = true
        
        var puffUp = SKAction.scale(to: CGFloat(2.0), duration: 0.4)
        if flipped {
            let puffUpX = SKAction.scaleX(to: CGFloat(-2.0), duration: 0.4)
            let puffUpY = SKAction.scaleY(to: CGFloat(2.0), duration: 0.4)
            puffUp = SKAction.group([puffUpX, puffUpY])
        }
        run(puffUp)
    }
    
    // Decrease size of pufferfish
    func deflate() {
        isPuffed = false
        
        var deflate = SKAction.scale(to: CGFloat(1.0), duration: 1)
        if flipped {
            let deflateX = SKAction.scaleX(to: CGFloat(-1.0), duration: 1)
            let deflateY = SKAction.scaleY(to: CGFloat(1.0), duration: 1)
            deflate = SKAction.group([deflateX, deflateY])
        }
        run(deflate)
    }
    
    func startMoving(from start: CGPoint, to end: CGPoint, speed: CGFloat) {
        self.position = start
        
        let moveAction = SKAction.move(to: end, duration: speed)
        
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])
        
        run(sequence)
    }
}
