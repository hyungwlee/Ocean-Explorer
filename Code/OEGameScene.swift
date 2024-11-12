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
    static let bubble: UInt32 = 0b100  // 4
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

    let gridSize = CGSize(width: 50, height: 50)
    var backgroundTiles: [SKSpriteNode] = []
  
    // Score properties
    var score = 0
    var scoreLabel: SKLabelNode!
    
    // Air properties
    var airAmount = 100
    var airLabel: SKLabelNode!
    var airIcon: SKSpriteNode!
    
    // Game state variable
    var isGameOver = false
    var lanes: [Lane] = []  // Added this line to define lanes
    var laneDirection = 0
    
    var playableWidthRange: ClosedRange<CGFloat> {
        return (-size.width / 2)...(size.width / 2)
    }
    
    var yPositionLanes: CGFloat = 0
    
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
            let leftStart = CGPoint(x: -size.width, y: yPosition)
            let rightStart = CGPoint(x: size.width, y: yPosition)

            // Random directions for lanes
            laneDirection = Int.random(in: 0..<2)
            
            if laneDirection == 0 {
                lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0)))
            } else {
                lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0)))
            }
            yPositionLanes = yPosition
        }
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
        startSpawning(lanes: lanes)

        // Initialize and set up score label
        setupScoreLabel()
        setupAirDisplay()
        airCountDown()
        includeBubbles()

        startCameraMovement()
    }

    func startCameraMovement() {
        let moveUp = SKAction.moveBy(x: 0, y: size.height, duration: 25) // Adjust duration as needed CAMERA SPEED GOING UP
        let continuousMove = SKAction.repeatForever(moveUp)
        cameraNode.run(continuousMove)

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
        updateBackgroundTiles()

        for child in children {
            if let pufferfish = child as? OEEnemyNode2 {
                pufferfish.checkProximityToPlayer(playerPosition: box?.position ?? .zero)
            }
        }
        
        // Check if the character goes below the view due to the camera moving up
        if let box = box, box.position.y < cameraNode.position.y - size.height / 2 {
            gameOver()
        }
    }

    func updateBackgroundTiles() {
        guard let box else { return }

        let thresholdY = cameraNode.position.y + size.height / 2
        if let lastTile = backgroundTiles.last, lastTile.position.y < thresholdY {
            addBackgroundTile(at: CGPoint(x: 0, y: lastTile.position.y + size.height))
            // generate new lanes
            generateNewLanes(startingAt: yPositionLanes, numberOfLanes: 5)
        }

        backgroundTiles = backgroundTiles.filter { tile in
            if tile.position.y < cameraNode.position.y - size.height {
                tile.removeFromParent()
                return false
            }
            return true
        }
    }
    
    func generateNewLanes(startingAt yPosition: CGFloat, numberOfLanes: Int) {
        var newLanes: [Lane] = []
        let laneHeight = size.height / CGFloat(numberOfLanes)
        
        for i in 0..<numberOfLanes {
            let newYPosition = yPosition + CGFloat(i + 1) * laneHeight
            let leftStart = CGPoint(x: -size.width, y: newYPosition)
            let rightStart = CGPoint(x: size.width, y: newYPosition)
            
            // Random directions for lanes
            laneDirection = Int.random(in: 0..<2)
            
            if laneDirection == 0 {
                let newLane = Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0))
                newLanes.append(newLane)
            } else {
                let newLane = Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0))
                newLanes.append(newLane)
            }
            yPositionLanes = newYPosition
        }
        let laneType = Int.random(in: 0..<2)
        if laneType == 0 {
            startSpawning(lanes: newLanes)

        } else {
            startSpawningPufferfish(lanes: newLanes)
        }
    }

    func removeAllGestureRecognizers() {
        if let gestureRecognizers = view?.gestureRecognizers {
            for gesture in gestureRecognizers {
                view?.removeGestureRecognizer(gesture)
            }
        }
    }

    func addGestureRecognizers() {
        // First, remove any existing gesture recognizers to prevent buildup
        removeAllGestureRecognizers()

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
        moveBox(to: nextPosition)
        updateScore()
    }

    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard let box, !isGameOver else { return }

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
        moveBox(to: nextPosition)
    }

    func moveBox(to position: CGPoint) {
        box?.move(to: position)
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

    func spawnEnemy(in lane: Lane) {
        let enemy = OEEnemyNode(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition)
    }

    func startSpawning(lanes: [Lane]) {
      
        for lane in lanes {
            let wait = SKAction.wait(forDuration: Double.random(in: 1.5...3.0)) // Adjust for spawn frequency
            let spawn = SKAction.run { [weak self] in
                self?.spawnEnemy(in: lane)
            }
            let sequence = SKAction.sequence([spawn, wait])
            let repeatAction = SKAction.repeatForever(sequence)
            
            run(repeatAction)
        }
    }

    
    func spawnPufferfish(at: CGPoint) {
        let pufferfish = OEEnemyNode2(gridSize: gridSize)
        pufferfish.position = at
        addChild(pufferfish)
        pufferfish.puff()
    }
    
    func startSpawningPufferfish(lanes: [Lane]) {
        for lane in lanes {
            var xCoordinates = [CGFloat]()
            for _ in 0..<3 {
                let randomX = CGFloat.random(in: -size.width...size.width)
                xCoordinates.append(randomX)
            }
            for x in xCoordinates {
                spawnPufferfish(at: CGPoint(x: x, y: lane.endPosition.y))
            }
        }
        
    }
    

    func spawnBubble() {
        let bubble = SKSpriteNode(imageNamed: "Bubble") // Use your bubble asset
        bubble.size = CGSize(width: 45, height: 45) // Adjust size as needed
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: bubble.size.width / 2)
        bubble.physicsBody?.categoryBitMask = PhysicsCategory.bubble
        bubble.physicsBody?.contactTestBitMask = PhysicsCategory.box
        bubble.physicsBody?.collisionBitMask = PhysicsCategory.none
        bubble.physicsBody?.isDynamic = false
        
        let randomX = CGFloat.random(in: playableWidthRange)
        let randomY = (box?.position.y ?? 0) + size.height * 0.5 + CGFloat.random(in: 0...200)
        bubble.position = CGPoint(x: randomX, y: randomY)
        
        addChild(bubble)
    }

    func includeBubbles() {
        let bubbleSpawnAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnBubble()
                },
                SKAction.wait(forDuration: Double.random(in: 5...10)) // Adjust spawn frequency
            ])
        )
        run(bubbleSpawnAction, withKey: "spawnBubbles")
    }

    func setupAirDisplay() {
        airIcon = SKSpriteNode(imageNamed: "Bubble")
        airIcon.size = CGSize(width: 30, height: 30)
        airIcon.position = CGPoint(x: size.width / 2 - 60, y: size.height / 2 - 70)
        airIcon.zPosition = 1
        cameraNode.addChild(airIcon)

        airLabel = SKLabelNode(fontNamed: "SF Mono")
        airLabel.fontSize = 32
        airLabel.fontColor = .white
        airLabel.position = CGPoint(x: airIcon.position.x - 20, y: airIcon.position.y - 10)
        airLabel.horizontalAlignmentMode = .right
        airLabel.text = "\(airAmount)"
        cameraNode.addChild(airLabel)
    }

    func airCountDown() {
        let countdownAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.decreaseAir()
                },
                SKAction.wait(forDuration: 0.5)
            ])
        )
        run(countdownAction, withKey: "airCountdown")
    }

    func decreaseAir() {
        guard !isGameOver else { return }
        
        if airAmount > 0 {
            airAmount -= 1
            airLabel.text = "\(airAmount)"
        } else {
            gameOver()
        }
    }

    func increaseAir() {
        guard !isGameOver else { return }
        
        if airAmount < 90 {
            airAmount += 10
            airLabel.text = "\(airAmount)"
        } else if airAmount >= 90 && airAmount <= 100 {
            airAmount = 100
            airLabel.text = "\(airAmount)"
        }
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
        
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.bubble) ||
           (bodyA.categoryBitMask == PhysicsCategory.bubble && bodyB.categoryBitMask == PhysicsCategory.box) {
            increaseAir()
            if bodyA.categoryBitMask == PhysicsCategory.bubble {
                bodyA.node?.removeFromParent()
            } else if bodyB.categoryBitMask == PhysicsCategory.bubble {
                bodyB.node?.removeFromParent()
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
        
            // Remove existing gesture recognizers before restarting the game
            removeAllGestureRecognizers()
        let newScene = OEGameScene(context: context!, size: size)
        newScene.scaleMode = .aspectFill
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
    }
}
