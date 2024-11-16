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
    let speed: CGFloat
    let laneType: String // Empty, Normal, Tutorial, Eel, or Pufferfish
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
    var airAmount = 26
  
    var airLabel: SKLabelNode!
    var airIcon: SKSpriteNode!
    
    // Game state variable
    var isGameOver = false
    var lanes: [Lane] = []  // Added this line to define lanes
    var laneDirection = 0
    
    var playableWidthRange: ClosedRange<CGFloat> {
        return ((-size.width / 2) + cellWidth)...((size.width / 2) - cellWidth)
    }
    
    var viewableHeightRange: ClosedRange<CGFloat> {
        guard let boxPositionY = box?.position.y else { return 0...0 }
        return (boxPositionY - cellHeight * 3)...(boxPositionY + cellHeight * 3)
    }
    
    var yPositionLanes: CGFloat = 0
    var numberOfRows: Int = 0
    var numberOfColumns: Int = 0
    var cellWidth: CGFloat = 0
    var cellHeight: CGFloat = 0
    
    var highestRowDrawn: Int = 13 // Track the highest row drawn for grid

    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)

        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.cameraNode = SKCameraNode()
        self.camera = cameraNode
        
        // Creating grid
        numberOfRows = 13
        numberOfColumns = 7
        cellWidth = size.width / CGFloat(numberOfColumns)
        cellHeight = size.height / CGFloat(numberOfRows)
        
        let laneHeight = cellHeight
        
        var i = 0
        while i < numberOfRows {
            while i < 4 {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                lanes.append(Lane(startPosition: CGPoint(x: 0, y: yPosition), endPosition: CGPoint(x: 0, y: 0), direction: CGVector(dx: 1, dy: 0), speed: 0, laneType: "Empty"))
                yPositionLanes = yPosition
                i += 1
            }
                    
            // 1 enemy at a time
            if i == 4 {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                let leftStart = CGPoint(x: -size.width, y: yPosition)
                let rightStart = CGPoint(x: size.width, y: yPosition)
                lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: 8.0, laneType: "Tutorial"))
                yPositionLanes = yPosition
                i += 1
            }
            
            // Gap
            if i == 5 {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                lanes.append(Lane(startPosition: CGPoint(x: 0, y: yPosition), endPosition: CGPoint(x: 0, y: 0), direction: CGVector(dx: 1, dy: 0), speed: 0, laneType: "Empty"))
                yPositionLanes = yPosition
                i += 1
            }

            // 2 enemies at a time
            while i < 8 {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                let leftStart = CGPoint(x: -size.width, y: yPosition)
                let rightStart = CGPoint(x: size.width, y: yPosition)
                if i == 6 {
                    lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: 9.0, laneType: "Tutorial"))
                } else {
                    lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: 7.0, laneType: "Tutorial"))
                }
                yPositionLanes = yPosition
                i += 1
            }
            
            // Gap
            while i < 10 {
                for _ in i...i + 1 {
                    let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                    lanes.append(Lane(startPosition: CGPoint(x: 0, y: yPosition), endPosition: CGPoint(x: 0, y: 0), direction: CGVector(dx: 1, dy: 0), speed: 0, laneType: "Empty"))
                    yPositionLanes = yPosition
                    i += 1
                }
            }
            
            // Pufferfish
            while i == 10 {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                let leftStart = CGPoint(x: -size.width, y: yPosition)
                let rightStart = CGPoint(x: size.width, y: yPosition)
                lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: 5.0, laneType: "Pufferfish"))
                yPositionLanes = yPosition
                i += 1
            }
            
            // Number of empty lanes in a row
            let numberOfEmptyRows = Int.random(in: 1...3)
            
            for _ in i...i + numberOfEmptyRows {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                lanes.append(Lane(startPosition: CGPoint(x: 0, y: yPosition), endPosition: CGPoint(x: 0, y: 0), direction: CGVector(dx: 1, dy: 0), speed: 0, laneType: "Empty"))
                yPositionLanes = yPosition
                i += 1
            }

            // Number of lanes in a row with enemies
            let numberOfEnemyRows = Int.random(in: 1...5)
            
            for _ in i...i + numberOfEnemyRows {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                let leftStart = CGPoint(x: -size.width, y: yPosition)
                let rightStart = CGPoint(x: size.width, y: yPosition)

                // Random directions for lanes
                laneDirection = Int.random(in: 0..<2)
                
                if laneDirection == 0 {
                    lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: CGFloat.random(in: 7..<10), laneType: "Normal"))
                } else {
                    lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: CGFloat.random(in: 7..<10), laneType: "Normal"))
                }
                yPositionLanes = yPosition
                i += 1
            }
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
        
        drawGridLines()
        
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
        let moveUp = SKAction.moveBy(x: 0, y: size.height, duration: 25.0) // Adjust duration as needed CAMERA SPEED GOING UP
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
        box?.position = positionFor(row: 0, column: 0)
        if let box = box {
            addChild(box)
        }
    }

    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "SF Mono")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 1000
        scoreLabel.position = CGPoint(x: -size.width / 2 + 20, y: size.height / 2 - 75)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.text = "\(score)"
        cameraNode.addChild(scoreLabel)
    }

    func updateScore() {
        score += 1
        if score % 10 == 0 {
                    scoreLabel.fontColor = .yellow
                } else {
                    scoreLabel.fontColor = .white
                }
        scoreLabel.text = "\(score)"
    }
    
    func updateHighestRowDrawn() {
        highestRowDrawn += numberOfRows
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let box = box else { return }

        // 1. Continuous upward movement for the camera
        cameraNode.position.y += 0 // Adjust this value for camera speed

        // 2. Check if the character is above a certain threshold relative to the camera's view
        let characterAboveThreshold = box.position.y > cameraNode.position.y + size.height / 4 // Adjust threshold as desired

        if characterAboveThreshold {
            // Move the camera up to match the character's y position while maintaining continuous movement
            cameraNode.position.y = box.position.y - size.height / 4
        }

        // 3. Existing functionality: Draw new rows if the camera has moved past the highest drawn row
        if (cameraNode.position.y + size.height / 2) >= CGFloat(highestRowDrawn) * cellHeight / 4 {
            drawNewGridRows()
            updateHighestRowDrawn()
        }

        // 4. Update background tiles
        updateBackgroundTiles()

        // 5. Check for proximity to player for each pufferfish enemy
        for child in children {
            if let pufferfish = child as? OEEnemyNode2 {
                pufferfish.checkProximityToPlayer(playerPosition: box.position)
            }
        }

        // 6. Game over if the character falls below the camera's view
        if box.position.y < cameraNode.position.y - size.height / 2 {
            gameOver()
        }
    }

    func updateBackgroundTiles() {
        guard let box else { return }

        let thresholdY = cameraNode.position.y + size.height / 2
        if let lastTile = backgroundTiles.last, lastTile.position.y < thresholdY {
            addBackgroundTile(at: CGPoint(x: 0, y: lastTile.position.y + size.height))
            // generate new lanes
            generateNewLanes(startingAt: yPositionLanes, numberOfLanes: numberOfRows)
        }

        backgroundTiles = backgroundTiles.filter { tile in
            if tile.position.y < cameraNode.position.y - size.height {
                tile.removeFromParent()
                return false
            }
            return true
        }
    }
    
    func positionFor(row: Int, column: Int) -> CGPoint {
        let x = CGFloat(column) * cellWidth + cellWidth / 2
        let y = CGFloat(row) * cellHeight + cellHeight / 2
        return CGPoint(x: x, y: y)
    }

    func drawGridLines() {
        // Horizontal lines
        for row in 0...numberOfRows {
            let yPosition = CGFloat(row) * cellHeight - size.height / 2 - cellHeight / 2
            let startPoint = CGPoint(x: -size.width, y: yPosition)
            let endPoint = CGPoint(x: size.width, y: yPosition)
            
            let horizontalLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            horizontalLine.path = path
            horizontalLine.strokeColor = .white  // Set color of grid lines
            horizontalLine.lineWidth = 1.0
            horizontalLine.alpha = 0.55 // OPACITY OF LINES
            
            addChild(horizontalLine)
        }
        
        // Vertical lines
        for column in 0...numberOfColumns {
            let xPosition = CGFloat(column) * cellWidth - size.width / 2 - cellWidth / 2
            let startPoint = CGPoint(x: xPosition, y: -size.height)
            let endPoint = CGPoint(x: xPosition, y: size.height)
            
            let verticalLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            verticalLine.path = path
            verticalLine.strokeColor = .white  // Set color of grid lines
            verticalLine.lineWidth = 1.0
            verticalLine.alpha = 0.55 // OPACITY OF LINES
            
            addChild(verticalLine)
        }
    }
    
    func drawNewGridRows() {
        // Draw new horizontal lines for rows above the current grid
        for row in (highestRowDrawn)...(highestRowDrawn + numberOfRows) {
            let yPosition = CGFloat(row) * cellHeight - size.height / 2 - cellHeight / 2
            let horizontalLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size.width, y: yPosition))
            path.addLine(to: CGPoint(x: size.width, y: yPosition))
            horizontalLine.path = path
            horizontalLine.strokeColor = .white
            horizontalLine.lineWidth = 1.0
            
            addChild(horizontalLine)
        }

        // Extend the vertical lines for the new height of the grid
        for column in 0...numberOfColumns {
            let xPosition = CGFloat(column) * cellWidth - size.width / 2 - cellWidth / 2
            let startPoint = CGPoint(x: xPosition, y: CGFloat(highestRowDrawn) * cellHeight)
            let endPoint = CGPoint(x: xPosition, y: CGFloat(highestRowDrawn + numberOfRows) * cellHeight)
            
            let verticalLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            verticalLine.path = path
            verticalLine.strokeColor = .white
            verticalLine.lineWidth = 1.0

            addChild(verticalLine)
        }
    }
    

    func gridPosition(for position: CGPoint) -> (row: Int, column: Int) {
        let row = Int(position.y / cellHeight)
        let column = Int(position.x / cellWidth)
        return (row, column)
    }
    
    func generateNewLanes(startingAt yPosition: CGFloat, numberOfLanes: Int) {
        var newLanes: [Lane] = []
        let laneHeight = cellHeight
        
        var i = 0
        while i < numberOfRows {
            
            // Number of empty lanes in a row
            let numberOfEmptyRows = Int.random(in: 1...3)
            
            for _ in i...i + numberOfEmptyRows {
                let newYPosition = yPosition + CGFloat(i + 1) * laneHeight
                newLanes.append(Lane(startPosition: CGPoint(x: 0, y: newYPosition), endPosition: CGPoint(x: 0, y: 0), direction: CGVector(dx: 1, dy: 0), speed: 0, laneType: "Empty"))
                yPositionLanes = newYPosition
                i += 1
            }
            
            // Number of lanes in a row with enemies
            let numberOfEnemyRows = Int.random(in: 2...5)
            
            for _ in i...i + numberOfEnemyRows {
                let newYPosition = yPosition + CGFloat(i + 1) * laneHeight 
                let leftStart = CGPoint(x: -size.width, y: newYPosition)
                let rightStart = CGPoint(x: size.width, y: newYPosition)
                
                // 1/20 chance to spawn eel
                let eelSpawn = Int.random(in: 0..<21)
                let laneType: String
                
                if eelSpawn == 20 {
                    laneType = "Eel"
                } else {
                    laneType = "Normal"
                }
                
                // Random directions for lanes
                laneDirection = Int.random(in: 0..<2)
                
                if laneDirection == 0 {
                    newLanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: CGFloat.random(in: 7..<10) - 2 * CGFloat(score) / 5, laneType: laneType))
                } else {
                    newLanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: CGFloat.random(in: 7..<10) - 2 * CGFloat(score) / 5, laneType: laneType))
                }
                yPositionLanes = newYPosition
                i += 1
            }
        }
        startSpawning(lanes: newLanes)
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
        let nextPosition = CGPoint(x: box.position.x, y: box.position.y + cellHeight)
        moveBox(to: nextPosition)
        updateScore()
    }

    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard let box, !isGameOver else { return }

        let nextPosition: CGPoint
        switch sender.direction {
        case .up:
            nextPosition = CGPoint(x: box.position.x, y: box.position.y + cellHeight)
        case .down:
            nextPosition = CGPoint(x: box.position.x, y: box.position.y - cellHeight)
        case .left:
            nextPosition = CGPoint(x: max(box.position.x - cellWidth, playableWidthRange.lowerBound), y: box.position.y)
        case .right:
            nextPosition = CGPoint(x: min(box.position.x + cellWidth, playableWidthRange.upperBound), y: box.position.y)
        default:
            return
        }
        moveBox(to: nextPosition)
    }

    func moveBox(to position: CGPoint) {
        box?.move(to: position)
    }

    func spawnEnemy(in lane: Lane) {
        let enemy = OEEnemyNode(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
    }
    
    func spawnPufferfish(in lane: Lane) {
        let enemy = OEEnemyNode2(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
    }

    func spawnLongEnemy(in lane: Lane) {
        let enemy = OEEnemyNode3(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition)
    }
    
    func warn(in lane: Lane) {
        let warningLabel = SKLabelNode()
        warningLabel.fontColor = .red
        warningLabel.text = "WARNING"
        warningLabel.fontSize = 30
        warningLabel.position = CGPoint(x: 0.0, y: lane.startPosition.y)
        addChild(warningLabel)
        let wait = SKAction.wait(forDuration: 3.0)
        let removeWarning = SKAction.removeFromParent()
        warningLabel.run(SKAction.sequence([wait, removeWarning]))
    }
    
    func startSpawning(lanes: [Lane]) {
      
        for lane in lanes {
            
            if lane.laneType == "Empty" {
                colorLane(in: lane)
            }
            
            if lane.laneType == "Tutorial" {
                let wait = SKAction.wait(forDuration: 5.0)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnEnemy(in: lane)
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lane.laneType == "Eel" {
                colorLane(in: lane)
                let wait = SKAction.wait(forDuration: CGFloat.random(in: 12...20))
                let warn = SKAction.run { [weak self] in
                    self?.warn(in: lane)
                }
                let spawn = SKAction.run { [weak self] in
                    self?.spawnLongEnemy(in: lane)
                }
                let sequence = SKAction.sequence([wait, warn, spawn])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lane.laneType == "Pufferfish" {
                let wait = SKAction.wait(forDuration: 4.0)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnPufferfish(in: lane)
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lane.laneType == "Normal" {
                let wait = SKAction.wait(forDuration: CGFloat.random(in: 3.5..<5.5) - CGFloat(score) / 20)
                let spawn = SKAction.run { [weak self] in
                    let enemyType = Int.random(in: 0..<8)
                    if enemyType == 7 {
                        self?.spawnPufferfish(in: lane)
                    } else {
                        self?.spawnEnemy(in: lane)
                    }
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
        }
    }
      
    // Color lanes that are empty or eel type
    func colorLane(in lane: Lane) {
        let laneColor = SKShapeNode(rect: CGRect(x: -size.width, y: lane.startPosition.y - cellHeight / 2, width: size.width * 2, height: cellHeight))
        if lane.laneType == "Empty" {
            laneColor.fillColor = .cyan
        }
        else {
            laneColor.fillColor = .yellow
        }
        laneColor.alpha = 0.5
        laneColor.zPosition = 0
        addChild(laneColor)
        print("Lane position: \(lane.startPosition.y)")
    }
    
    // Function to spawn the bubbles randomly in grid spaces
    func spawnBubble() {
        
        // Create the bubble asset
        let bubble = SKSpriteNode(imageNamed: "Bubble") // Use your bubble asset
        bubble.size = CGSize(width: 45, height: 45) // Adjust size as needed
        bubble.alpha = 0.6 // Set the opacity (0.0 to 1.0, where 0.5 is 50% opacity)
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: bubble.size.width / 2.2)
        bubble.physicsBody?.categoryBitMask = PhysicsCategory.bubble
        bubble.physicsBody?.contactTestBitMask = PhysicsCategory.box
        bubble.physicsBody?.collisionBitMask = PhysicsCategory.none
        bubble.physicsBody?.isDynamic = false
        
        // Used to find the column range to place the bubble in randomly
        let columns = Int(size.width / cellWidth)
        let playableColumnRange = ((-columns / 2) + 1)...((columns / 2) - 1)
        
        // Used to find the row range to place the bubble in randomly
        guard let box = box else { return }
        
        // Getting the curr row and column of the box/player using gridPosition funct
        let currPosition = gridPosition(for: box.position)
        let currRow = currPosition.row  // This is the curr row the player is on
        
        // Create a row range for bubble to be placed randomly
        let min = currRow - 2
        let max = currRow + 4
        let playableRowRange = min...max
        
        // Now get a random row and column for the bubble to spawn in
        let randomRow = Int.random(in: playableRowRange)
        let randomColumn = Int.random(in: playableColumnRange)
        
        // Set the bubble position
        bubble.position = positionFor(row: randomRow, column: randomColumn)
        
        addChild(bubble)
    }

    func includeBubbles() {
        let bubbleSpawnAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnBubble()
                },
                SKAction.wait(forDuration: 5) // Adjust spawn frequency
            ])
        )
        run(bubbleSpawnAction, withKey: "spawnBubbles")
    }

    func setupAirDisplay() {
        airIcon = SKSpriteNode(imageNamed: "Bubble")
        airIcon.size = CGSize(width: 30, height: 30)
        airIcon.position = CGPoint(x: size.width / 2 - 60, y: size.height / 2 - 70)
        airIcon.zPosition = 1000
        cameraNode.addChild(airIcon)

        airLabel = SKLabelNode(fontNamed: "SF Mono")
        airLabel.fontSize = 32
        airLabel.fontColor = .white
        airLabel.zPosition = 1000
        airLabel.position = CGPoint(x: airIcon.position.x - 20, y: airIcon.position.y - 10)
        airLabel.horizontalAlignmentMode = .right
        airLabel.text = "\(airAmount)"
        cameraNode.addChild(airLabel)
    }

    // Continuously decreases air during game
    func airCountDown() {
        let countdownAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.decreaseAir()
                },
                SKAction.wait(forDuration: 1)
            ])
        )
        run(countdownAction, withKey: "airCountdown")
    }

    // Function to decrease air by 1 (called in aircountdown)
    func decreaseAir() {
        guard !isGameOver else { return }
        
        if airAmount < 17 {
            airLabel.fontColor = .red
            } else {
                airLabel.fontColor = .white
            }
        
        if airAmount > 0 {
            airAmount -= 1
            airLabel.text = "\(airAmount)"
        } else {
            gameOver()
        }
    }
    
    // Function to increase air by 5 when player gets bubble
    func increaseAir() {
        guard !isGameOver else { return }
        
        if airAmount < 20 {
            airAmount += 5
            airLabel.text = "\(airAmount)"
        } else if airAmount >= 20 && airAmount <= 25 {
            airAmount = 25
            airLabel.text = "\(airAmount)"
        }
    }
    
    // Handles player contact with bubbles and enemies
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
        cameraNode.removeAllActions() // Stop camera movement
        removeAction(forKey: "spawnEnemies") // Stop spawning enemies
        
        // Save the current score
        let finalScore = score
        
        // Reset the score display (but keep the score variable intact for now)
        scoreLabel.text = "\(score)"
        
        let gameOverLabel = SKLabelNode(text: "Game Over!")
        gameOverLabel.fontSize = 48
        gameOverLabel.zPosition = 1000 //MAKE TEXT BE TOP VISIBLE LAYER
        gameOverLabel.fontColor = .red
        gameOverLabel.fontName = "Arial-BoldMT" // Use bold font
        gameOverLabel.position = CGPoint(x: 0, y: 100) // Center on screen
        cameraNode.addChild(gameOverLabel)

        // Display Final Score
        let finalScoreLabel = SKLabelNode(text: "Score: \(finalScore)")
        finalScoreLabel.fontSize = 32
        finalScoreLabel.fontColor = .white
        finalScoreLabel.zPosition = 1000 //MAKE TEXT BE TOP VISIBLE LAYER
        finalScoreLabel.fontName = "Arial-BoldMT" // Use bold font
        finalScoreLabel.position = CGPoint(x: 0, y: 50) // Positioned just below the "Game Over" text
        cameraNode.addChild(finalScoreLabel)

        // Display "Tap to Restart" message
        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 28
        restartLabel.fontColor = .yellow
        restartLabel.zPosition = 1000 //MAKE TEXT BE TOP VISIBLE LAYER
        restartLabel.fontName = "Arial" // Use bold font
        restartLabel.position = CGPoint(x: 0, y: 0) // Positioned below the final score
        cameraNode.addChild(restartLabel)

        
        // Pause the scene to stop further actions
        self.isPaused = true
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            restartGame()
        }
    }

    func restartGame() {
        // Clear all nodes and actions from the current scene
        removeAllActions()
        removeAllChildren()
        
        // Reset the game state
        isGameOver = false
        score = 0
        airAmount = 26

        // Load a new instance of the scene
        let newScene = OEGameScene(context: context!, size: size)
        newScene.scaleMode = .aspectFill
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
    }

}
