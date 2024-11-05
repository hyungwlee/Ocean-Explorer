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

    let gridSize = CGSize(width: 50, height: 50)
    var backgroundTiles: [SKSpriteNode] = []
    
    // Score properties
    var score = 0
    var scoreLabel: SKLabelNode!
    
    // Game state variable
    var isGameOver = false

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

        // Disable gravity in the scene's physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        setupBackground()
        prepareGameContext()
        prepareStartNodes()

        cameraNode.position = CGPoint(x: 0, y: 0)
        context.stateMachine?.enter(OEGameIdleState.self)

        addGestureRecognizers()

        // Set up physics world contact delegate
        physicsWorld.contactDelegate = self

        // Start timed enemy spawning
        startEnemySpawning()

        // Initialize and set up score label
        setupScoreLabel()
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

    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "SF Mono")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -size.width / 2 + 20, y: size.height / 2 - 75)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.text = "\(score)"
        cameraNode.addChild(scoreLabel)
    }

    func updateScore() {
        score += 1
        scoreLabel.text = "\(score)"
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

    func addGestureRecognizers() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for direction in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = direction
            view?.addGestureRecognizer(swipe)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view?.addGestureRecognizer(tap)
    }
    
    @objc func handleTap() {
        guard let box, !isGameOver else { return }
        let nextPosition = CGPoint(x: box.position.x, y: box.position.y + gridSize.height)
        box.move(to: nextPosition)
        updateScore()
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard let box, !isGameOver else { return }

        let nextPosition: CGPoint
        switch sender.direction {
        case .up:
            nextPosition = CGPoint(x: box.position.x, y: box.position.y + gridSize.height)
            updateScore()
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
    
    func startEnemySpawning() {
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnRandomEnemy()
        }
        let waitAction = SKAction.wait(forDuration: Double.random(in: 2...5))
        let sequence = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequence)
        
        run(repeatAction, withKey: "spawnEnemies")
    }

    func spawnRandomEnemy() {
        let enemy = OEEnemyNode(gridSize: gridSize)
        let isLeftToRight = Bool.random()
        let startX = isLeftToRight ? -size.width / 2 - enemy.size.width : size.width / 2 + enemy.size.width
        let endX = isLeftToRight ? size.width / 2 + enemy.size.width : -size.width / 2 - enemy.size.width
        let yPos = (box?.position.y ?? 0) + CGFloat.random(in: 3...6) * gridSize.height
        enemy.startMoving(from: CGPoint(x: startX, y: yPos), to: CGPoint(x: endX, y: yPos))
        addChild(enemy)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.enemy) ||
           (bodyA.categoryBitMask == PhysicsCategory.enemy && bodyB.categoryBitMask == PhysicsCategory.box) {
            if !isGameOver {
                gameOver()
            }
        }
    }

    func gameOver() {
        isGameOver = true
        removeAction(forKey: "spawnEnemies")
        score = 0
        scoreLabel.text = "\(score)"

        let gameOverLabel = SKLabelNode(text: "Game Over!")
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: cameraNode.position.y)
        cameraNode.addChild(gameOverLabel)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.restartGame()
        }
    }

    func restartGame() {
        let newScene = OEGameScene(context: context!, size: size)
        newScene.scaleMode = .aspectFill
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
    }
}
