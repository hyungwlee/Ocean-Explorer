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

struct Lane {
    let startPosition: CGPoint
    let endPosition: CGPoint
    let direction: CGVector
}

class OEGameScene: SKScene, SKPhysicsContactDelegate {
    weak var context: OEGameContext?
    var box: OEBoxNode?
    var cameraNode: SKCameraNode!
    
    let gridSize = CGSize(width: 50, height: 50)  // Smaller grid for more lines
    var backgroundTiles: [SKSpriteNode] = []
    var lastEnemySpawnPositionY: CGFloat = 0  // Track the last Y position where an enemy spawned
    
    var lanes: [Lane] = []

    var playableWidthRange: ClosedRange<CGFloat> {
        return (-size.width / 2)...(size.width / 2)
    }
    
    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.cameraNode = SKCameraNode()
        self.camera = cameraNode
        
        let numberOfLanes = 5 // Example: three lanes
        let laneHeight = size.height / CGFloat(numberOfLanes)

        for i in 0..<numberOfLanes {
            let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
            let leftStart = CGPoint(x: 0, y: yPosition)
            let rightStart = CGPoint(x: size.width, y: yPosition)

            // Alternate directions for lanes
            if i % 2 == 0 {
                lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0)))
            } else {
                lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0)))
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard let context else { return }
        
        setupBackground()
        prepareGameContext()
        prepareStartNodes()
        startSpawning()
        
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
    
    // Spawns enemies into a lane
    func spawnEnemy(in lane: Lane) {
        let enemy = OEEnemyNode()
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition)
    }
    
    // Populates lanes with enemies
    func startSpawning() {
        for lane in lanes {
            let wait = SKAction.wait(forDuration: 3.0) // Adjust for spawn frequency
            let spawn = SKAction.run { [weak self] in
                self?.spawnEnemy(in: lane)
            }
            let sequence = SKAction.sequence([spawn, wait])
            let repeatAction = SKAction.repeatForever(sequence)

            run(repeatAction)
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
