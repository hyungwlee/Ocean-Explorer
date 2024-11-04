//
//  OEGameScene.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//
import SpriteKit

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let box: UInt32 = 0b1       // 1
    static let enemy: UInt32 = 0b10    // 2
}

class OEGameScene: SKScene, SKPhysicsContactDelegate {
    weak var context: OEGameContext?
    var box: OEBoxNode?
    var cameraNode: SKCameraNode!
    
    let gridSize = CGSize(width: 50, height: 50)  // Smaller grid for more lines
    var backgroundTiles: [SKSpriteNode] = []
    var lastEnemySpawnPositionY: CGFloat = 0  // Track the last Y position where an enemy spawned

    var playableWidthRange: ClosedRange<CGFloat> {
        return (-size.width / 2)...(size.width / 2)
    }

    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.cameraNode = SKCameraNode()
        self.camera = cameraNode
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard let context else { return }
        
        setupBackground()
        prepareGameContext()
        prepareStartNodes()
        
        cameraNode.position = CGPoint(x: 0, y: 0)
        context.stateMachine?.enter(OEGameIdleState.self)
        
        addSwipeGestureRecognizers()
        
        // Set up physics world contact delegate
        physicsWorld.contactDelegate = self
    }

    func setupBackground() {
        addBackgroundTile(at: CGPoint(x: 0, y: 0))
        addChild(cameraNode)
    }

    func addBackgroundTile(at position: CGPoint) {
        let backgroundNode = SKSpriteNode(imageNamed: "Background")
        backgroundNode.size = size
        backgroundNode.position = position
        backgroundNode.zPosition = -1
        addChild(backgroundNode)
        backgroundTiles.append(backgroundNode)
    }
    
    func prepareGameContext() {
        guard let context else { return }
        context.scene = self
        context.updateLayoutInfo(withScreenSize: size)
        context.configureStates()
    }
    
    func prepareStartNodes() {
        let center = CGPoint(x: 0, y: 0)
        box = OEBoxNode(gridSize: gridSize)
        box?.position = center
        if let box = box {
            addChild(box)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        followCharacter()
        updateBackgroundTiles()
        spawnEnemyIfNeeded()
    }
    
    func followCharacter() {
        if let box = box {
            cameraNode.position.y = box.position.y
        }
    }

    func updateBackgroundTiles() {
        guard let box else { return }
        
        let thresholdY = cameraNode.position.y + size.height / 2
        if let lastTile = backgroundTiles.last, lastTile.position.y < thresholdY {
            addBackgroundTile(at: CGPoint(x: 0, y: lastTile.position.y + size.height))
        }

        backgroundTiles = backgroundTiles.filter { tile in
            if tile.position.y < cameraNode.position.y - size.height {
                tile.removeFromParent()
                return false
            }
            return true
        }
    }

    func addSwipeGestureRecognizers() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for direction in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = direction
            view?.addGestureRecognizer(swipe)
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard let box else { return }

        let nextPosition: CGPoint
        switch sender.direction {
        case .up:
            nextPosition = CGPoint(x: box.position.x, y: box.position.y + gridSize.height)
        case .down:
            nextPosition = CGPoint(x: box.position.x, y: box.position.y - gridSize.height)
        case .left:
            nextPosition = CGPoint(x: max(box.position.x - gridSize.width, playableWidthRange.lowerBound), y: box.position.y)
        case .right:
            nextPosition = CGPoint(x: min(box.position.x + gridSize.width, playableWidthRange.upperBound), y: box.position.y)
        default:
            return
        }

        box.move(to: nextPosition)
    }
    
    func spawnEnemyIfNeeded() {
        guard let box = box else { return }
        
        // Check if box has moved 15 tiles since the last enemy spawn
        if box.position.y - lastEnemySpawnPositionY >= gridSize.height * 15 {
            lastEnemySpawnPositionY = box.position.y  // Update the last spawn position
            
            // Create a new enemy and start its movement
            let enemy = OEEnemyNode()
            let startX = size.width / 2 + enemy.size.width  // Start off-screen to the right
            let yPos = box.position.y + gridSize.height * 5  // 5 grid tiles ahead of the box's current position
            
            let endX = -size.width / 2 - enemy.size.width   // End off-screen to the left
            
            enemy.startMoving(from: CGPoint(x: startX, y: yPos), to: CGPoint(x: endX, y: yPos))
            addChild(enemy)
        }
    }
    
    // Handle contact between physics bodies
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.enemy) ||
           (bodyA.categoryBitMask == PhysicsCategory.enemy && bodyB.categoryBitMask == PhysicsCategory.box) {
            gameOver()
        }
    }

    func gameOver() {
        // Implement your game over logic here
        print("Game Over!")
        // You could present a game over scene or reset the game
    }
}
