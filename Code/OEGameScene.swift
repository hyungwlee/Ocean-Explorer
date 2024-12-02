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
    static let shell: UInt32 = 0b1000
}

struct Lane {
    let startPosition: CGPoint
    let endPosition: CGPoint
    let direction: CGVector
    let speed: CGFloat
    let laneType: String // Empty, Normal, Tutorial, Eel, Pufferfish, Long, or Jelly
}

// Collection of easy sets of lanes
let easySets: [[String]] = [
    ["Jellyfish", "Jellyfish", "Jellyfish"],
    ["Jellyfish", "Long", "Jellyfish"],
    ["Jellyfish"],
    ["Long"],
    ["Jellyfish"],
    ["Jellyfish", "Normal"],
    ["Jellyfish", "Jellyfish"],
    ["Eel"],
    ["Eel", "Jellyfish"],
    ["Jellyfish", "Normal", "Long"],
    ["Normal", "Jellyfish", "Jellyfish"]
]

// Collection of medium sets of lanes
let mediumSets: [[String]] = [
    ["Eel", "Eel", "Jellyfish"],
    ["Long", "Long", "Normal"],
    ["Jellyfish", "Jellyfish", "Eel", "Eel"],
    ["Normal", "Jellyfish", "Jellyfish", "Jellyfish", "Jellyfish"],
    ["Long", "Normal", "Long"],
    ["Normal", "Jellyfish", "Jellyfish", "Normal"],
    ["Jellyfish", "Long", "Jellyfish", "Jellyfish", "Long"],
    ["Normal", "Eel", "Jellyfish", "Long"],
    ["Eel", "Normal", "Eel"]
]

// Collection of hard sets of lanes
let hardSets: [[String]] = [
    ["Jellyfish", "Jellyfish", "Normal", "Eel", "Eel"],
    ["Normal", "Eel", "Eel", "Eel"],
    ["Eel", "Long", "Jellyfish", "Jellyfish", "Eel"],
    ["Jellyfish", "Normal", "Normal", "Long", "Jellyfish", "Jellyfish", "Jellyfish", "Jellyfish"],
    ["Jellyfish", "Jellyfish", "Normal", "Eel", "Eel", "Eel", "Long"],
    ["Jellyfish", "Normal", "Jellyfish", "Normal", "Normal", "Long", "Jellyfish", "Eel", "Jellyfish"],
    ["Normal", "Pufferfish", "Normal"]
]
    
class OEGameScene: SKScene, SKPhysicsContactDelegate {
    weak var context: OEGameContext?
    var box: OEBoxNode?
    var cameraNode: SKCameraNode!

    let gridSize = CGSize(width: 50, height: 50)
    var backgroundTiles: [SKSpriteNode] = []
  
    // Score properties
    var score = 0
    var scoreDisplayed = 0
    var scoreLabel: SKLabelNode!
    
    // Air properties
    var airAmount = 21
    var airLabel: SKLabelNode!
    var airIcon: SKSpriteNode!
    var firstBubble: SKSpriteNode? = nil
    var arrow: SKSpriteNode?
    var bubbleText: SKLabelNode?
    
    // Tapping properties
    var tapQueue: [CGPoint] = [] // Queue to hold pending tap positions
    var isActionInProgress = false // Flag to indicate if a movement is in progress

    
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
    
    var highestRowDrawn: Int = 15 // Track the highest row drawn for grid

    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)

        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.cameraNode = SKCameraNode()
        self.camera = cameraNode
        
        // Creating grid
        numberOfRows = 15
        numberOfColumns = 9
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
                    lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: 9.0, laneType: "Long"))
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
            let chanceOfEmptyRows = Int.random(in: 1...10)
            var numberOfEmptyRows: Int = 0
            
            if chanceOfEmptyRows > 3 {
                numberOfEmptyRows = 1
            }
            else {
                numberOfEmptyRows = 2
            }

            for _ in i...i + numberOfEmptyRows {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                lanes.append(Lane(startPosition: CGPoint(x: 0, y: yPosition), endPosition: CGPoint(x: 0, y: 0), direction: CGVector(dx: 1, dy: 0), speed: 0, laneType: "Empty"))
                yPositionLanes = yPosition
                i += 1
            }
            
            // Difficulty of lanes based on score
            var chanceOfEasyLanes = 0
            var chanceOfMediumLanes = 0
            var laneDifficulty: [[String]]
            
            if score < 25 {
                chanceOfEasyLanes = 7
                chanceOfMediumLanes = 10
            }
            else if score < 50 {
                chanceOfEasyLanes = 4
                chanceOfMediumLanes = 8
            }
            else {
                chanceOfEasyLanes = 0
                chanceOfMediumLanes = 4
            }
            
            let chanceOfLaneType = Int.random(in: 1...10)
            
            if (chanceOfLaneType <= chanceOfEasyLanes) {
                laneDifficulty = easySets
            }
            else if (chanceOfLaneType <= chanceOfMediumLanes) {
                laneDifficulty = mediumSets
            }
            else {
                laneDifficulty = hardSets
            }
            
            let laneSet = Int.random(in: 0...laneDifficulty.count - 1)
            var lane = 0
            for _ in i...i + laneDifficulty[laneSet].count - 1 {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                let leftStart = CGPoint(x: -size.width, y: yPosition)
                let rightStart = CGPoint(x: size.width, y: yPosition)
                
                // Random directions for lanes
                laneDirection = Int.random(in: 0..<2)
                
                if laneDirection == 0 {
                    lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: CGFloat.random(in: 7...13), laneType: laneDifficulty[laneSet][lane]))
                } else {
                    lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: CGFloat.random(in: 7...13), laneType: laneDifficulty[laneSet][lane]))
                }
                yPositionLanes = yPosition
                i += 1
                lane += 1
            }
            /*
            // Number of lanes in a row with enemies
            let chanceOfEnemyRows = Int.random(in: 1...20)
            var numberOfEnemyRows: Int = 0
            
            if chanceOfEnemyRows > 13 {
                numberOfEnemyRows = 3
            }
            else if chanceOfEnemyRows > 4 {
                numberOfEnemyRows = 2
            }
            else if chanceOfEnemyRows > 2 {
                numberOfEnemyRows = 1
            }
            else if chanceOfEnemyRows == 2 {
                numberOfEnemyRows = 4
            }
            else {
                numberOfEnemyRows = 5
            }
            
            for _ in i...i + numberOfEnemyRows {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                let leftStart = CGPoint(x: -size.width, y: yPosition)
                let rightStart = CGPoint(x: size.width, y: yPosition)

                // Random directions for lanes
                laneDirection = Int.random(in: 0..<2)
                
                // Random chance for longer enemies
                let enemySize: String
                let enemySpeed: CGFloat
                
                let enemySizeChance = Int.random(in: 0...4)
                if enemySizeChance == 0 {
                    enemySize = "Long"
                    enemySpeed = CGFloat.random(in: 10..<13)
                }
                else if enemySizeChance == 1 {
                    enemySize = "Jellyfish"
                    enemySpeed = CGFloat.random(in: 8.5..<11.5)
                }
                else {
                    enemySize = "Normal"
                    enemySpeed = CGFloat.random(in: 7..<10)
                }
                
                if laneDirection == 0 {
                    lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: enemySpeed, laneType: enemySize))
                } else {
                    lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: enemySpeed, laneType: enemySize))
                }
                yPositionLanes = yPosition
                i += 1
            }
             */
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
        
        //drawGridLines()
        
        // Start timed enemy spawning
        startSpawning(lanes: lanes)

        // Initialize and set up score label
        setupScoreLabel()
        setupAirDisplay()
        airCountDown()
        includeBubbles()
        includeShells()
        spawnTemporaryArrow()

        startCameraMovement()
    }

    func startCameraMovement() {
      
        let moveUp = SKAction.moveBy(x: 0, y: size.height, duration: 15.0) // Adjust duration as needed CAMERA SPEED GOING UP

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

        // Add reef to the scene
        setupReef()
    }

    func setupReef() {
        let reef = SKSpriteNode(imageNamed: "Reef")
        
        // Adjust position as needed
        reef.position = CGPoint(x: size.width / 350, y: reef.size.height / 20 - 100)
        reef.zPosition = 10
        
        // Scale the width by increasing xScale
        reef.xScale = 1.15 // Adjust the scale factor as needed for more width
        
        addChild(reef)
        // Create a fade-out action
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([SKAction.wait(forDuration: 4.0), fadeOut, remove])
        reef.run(sequence)
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
        scoreLabel.fontSize = 75
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 1000
        scoreLabel.position = CGPoint(x: -size.width / 2 + 170, y: size.height / 2 - 125)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.text = "\(score)"
        cameraNode.addChild(scoreLabel)
    }

    let goldColor = UIColor(red: 255/255.0, green: 223/255.0, blue: 87/255.0, alpha: 1.0) // Lighter gold
    
    func updateScore() {
        score += 1
        if score >= scoreDisplayed + 1 {
            scoreDisplayed += 1
        }
        
        if score % 100 == 0 {
            scoreLabel.fontColor = .red // Gold color
        } else if score % 10 == 0 {
            scoreLabel.fontColor = goldColor
            scoreLabel.run(createPopOutAction()) // Apply the popping effect on multiples of 10
        } else {
            scoreLabel.fontColor = .white
        }
        scoreLabel.text = "\(max(score, scoreDisplayed))"
    }

    func createPopOutAction() -> SKAction {
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        return sequence
    }
    
    func updateHighestRowDrawn() {
        highestRowDrawn += numberOfRows
    }
    
//    override func update(_ currentTime: TimeInterval) {
//        guard let box = box else { return }
//
//        // 1. Continuous upward movement for the camera
//        cameraNode.position.y += 0 // Adjust this value for camera speed
//
//        // 2. Check if the character is above a certain threshold relative to the camera's view
//
//        let characterAboveThreshold = box.position.y > cameraNode.position.y  // Adjust threshold as desired
//
//        if characterAboveThreshold {
//            // Move the camera up to match the character's y position while maintaining continuous movement
//            cameraNode.position.y = box.position.y 
//        }
//
//        // 3. Existing functionality: Draw new rows if the camera has moved past the highest drawn row
//        if (cameraNode.position.y + size.height / 2) >= CGFloat(highestRowDrawn) * cellHeight / 4 {
//            drawNewGridRows()
//            updateHighestRowDrawn()
//        }
//
//        // 4. Update background tiles
//        updateBackgroundTiles()
//
//        // 5. Check for proximity to player for each pufferfish enemy
//        for child in children {
//            if let pufferfish = child as? OEEnemyNode2 {
//                pufferfish.checkProximityToPlayer(playerPosition: box.position)
//            }
//        }
//
//        // 6. Game over if the character falls below the camera's view
//        if box.position.y < cameraNode.position.y - size.height / 2 {
//            gameOver()
//        }
//    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let box = box else { return }

        // Smoothly move the camera towards the box's position with slower forward movement
        let lerpFactor: CGFloat = 0.018 // Smaller value for slower camera movement
        let targetY = max(cameraNode.position.y, box.position.y) // Ensure the camera only moves forward
        cameraNode.position.y += (targetY - cameraNode.position.y) * lerpFactor

        // Draw new rows if the camera has moved past the highest drawn row
        if (cameraNode.position.y + size.height / 2) >= CGFloat(highestRowDrawn) * cellHeight / 4 {
            //drawNewGridRows()
            updateHighestRowDrawn()
        }

        // Update background tiles
        updateBackgroundTiles()

        // Check for proximity to player for each pufferfish enemy
        for child in children {
            if let pufferfish = child as? OEEnemyNode2 {
                pufferfish.checkProximityToPlayer(playerPosition: box.position)
            }
        }

        // Game over if the character falls below the camera's view
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
/*
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
    
*/
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
            let chanceOfEmptyRows = Int.random(in: 1...10)
            var numberOfEmptyRows: Int = 0
            
            if chanceOfEmptyRows > 3 {
                numberOfEmptyRows = 1
            }
            else {
                numberOfEmptyRows = 2
            }
            
            for _ in i...i + numberOfEmptyRows {
                let newYPosition = yPosition + CGFloat(i + 1) * laneHeight
                newLanes.append(Lane(startPosition: CGPoint(x: 0, y: newYPosition), endPosition: CGPoint(x: 0, y: 0), direction: CGVector(dx: 1, dy: 0), speed: 0, laneType: "Empty"))
                yPositionLanes = newYPosition
                i += 1
            }
            
            
            // Difficulty of lanes based on score
            var chanceOfEasyLanes = 0
            var chanceOfMediumLanes = 0
            var laneDifficulty: [[String]]
            
            if score < 25 {
                chanceOfEasyLanes = 7
                chanceOfMediumLanes = 10
            }
            else if score < 50 {
                chanceOfEasyLanes = 4
                chanceOfMediumLanes = 8
            }
            else {
                chanceOfEasyLanes = 0
                chanceOfMediumLanes = 4
            }
            
            let chanceOfLaneType = Int.random(in: 1...10)
            
            if (chanceOfLaneType <= chanceOfEasyLanes) {
                laneDifficulty = easySets
            }
            else if (chanceOfLaneType <= chanceOfMediumLanes) {
                laneDifficulty = mediumSets
            }
            else {
                laneDifficulty = hardSets
            }
            
            let laneSet = Int.random(in: 0...laneDifficulty.count - 1)
            var lane = 0
            for _ in i...i + laneDifficulty[laneSet].count - 1 {
                let newYPosition = yPosition + CGFloat(i + 1) * laneHeight
                let leftStart = CGPoint(x: -size.width, y: newYPosition)
                let rightStart = CGPoint(x: size.width, y: newYPosition)
                
                // Random directions for lanes
                laneDirection = Int.random(in: 0..<2)
                
                if laneDirection == 0 {
                    newLanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: CGFloat.random(in: 7...13), laneType: laneDifficulty[laneSet][lane]))
                } else {
                    newLanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: CGFloat.random(in: 7...13), laneType: laneDifficulty[laneSet][lane]))
                }
                yPositionLanes = newYPosition
                i += 1
                lane += 1
            }
            /*
            // Number of lanes in a row with enemies
            let chanceOfEnemyRows = Int.random(in: 1...20)
            var numberOfEnemyRows: Int = 0
            
            if chanceOfEnemyRows > 13 {
                numberOfEnemyRows = 3
            }
            else if chanceOfEnemyRows > 4 {
                numberOfEnemyRows = 2
            }
            else if chanceOfEnemyRows > 2 {
                numberOfEnemyRows = 1
            }
            else if chanceOfEnemyRows == 2 {
                numberOfEnemyRows = 4
            }
            else {
                numberOfEnemyRows = 5
            }
            
            for _ in i...i + numberOfEnemyRows {
                let newYPosition = yPosition + CGFloat(i + 1) * laneHeight 
                let leftStart = CGPoint(x: -size.width, y: newYPosition)
                let rightStart = CGPoint(x: size.width, y: newYPosition)
                
                // 1/20 chance to spawn eel
                let eelSpawn = Int.random(in: 0..<21)
                let laneType: String
                let laneSpeed: CGFloat
                
                if eelSpawn == 20 {
                    laneType = "Eel"
                    laneSpeed = 0.0
                }
                else if eelSpawn > 16 {
                    laneType = "Long"
                    laneSpeed = CGFloat.random(in: 10..<13)
                }
                else if eelSpawn > 12 {
                    laneType = "Jellyfish"
                    laneSpeed = CGFloat.random(in: 8.5..<11.5)
                }
                else {
                    laneType = "Normal"
                    laneSpeed = CGFloat.random(in: 7..<10)
                }
                
                // Random directions for lanes
                laneDirection = Int.random(in: 0..<2)
                
                if laneDirection == 0 {
                    newLanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: max(laneSpeed - 2 * CGFloat(score) / 5, 3.0), laneType: laneType))
                } else {
                    newLanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: max(laneSpeed - 2 * CGFloat(score) / 5, 3.0), laneType: laneType))
                }
                yPositionLanes = newYPosition
                i += 1
            }
             */
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
        // If an action is already in progress, queue the next tap position
        if isActionInProgress {
            tapQueue.append(nextPosition)
        } else {
            // Execute immediately if no action is in progress
            moveBox(to: nextPosition)
        }
    }

    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard let box, !isGameOver else { return }

        let nextPosition: CGPoint
        switch sender.direction {
        case .up:
            nextPosition = CGPoint(x: box.position.x, y: box.position.y + cellHeight)
        case .down:
            nextPosition = CGPoint(x: box.position.x, y: box.position.y - cellHeight)
            score -= 1
        case .left:
            nextPosition = CGPoint(x: max(box.position.x - cellWidth, playableWidthRange.lowerBound), y: box.position.y)
        case .right:
            nextPosition = CGPoint(x: min(box.position.x + cellWidth, playableWidthRange.upperBound), y: box.position.y)
        default:
            return
        }
        moveBox(to: nextPosition)
    }

//    func moveBox(to position: CGPoint) {
//        if position.y > box?.position.y ?? 0 {
//            if box?.move(to: position) == 1 {
//                updateScore()
//            }
//        }
//        else {
//            box?.move(to: position)
//        }
//    }
    
    func moveBox(to position: CGPoint) {
        guard let box else { return }
        
        // Set the flag to indicate movement in progress
        isActionInProgress = true
        
        // Example movement logic using an animation
        UIView.animate(withDuration: 0.3, animations: {
            box.position = position
        }) { [weak self] _ in
            guard let self = self else { return }
            
            // Mark the current action as completed
            self.isActionInProgress = false

            
            // If there are more actions in the queue, execute the next one
            if let nextPosition = self.tapQueue.first {
                self.tapQueue.removeFirst()
                self.moveBox(to: nextPosition)
                // Update the score
                updateScore()
            }
        }
    }

    func spawnEnemy(in lane: Lane) {
        let enemy = OEEnemyNode(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
    }
    
    func spawnJellyfish(in lane: Lane) {
        let enemy = OEEnemyNode5(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
    }
    
    func spawnLongEnemy(in lane: Lane) {
        let enemy = OEEnemyNode4(gridSize: gridSize)
        addChild(enemy)
        if lane.direction == CGVector(dx: -1, dy: 0) {
            enemy.xScale = -1
        }
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
    }
    
    func spawnPufferfish(in lane: Lane) {
        let enemy = OEEnemyNode2(gridSize: gridSize)
        addChild(enemy)
        if lane.direction == CGVector(dx: -1, dy: 0) {
            enemy.xScale = -1
        }
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
    }

    func spawnEel(in lane: Lane) {
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
                    self?.spawnEel(in: lane)
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
                let wait = SKAction.wait(forDuration: CGFloat.random(in: 4..<5.5))
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
            
            if lane.laneType == "Jellyfish" {
                let wait = SKAction.wait(forDuration: CGFloat.random(in: 3.5..<5.5))
                let spawn = SKAction.run { [weak self] in
                    self?.spawnJellyfish(in: lane)
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }

            if lane.laneType == "Long" {
                let wait = SKAction.wait(forDuration: CGFloat.random(in: 4.5..<5.5))
                let spawn = SKAction.run { [weak self] in
                    self?.spawnLongEnemy(in: lane)
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
    
    // Function to spawn the shells randomly in grid spaces
    func spawnShell() {
        let shell = SKSpriteNode(imageNamed: "Shell") // Use your shell asset
        shell.size = CGSize(width: 45, height: 45) // Adjust size as needed
        shell.alpha = 1 // Set the opacity (0.0 to 1.0, where 0.5 is 50% opacity)
        shell.physicsBody = SKPhysicsBody(circleOfRadius: shell.size.width / 2.2)
        shell.physicsBody?.categoryBitMask = PhysicsCategory.shell
        shell.physicsBody?.contactTestBitMask = PhysicsCategory.box
        shell.physicsBody?.collisionBitMask = PhysicsCategory.none
        shell.physicsBody?.isDynamic = false

        // Create the pulsating effect with a pause
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let wait = SKAction.wait(forDuration: 3.0) // Wait for x seconds before animation
        let pulsate = SKAction.sequence([scaleUp, scaleDown, wait])
        let repeatPulsate = SKAction.repeatForever(pulsate)
        shell.run(repeatPulsate)

        let columns = Int(size.width / cellWidth)
        let playableColumnRange = ((-columns / 2) + 1)...((columns / 2) - 1)

        guard let box = box else { return }

        let currPosition = gridPosition(for: box.position)
        let currRow = currPosition.row

        let min = currRow - 2
        let max = currRow + 4
        let playableRowRange = min...max

        let randomRow = Int.random(in: playableRowRange)
        let randomColumn = Int.random(in: playableColumnRange)

        shell.position = positionFor(row: randomRow, column: randomColumn)
        addChild(shell)
    }

    // Function to add shells periodically
    func includeShells() {
        let initialDelay = SKAction.wait(forDuration: 8) // Add an initial delay of 30 seconds
        let shellSpawnAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnShell()
                },
                SKAction.wait(forDuration: 13) // Shells spawn less frequently
            ])
        )
        let sequence = SKAction.sequence([initialDelay, shellSpawnAction])
        run(sequence, withKey: "spawnShells")
    }

    // Function to increase score by 5 when player collects a shell
    func increaseScoreFromShell() {
        guard !isGameOver else { return }
        
        score += 5 // Increase score by 5
        scoreLabel.text = "\(score)" // Update the score label
        
        // Change the score label color to yellow
        let orangeAction = SKAction.colorize(with: .orange, colorBlendFactor: 1.0, duration: 0.0)
        let waitAction = SKAction.wait(forDuration: 0.5) // X.X SECONDS LONG YELLOW STAYS UPON SHELL COLLECTED
        // Change the score label color back to white
        let whiteAction = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 1.0)
        // Create a sequence of actions
        let colorSequence = SKAction.sequence([orangeAction, waitAction, whiteAction])
        
        // Run the sequence on the score label
        scoreLabel.run(colorSequence)
    }
    
    func showShellNextToScore() {
        let newShell = SKSpriteNode(imageNamed: "Shell") // Use your shell asset
        newShell.size = CGSize(width: 35, height: 35) // Initial size
        newShell.alpha = 0 // Start fully transparent
        newShell.position = CGPoint(x: scoreLabel.position.x - 40, y: scoreLabel.position.y) // Adjust position next to the score
        newShell.zPosition = scoreLabel.zPosition

        let fadeInAction = SKAction.fadeAlpha(to: 1.0, duration: 0.5) // Fade in over 0.5 seconds
        let enlargeAction = SKAction.scale(to: 1.5, duration: 0.5) // Enlarge over 0.5 seconds
        let moveToScoreAction = SKAction.move(to: scoreLabel.position, duration: 1.0) // Move to the score position over 1 second
        let shrinkAction = SKAction.scale(to: 0.1, duration: 1.0) // Shrink over 1 second
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0) // Fade out over 1 second

        let appearAction = SKAction.group([fadeInAction, enlargeAction])
        let moveAndFadeAction = SKAction.group([moveToScoreAction, shrinkAction, fadeOutAction])
        let removeAction = SKAction.removeFromParent()
        let sequenceAction = SKAction.sequence([appearAction, moveAndFadeAction, removeAction])
        
        newShell.run(sequenceAction)
        cameraNode.addChild(newShell)
    }

    func didBeginShellContact(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        print("Contact: \(bodyA.categoryBitMask) <-> \(bodyB.categoryBitMask)")  // Debugging collision
        
        let shellNode: SKNode
        if bodyA.categoryBitMask == PhysicsCategory.shell {
            shellNode = bodyA.node!
        } else {
            shellNode = bodyB.node!
        }

        // Remove the shell from the scene
        shellNode.removeFromParent()
        
        // Show a new shell next to the score
        showShellNextToScore()

        // Increase the score
        increaseScoreFromShell()
    }

    // Function to spawn the bubbles randomly in grid spaces
    func spawnBubble() {
        
        // Create the bubble asset
        let bubble = SKSpriteNode(imageNamed: "Bubble") // Use your bubble asset
        bubble.size = CGSize(width: 35, height: 35) // Adjust size as needed
        bubble.alpha = 0.75 // Set the opacity (0.0 to 1.0, where 0.5 is 50% opacity)
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: bubble.size.width / 2.2)
        bubble.physicsBody?.categoryBitMask = PhysicsCategory.bubble
        bubble.physicsBody?.contactTestBitMask = PhysicsCategory.box
        bubble.physicsBody?.collisionBitMask = PhysicsCategory.none
        bubble.physicsBody?.isDynamic = false
        
        // If this is the first bubble, set a fixed position
        if firstBubble == nil {
            let fixedRow = 3
            let fixedColumn = 0
            bubble.position = positionFor(row: fixedRow, column: fixedColumn)
            firstBubble = bubble
            addArrowAndText(to: bubble)
        } else {
            // Used to find the column range to place the bubble in randomly
            let columns = Int(size.width / cellWidth)
            let playableColumnRange = ((-columns / 2) + 1)...((columns / 2) - 1)
            
            // Used to find the row range to place the bubble in randomly
            guard let box = box else { return }
            
            // Getting the current row and column of the box/player using gridPosition function
            let currPosition = gridPosition(for: box.position)
            let currRow = currPosition.row // This is the current row the player is on
            
            // Create a row range for bubble to be placed randomly
            let min = currRow - 2
            let max = currRow + 4
            let playableRowRange = min...max
            
            // Now get a random row and column for the bubble to spawn in
            let randomRow = Int.random(in: playableRowRange)
            let randomColumn = Int.random(in: playableColumnRange)
            
            // Set the bubble position
            bubble.position = positionFor(row: randomRow, column: randomColumn)
        }
        
        addChild(bubble)
    }
    
    func addArrowAndText(to bubble: SKSpriteNode) {
        // Create the arrow
        arrow = SKSpriteNode(imageNamed: "Arrow") // Use your arrow asset
        arrow?.position = CGPoint(x: bubble.position.x - 35, y: bubble.position.y - 35) // Adjust position
        arrow?.zPosition = 1
        addChild(arrow!)
        
        // Create the text label
        bubbleText = SKLabelNode(text: "Collect bubbles to increase air!")
        bubbleText?.fontName = "SF Mono"
        bubbleText?.fontSize = 25
        bubbleText?.fontColor = .red
        bubbleText?.position = CGPoint(x: bubble.position.x - 10, y: bubble.position.y - 70)
        bubbleText?.zPosition = 1
        addChild(bubbleText!)
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
        airIcon = SKSpriteNode(imageNamed: "AirMeter")
        airIcon.size = CGSize(width: 35, height: 50)
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

    // Function to decrease air by 1 (called in aircountdown) // Air Meter Animation for Low Air
    func decreaseAir() {
        guard !isGameOver else { return }

        // Update air label
        airLabel.text = "\(airAmount)"

        // Change air label color when air is low
        if airAmount < 17 {
            airLabel.fontColor = .red
        } else {
            airLabel.fontColor = .white
        }

        // Enlarge the AirMeter asset (airIcon) when low air and pulsate red
        if airAmount < 17 {
            let enlargeAction = SKAction.scale(to: CGSize(width: 52.5, height: 75), duration: 0.2) // Scale up by 1.5x
            airIcon.run(enlargeAction)

            // Add pulsating red effect
            let redAction = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.5)
            let normalAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.5)
            let pulsateAction = SKAction.sequence([redAction, normalAction])
            airIcon.run(SKAction.repeatForever(pulsateAction), withKey: "pulsateRed")
        } else {
            let shrinkAction = SKAction.scale(to: CGSize(width: 35, height: 50), duration: 0.2) // Reset to original size
            airIcon.run(shrinkAction)

            // Remove the pulsating effect if air is 10 or more
            airIcon.removeAction(forKey: "pulsateRed")
            airIcon.colorBlendFactor = 0.0 // Reset to normal color
        }

        // Decrease air amount
        if airAmount > 0 {
            airAmount -= 1
            airLabel.text = "\(airAmount)"
        } else {
            gameOver()
        }
    }
    
    // Function to increase air by 10 when player gets bubble
    func increaseAir() {
        guard !isGameOver else { return }
        
        if airAmount < 30 {
            airAmount += 5
            if airAmount > 30 {
                airAmount = 30 // Cap the air at 30
            }
            airLabel.text = "\(airAmount)"
        }
    }
    
    func spawnTemporaryArrow() {
        // Create the temporary arrow
        let temporaryArrow = SKSpriteNode(imageNamed: "Arrow") // Use your arrow asset
        temporaryArrow.size = CGSize(width: 50, height: 50) // Adjust size as needed
        temporaryArrow.position = CGPoint(x: airIcon.position.x - 50, y: airIcon.position.y - 50)
        
        // Add the arrow to the scene
        cameraNode.addChild(temporaryArrow)
        
        // Create a fade-out action sequence to remove the arrow after a few seconds
        let delay = SKAction.wait(forDuration: 4.5) // Arrow stays for 3 seconds
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([delay, fadeOut, remove])
        
        // Run the sequence on the arrow
        temporaryArrow.run(sequence)
    }

    
    // Handles player contact with bubbles, enemies, and shells
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        // Handle contact with enemies
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.enemy) ||
           (bodyA.categoryBitMask == PhysicsCategory.enemy && bodyB.categoryBitMask == PhysicsCategory.box) {
            if !isGameOver {
                gameOver()
            }
        }
        
        // Handle contact with bubbles
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.bubble) ||
           (bodyA.categoryBitMask == PhysicsCategory.bubble && bodyB.categoryBitMask == PhysicsCategory.box) {
            increaseAir()
            
            // Check which body is the bubble
            let bubbleNode: SKNode
            if bodyA.categoryBitMask == PhysicsCategory.bubble {
                bubbleNode = bodyA.node!
            } else {
                bubbleNode = bodyB.node!
            }
            
            // Remove the bubble from the scene
            bubbleNode.removeFromParent()
            
            // Check if this was the first bubble
            if bubbleNode == firstBubble {
                // Remove the arrow and text
                arrow?.removeFromParent()
                bubbleText?.removeFromParent()
            }
        }
        
        // Handle contact with shells
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.shell) ||
           (bodyA.categoryBitMask == PhysicsCategory.shell && bodyB.categoryBitMask == PhysicsCategory.box) {
            didBeginShellContact(contact)
        }
    }

    func gameOver() {
        isGameOver = true
        cameraNode.removeAllActions() // Stop camera movement
        removeAction(forKey: "spawnEnemies") // Stop spawning enemies
        
        // Create semi-transparent black box
        let backgroundBox = SKShapeNode(rectOf: CGSize(width: size.width, height: 85))
        backgroundBox.position = CGPoint(x: 0, y: 92) // Adjust position as needed
        backgroundBox.fillColor = .black
        backgroundBox.alpha = 0.20 // Set transparency
        backgroundBox.zPosition = 999 // Ensure it is behind the text but above other nodes
        cameraNode.addChild(backgroundBox)
        
        // Add the game logo
        let logoTexture = SKTexture(imageNamed: "Logo")
        let logoSprite = SKSpriteNode(texture: logoTexture)
        logoSprite.position = CGPoint(x: 0, y: 270) // Positioned above the "Game Over" text
        logoSprite.zPosition = 1000 // Make logo be top visible layer
        logoSprite.xScale = 0.6 // Scale width to 60%
        logoSprite.yScale = 0.6 // Scale height to 60%
        cameraNode.addChild(logoSprite)
        
        // Save the current score
        let finalScore = score
        
        // Reset the score display (but keep the score variable intact for now)
        scoreLabel.text = "\(score)"
        
        // Add Game Over text
        let gameOverLabel = SKLabelNode(text: "Game Over!")
        gameOverLabel.fontSize = 48
        gameOverLabel.zPosition = 1000 // Make text be top visible layer
        gameOverLabel.fontColor = .red
        gameOverLabel.fontName = "Arial-BoldMT" // Use bold font
        gameOverLabel.position = CGPoint(x: 0, y: 90) // Center on screen
        cameraNode.addChild(gameOverLabel)

        // Display Final Score
        let finalScoreLabel = SKLabelNode(text: "Score: \(finalScore)")
        finalScoreLabel.fontSize = 32
        finalScoreLabel.fontColor = .white
        finalScoreLabel.zPosition = 1000 // Make text be top visible layer
        finalScoreLabel.fontName = "Arial-BoldMT" // Use bold font
        finalScoreLabel.position = CGPoint(x: 0, y: 60) // Positioned just below the "Game Over" text
        cameraNode.addChild(finalScoreLabel)

        // Display "Tap to Restart" message
        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 28
        restartLabel.fontColor = .yellow
        restartLabel.zPosition = 1000 // Make text be top visible layer
        restartLabel.fontName = "Arial" // Use bold font
        restartLabel.position = CGPoint(x: 0, y: -10) // Positioned below the final score
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
