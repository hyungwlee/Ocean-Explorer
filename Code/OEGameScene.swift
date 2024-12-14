//
//  OEGameScene.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//

import SpriteKit
import AVFoundation
import CoreHaptics
import UIKit
import AudioToolbox

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let box: UInt32 = 0b1       // 1
    static let enemy: UInt32 = 0b10    // 2
    static let bubble: UInt32 = 0b100  // 4
    static let shell: UInt32 = 0b1000  // 8
    static let GoldBubble: UInt32 = 0b10000  // 16
    static let rock: UInt32 = 0b100000 // 32
    static let lava: UInt32 = 0b1000000 // 64
    static let seaweed: UInt32 = 0b10000000 // 128
    static let rock2: UInt32 = 0b100000000 // 256
    static let rock3: UInt32 = 0b1000000000 // 532
}

struct Lane {
    let startPosition: CGPoint
    let endPosition: CGPoint
    let direction: CGVector
    let speed: CGFloat
    let laneType: String // Empty, Spike, Tutorial, Eel, Pufferfish, Shark, Jellyfish, or Lava
}

// Collection of easy sets of lanes
let easySets: [[String]] = [
    ["Lava"],
    ["Jellyfish", "Jellyfish", "Jellyfish"],
    ["Jellyfish", "Shark", "Jellyfish"],
    ["Jellyfish"],
    ["Shark"],
    ["Jellyfish"],
    ["Jellyfish", "Spike"],
    ["Jellyfish", "Jellyfish"],
    ["Eel"],
    ["Eel", "Jellyfish"],
    ["Jellyfish", "Spike", "Shark"],
    ["Spike", "Jellyfish", "Jellyfish"],
    ["Lava", "Lava", "Lava"],
    ["Lava", "Lava"],
    ["Lava", "Lava", "Jellyfish"],
]

// Collection of medium sets of lanes
let mediumSets: [[String]] = [
    ["Eel", "Eel", "Jellyfish"],
    ["Shark", "Shark", "Spike"],
    ["Jellyfish", "Jellyfish", "Eel", "Eel"],
    ["Spike", "Jellyfish", "Jellyfish", "Jellyfish", "Jellyfish"],
    ["Shark", "Spike", "Shark"],
    ["Spike", "Jellyfish", "Jellyfish", "Spike"],
    ["Jellyfish", "Shark", "Jellyfish", "Jellyfish", "Shark"],
    ["Spike", "Eel", "Jellyfish", "Shark"],
    ["Eel", "Spike", "Eel"],
    ["Lava", "Lava", "Lava", "Lava", "Lava"],
    ["Jellyfish", "Spike", "Spike", "Jellyfish", "Lava", "Lava"],
    ["Lava", "Lava", "Lava", "Jellyfish", "Jellyfish"],
    ["Jellyfish", "Jellyfish", "Jellyfish", "Lava", "Lava"],
    ["Spike", "Jellyfish", "Shark", "Lava", "Lava"]
]

// Collection of hard sets of lanes
let hardSets: [[String]] = [
    ["Jellyfish", "Jellyfish", "Spike", "Eel", "Eel"],
    ["Spike", "Eel", "Eel", "Eel"],
    ["Eel", "Shark", "Jellyfish", "Jellyfish", "Eel"],
    ["Jellyfish", "Spike", "Spike", "Shark", "Jellyfish", "Jellyfish", "Jellyfish", "Jellyfish"],
    ["Jellyfish", "Jellyfish", "Spike", "Eel", "Eel", "Eel", "Shark"],
    ["Jellyfish", "Spike", "Jellyfish", "Spike", "Spike", "Shark", "Jellyfish", "Eel", "Jellyfish"],
    ["Spike", "Pufferfish", "Spike"],
    ["Eel", "Spike", "Eel", "Lava", "Lava", "Lava", "Spike"],
    ["Spike", "Jellyfish", "Jellyfish", "Jellyfish", "Shark", "Lava", "Lava"],
    ["Jellyfish", "Jellyfish", "Eel", "Eel", "Jellyfish", "Eel", "Eel", "Eel"],
    ["Lava", "Lava", "Lava", "Lava", "Jellyfish", "Jellyfish"],
    ["Jellyfish", "Spike", "Jellyfish", "Spike", "Lava", "Lava", "Lava", "Lava", "Shark", "Lava", "Lava", "Lava", "Lava"]
]

// Create haptic feedback generators
let softImpactFeedback = UIImpactFeedbackGenerator(style: .soft) // For medium feedback
// let mediumImpactFeedback = UIImpactFeedbackGenerator(style: .medium) // For medium feedback
let heavyImpactFeedback = UIImpactFeedbackGenerator(style: .heavy)  // For heavy feedback (e.g., death)

    
@available(iOS 18.0, *)
class OEGameScene: SKScene, SKPhysicsContactDelegate {
    weak var context: OEGameContext?
    var box: OEBoxNode?
    var cameraNode: SKCameraNode!
    
    let gridSize = CGSize(width: 50, height: 50)
    var backgroundTiles: [SKSpriteNode] = []
    
    // Check if player on rock
    var isPlayerOnRock: Bool = false
    var currentRock: OERockNode? = nil
    var currentRock2: OERockNode2? = nil
    var currentRock3: OERockNode3? = nil
    var currentRockZone: String = ""
    var currentLongRockZone: String = ""
    var hasGameStarted = false
    
    var firstLane: Bool = true
    
    // Keep track of current latest rock speed and direction
    var currentRockSpeed: String = ""
    
    // Positions of all lava nodes
    var lavaYPositions: [CGFloat] = []
    
    // To keep track of seaweed positions
    var seaweedPositions: Set<CGPoint> = []
    
    // Score properties
    var score = 0
    var scoreDisplayed = 0
    var scoreLabel: SKLabelNode!
    
    // Air properties
    var airAmount = 20
    var airLabel: SKLabelNode!
    var airIconBackground: SKSpriteNode!
    var airIconFill: SKSpriteNode!
    var firstBubble: SKSpriteNode? = nil
    var arrow: SKSpriteNode?
    var bubbleText: SKLabelNode?
    var bubbleTextBackground: SKShapeNode?
    var red = false
    
    // Tapping properties
    var tapQueue: [CGPoint] = [] // Queue to hold pending tap positions
    var isActionInProgress = false // Flag to indicate if a movement is in progress
    
    var playerNextPosition: CGPoint = .zero
    
    // Game state variable
    var isGameOver = false
    var lanes: [Lane] = []  // Added this line to define lanes
    var laneDirection: Int = 0
    var prevLane: Lane? = nil
    
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
    var audioPlayer: AVAudioPlayer? // Audio player
    var backgroundMusicPlayer: AVAudioPlayer? // Background music audio player
    var playerMovementAudio: SystemSoundID = 0
    
    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        
        isPlayerOnRock = false
        currentRock = nil
        currentRock2 = nil
        currentRock3 = nil
        currentRockZone = ""
        currentLongRockZone = ""
        
        // Initially slow rock speed
        currentRockSpeed = "Slow"
 
        guard let url = Bundle.main.url(forResource: "move", withExtension: "mp3") else {
                return
            }
            let osstatus = AudioServicesCreateSystemSoundID(url as CFURL, &playerMovementAudio)
            if osstatus != noErr { // or kAudioServicesNoError. same thing.
                print("could not create system sound")
                print("osstatus: \(osstatus)")
            }
        
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
                    lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: 9.0, laneType: "Jellyfish"))
                } else {
                    lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: 7.0, laneType: "Shark"))
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
                lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: 5.0, laneType: "Pufferfish"))
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
            
            firstLane = true
            for _ in i...i + laneDifficulty[laneSet].count - 1 {
                let yPosition = laneHeight * CGFloat(i) + (laneHeight / 2)
                let leftStart = CGPoint(x: -size.width, y: yPosition)
                let rightStart = CGPoint(x: size.width, y: yPosition)
                
                var laneSpeed: CGFloat = 0
                
                // For lava lanes have to either switch direction, speed, or both each time
                if laneDifficulty[laneSet][lane] == "Lava" {
                    
                    let choice = Int.random(in: 0...9)
                    
                    // Switch direction
                    if choice < 4 {
                        laneDirection = 1 - laneDirection
                        if currentRockSpeed == "Slow" {
                            laneSpeed = CGFloat.random(in: 13...16)
                        } else {
                            laneSpeed = CGFloat.random(in: 4...6.5)
                        }
                    }
                    
                    // Switch speed
                    else if choice < 6 {
                        if currentRockSpeed == "Slow" {
                            laneSpeed = CGFloat.random(in: 4...6.5)
                            currentRockSpeed = "Fast"
                        } else {
                            laneSpeed = CGFloat.random(in: 13...16)
                            currentRockSpeed = "Slow"
                        }
                    }
                    
                    // Switch direction and speed
                    else {
                        laneDirection = 1 - laneDirection
                        if currentRockSpeed == "Slow" {
                            laneSpeed = CGFloat.random(in: 4...6.5)
                            currentRockSpeed = "Fast"
                        } else {
                            laneSpeed = CGFloat.random(in: 13...16)
                            currentRockSpeed = "Slow"
                        }
                    }
                    if firstLane {
                        currentRockSpeed = "Slow"
                        laneSpeed = CGFloat.random(in: 13...16)
                    }
                } else {
                    // Random directions for lanes
                    laneDirection = Int.random(in: 0..<2)
                    laneSpeed = CGFloat.random(in: 7...13)
                }
                
                if laneDirection == 0 {
                    lanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: laneSpeed, laneType: laneDifficulty[laneSet][lane]))
                } else {
                    lanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: laneSpeed, laneType: laneDifficulty[laneSet][lane]))
                }
                yPositionLanes = yPosition
                i += 1
                lane += 1
                firstLane = false
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
             enemySize = "Shark"
             enemySpeed = CGFloat.random(in: 10..<13)
             }
             else if enemySizeChance == 1 {
             enemySize = "Jellyfish"
             enemySpeed = CGFloat.random(in: 8.5..<11.5)
             }
             else {
             enemySize = "Spike"
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
        showStartOverlay()
        prepareGameContext()
        prepareStartNodes()
        
        cameraNode.position = CGPoint(x: 0, y: 0)
        context.stateMachine?.enter(OEGameIdleState.self)
        
        addGestureRecognizers()
        
        // Set up physics world contact delegate
        physicsWorld.contactDelegate = self
        
        // drawGridLines()
        
        // Start timed enemy spawning
        startSpawning(lanes: lanes)
        
        // Initialize and set up score label
        setupScoreLabel()
        setupAirDisplay()
        airCountDown()
        includeBubbles()
        includeShells()
     // spawnTemporaryArrow()
        
        startCameraMovement()
    }
    
    func startCameraMovement() {
        guard hasGameStarted else { return } // Ensure camera movement starts only if game has started
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
            playerNextPosition = box.position
        }
    }
    let shadowLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")

    func setupScoreLabel() {
        // Main score label
        scoreLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        scoreLabel.fontSize = 75
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 1000
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - 125) // Centered horizontally
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.text = "\(score)"

        // Shadow label
        shadowLabel.fontSize = 75
        shadowLabel.fontColor = .black.withAlphaComponent(0.5) // Semi-transparent shadow
        shadowLabel.zPosition = 999 // Place below the main label
        shadowLabel.position = CGPoint(x: scoreLabel.position.x + 5, y: scoreLabel.position.y - 5) // Slight offset
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.text = "\(score)"
        
        // Add shadow and main score label to the camera node
        cameraNode.addChild(shadowLabel)
        cameraNode.addChild(scoreLabel)
    }
    
    let goldColor = UIColor(red: 255/255.0, green: 223/255.0, blue: 87/255.0, alpha: 1.0) // Lighter gold
    
    func updateScore() {
        score += 1
        if score >= scoreDisplayed + 1 {
            scoreDisplayed += 1
        }
        
        // Update font colors and effects based on score milestones
        if score % 100 == 0 {
            scoreLabel.fontColor = .red // Gold color
        } else if score % 10 == 0 {
            scoreLabel.run(createPopOutAction()) // Apply the popping effect on multiples of 10
        } else {
            scoreLabel.fontColor = .white
            shadowLabel.fontColor = .black.withAlphaComponent(0.5) // Default shadow color
        }
        
        // Update the text for both labels
        let updatedText = "\(max(score, scoreDisplayed))"
        scoreLabel.text = updatedText
        shadowLabel.text = updatedText
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
        
        super.update(currentTime)
        
        if !isPlayerOnRock && isPlayerOnLava() && !isPlayerInContactWithRock() && !isPlayerInContactWithRock2() && !isPlayerInContactWithRock3() {
            handleLavaContact()
        }
        
        
        // Sync player movement with rock while they are on it
        if let rock = currentRock {
            box.position.x = rock.position.x // Follow the rock horizontally
            playerNextPosition.x = rock.position.x
        }
        
        if let rock = currentRock2 {
            if currentRockZone == "Left" {
                box.position.x = rock.position.x - rock.size.width * 0.2
                playerNextPosition.x = rock.position.x - rock.size.width * 0.2
            } else {
                box.position.x = rock.position.x + rock.size.width * 0.2
                playerNextPosition.x = rock.position.x + rock.size.width * 0.2
            }
        }
        
        if let rock = currentRock3 {
            if currentLongRockZone == "Left" {
                box.position.x = rock.leftSnapZone.x
                playerNextPosition.x = rock.leftSnapZone.x
            } else if currentLongRockZone == "Center" {
                box.position.x = rock.centerSnapZone.x
                playerNextPosition.x = rock.centerSnapZone.x
            } else {
                box.position.x = rock.rightSnapZone.x
                playerNextPosition.x = rock.rightSnapZone.x
            }
        }
        
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
            // Play the "fell" sound effect
            playFellSound()
            
            // Trigger game over with the appropriate reason
            gameOver(reason: "You sank into the depths and disappeared!")
        }
        
        if box.position.x > size.width / 2 || box.position.x < -size.width / 2 {
            // Play the "fell" sound effect
            //swept and fell have same sounds
            playFellSound()
            gameOver(reason: "You were swept away by the rocks!")
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
            firstLane = true
            for _ in i...i + laneDifficulty[laneSet].count - 1 {
                let newYPosition = yPosition + CGFloat(i + 1) * laneHeight
                let leftStart = CGPoint(x: -size.width, y: newYPosition)
                let rightStart = CGPoint(x: size.width, y: newYPosition)
                
                var laneSpeed: CGFloat = 0.0
                
                if laneDifficulty[laneSet][lane] == "Lava" {
                    
                    let choice = Int.random(in: 0...9)
                    
                    // Switch direction
                    if choice < 4 {
                        laneDirection = 1 - laneDirection
                        if currentRockSpeed == "Slow" {
                            laneSpeed = CGFloat.random(in: 13...16)
                        } else {
                            laneSpeed = CGFloat.random(in: 4...6.5)
                        }
                    }
                    
                    // Switch speed
                    else if choice < 6 {
                        if currentRockSpeed == "Slow" {
                            laneSpeed = CGFloat.random(in: 4...6.5)
                            currentRockSpeed = "Fast"
                        } else {
                            laneSpeed = CGFloat.random(in: 13...16)
                            currentRockSpeed = "Slow"
                        }
                    }
                    
                    // Switch direction and speed
                    else {
                        laneDirection = 1 - laneDirection
                        if currentRockSpeed == "Slow" {
                            laneSpeed = CGFloat.random(in: 4...6.5)
                            currentRockSpeed = "Fast"
                        } else {
                            laneSpeed = CGFloat.random(in: 13...16)
                            currentRockSpeed = "Slow"
                        }
                    }
                    if firstLane {
                        laneSpeed = CGFloat.random(in: 13...16)
                        currentRockSpeed = "Slow"
                    }
                } else {
                    // Random directions for lanes
                    laneDirection = Int.random(in: 0...1)
                    laneSpeed = CGFloat.random(in: 7...13)
                }
                
                if laneDirection == 0 {
                    newLanes.append(Lane(startPosition: leftStart, endPosition: rightStart, direction: CGVector(dx: 1, dy: 0), speed: laneSpeed, laneType: laneDifficulty[laneSet][lane]))
                } else {
                    newLanes.append(Lane(startPosition: rightStart, endPosition: leftStart, direction: CGVector(dx: -1, dy: 0), speed: laneSpeed, laneType: laneDifficulty[laneSet][lane]))
                }
                yPositionLanes = newYPosition
                i += 1
                lane += 1
                firstLane = false
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
             laneType = "Shark"
             laneSpeed = CGFloat.random(in: 10..<13)
             }
             else if eelSpawn > 12 {
             laneType = "Jellyfish"
             laneSpeed = CGFloat.random(in: 8.5..<11.5)
             }
             else {
             laneType = "Spike"
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
        // Update global lanes with new Lanes
        lanes.append(contentsOf: newLanes)
        
        // Start spawning lanes
        startSpawning(lanes: newLanes)
    }
    
    // Returns current Lane Type based on posistion of thing passed int (bubble)
    func currentLaneType(position: CGPoint) -> String? {
        for lane in lanes {
            if position.y >= lane.startPosition.y - 3 && position.y < lane.startPosition.y + 3 {
                return lane.laneType
            }
        }
        return nil // Return nil if no lane matches
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
        
        // Haptic feedback for each movement
      //  softImpactFeedback.impactOccurred()
        


        let nextPosition = CGPoint(x: playerNextPosition.x, y: playerNextPosition.y + cellHeight)
        if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x, y: playerNextPosition.y + cellHeight)) {
            playerNextPosition.y += cellHeight
            
            
            // Play the move sound effect
                playMoveSound()
            
            // If an action is already in progress, queue the next tap position
            print("QUEUING MOVEMENT")
            tapQueue.append(playerNextPosition)
            box.hop(to: nextPosition, inQueue: playerNextPosition, up: true)
            updateScore()

        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        
        var hitSeaweed = false
        if isActionInProgress {
            return
        }
        
        guard let box, !isGameOver else { return }
        
        let nextPosition: CGPoint
        // playMoveSound()
        // softImpactFeedback.impactOccurred() // HAPTICS for swiping left/right
        switch sender.direction {

        case .down:
    
            nextPosition = CGPoint(x: box.position.x, y: playerNextPosition.y - cellHeight)
            if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x, y: playerNextPosition.y - cellHeight)) {
                playerNextPosition.y -= cellHeight
            } else {
                hitSeaweed = true
            }
            score -= 1
        case .left:
          if isPlayerOnRock { // Check if the player is on the rock
                playRockJumpSound()
            }
            nextPosition = CGPoint(x: max(playerNextPosition.x - cellWidth, playableWidthRange.lowerBound), y: box.position.y)
            if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x - cellWidth, y: playerNextPosition.y)) && !box.getIsMoving(){
                print(isActionInProgress)
                print("MOVING LEFT")
                playerNextPosition.x -= cellWidth
            } else {
                hitSeaweed = true
            }

            if currentRock2 != nil && currentRockZone == "Right" {
                currentRockZone = "Left"
                return
            }
            if currentRock3 != nil {
                if currentLongRockZone == "Right" {
                    currentLongRockZone = "Center"
                    return
                }
                else if currentLongRockZone == "Center" {
                    currentLongRockZone = "Left"
                    return
                }
            }
        case .right:
            if isPlayerOnRock { // Check if the player is on the rock
                playRockJumpSound()
            }
            nextPosition = CGPoint(x: min(playerNextPosition.x + cellWidth, playableWidthRange.upperBound), y: box.position.y)
            if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x + cellWidth, y: playerNextPosition.y)) && !box.getIsMoving() {
                print("MOVING RIGHT")
                playerNextPosition.x += cellWidth
            } else {
                hitSeaweed = true
            }
            if currentRock2 != nil && currentRockZone == "Left" {
                currentRockZone = "Right"
                return
            }
            if currentRock3 != nil {
                if currentLongRockZone == "Left" {
                    currentLongRockZone = "Center"
                    return
                }
                else if currentLongRockZone == "Center" {
                    currentLongRockZone = "Right"
                    return
                }
            }
            
        default:
            return
        }
        if !hitSeaweed {
                box.hop(to: nextPosition, inQueue: nextPosition, up: false)
            }
        
    }
    
  /*
    func moveBox(to position: CGPoint) {
        guard let box else { return }
        
        //Check if player is running into seaweed with movement
        if handleSeaweedContact(nextPosition:  position) {
            // If true then return and do nothing
            print("Ran into seaweed")
            return
        }
        
        // Set the flag to indicate movement in progress
        isActionInProgress = true
        
        // Example movement logic using an animation

        UIView.animate(withDuration: 0.15, animations: {
            
            print("HOPPING")
        
            box.hop(to: position)
            

        }) { [weak self] _ in
            guard let self = self else { return }
            
            // If there are more actions in the queue, execute the next one
            if let nextPosition = self.tapQueue.first {
                self.tapQueue.removeFirst()
                box.run(SKAction.wait(forDuration: 1))
                self.moveBox(to: nextPosition)
                // Update the score
                updateScore()
            } else {
                self.isActionInProgress = false
            }
        }
        
    }
    */
    func spawnEnemy(in lane: Lane) {
        let enemy = OEEnemyNode(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed + CGFloat.random(in: -0.5...1))
    }
    
    func spawnJellyfish(in lane: Lane) {
        let enemy = OEEnemyNode5(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed + CGFloat.random(in: -0.5...1))
        enemy.animate()
    }
    
    func spawnLongEnemy(in lane: Lane) {
        let enemy = OEEnemyNode4(gridSize: gridSize)
        addChild(enemy)
        if lane.direction == CGVector(dx: -1, dy: 0) {
            enemy.xScale = -1
        }
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed + CGFloat.random(in: -0.5...1))
        enemy.animate()
    }
    
    func spawnPufferfish(in lane: Lane) {
        var flipped = false
        if lane.direction == CGVector(dx: -1, dy: 0) {
            flipped = true
        }
        let enemy = OEEnemyNode2(gridSize: gridSize, flipped: flipped)
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
    
    func spawnLava(in lane: Lane) {
        let lava = OELavaNode(size: CGSize(width: size.width * 2, height: cellHeight))
        addChild(lava)
        lava.position = CGPoint(x: 0, y: lane.startPosition.y)
        lava.animate()
    }
    
    func spawnRock(in lane: Lane) {
        let rockType = Int.random(in: 0...2)
        if rockType == 0 {
            let rock = OERockNode(height: cellHeight + cellHeight / 4)
            addChild(rock)
            rock.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
        } else if rockType == 1{
            let rock = OERockNode2(height: cellHeight + cellHeight / 4)
            addChild(rock)
            rock.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
        } else {
            let rock = OERockNode3(height: cellHeight + cellHeight / 4)
            addChild(rock)
            rock.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
        }
    }
    
    func spawnSeaweed(in lane: Lane) {
        // Randomly decide how many seaweed assets to spawn (3 to 5)
        let numberOfSeaweed = Int.random(in: 1...4)
        
        // Exclude the 0 in the middle
        let validColumns = (-4...4).filter { $0 != 0 }
        
        // Randomly select distinct columns for seaweed placement
        var selectedColumns = Set<Int>()
        while selectedColumns.count < numberOfSeaweed {
            if let columnIndex = validColumns.randomElement() {
                selectedColumns.insert(columnIndex)
            }
        }
        
        // Spawn seaweed in the selected columns
        for columnIndex in selectedColumns {
            
            //Set size of seaweed
            let seaweed = OESeaweedNode(size: CGSize(width: 48, height: 52))
            addChild(seaweed)
            
            
            // Calculate the x-position for the selected column
            let columnXPosition = (CGFloat(columnIndex) + 0.5) * cellWidth
            
            // Use the lane's startPosition y-coordinate for the row
            seaweed.position = CGPoint(x: columnXPosition, y: lane.startPosition.y)
            
            //Keep track of seaweed spots for bubble and shell placement
            seaweedPositions.insert(seaweed.position)
            seaweed.animate()
        }
    }
    
    func warn(in lane: Lane, completion: @escaping () -> Void) {
        
        let warningLabel = SKSpriteNode(imageNamed: "EelWarning")
        warningLabel.position = CGPoint(x: 0.0, y: lane.startPosition.y)
        warningLabel.size = CGSize(width: warningLabel.size.width * 0.85, height: warningLabel.size.height * 0.70)
        addChild(warningLabel)
        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        let fadeIn = SKAction.fadeIn(withDuration: 0.25)
        let removeWarning = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, fadeIn, fadeOut, fadeIn, fadeOut, removeWarning])
        // Run the sequence and trigger the completion block
        warningLabel.run(sequence) {
            completion()
        }
    }
    
    func startSpawning(lanes: [Lane]) {
        
        for lane in lanes {
            
            if lane.laneType == "Empty" {
                colorLane(in: lane)
                
                // If Lava then empty then don't spawn any seaweed
                if prevLane?.laneType == "Lava" {
                    continue
                }
                let spawn = SKAction.run { [weak self] in
                    self?.spawnSeaweed(in: lane)
                }
                run(spawn)
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
                let wait = SKAction.wait(forDuration: CGFloat.random(in: 7...10))
                let warn = SKAction.run { [weak self] in
                    self?.warn(in: lane) {
                        // Trigger spawn after warning is completed
                        self?.spawnEel(in: lane)
                    }
                }
                let sequence = SKAction.sequence([wait, warn])
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
            
            if lane.laneType == "Spike" {
                let wait = SKAction.wait(forDuration: 4.25, withRange: 2)
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
                let wait = SKAction.wait(forDuration: 4, withRange: 2)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnJellyfish(in: lane)
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lane.laneType == "Shark" {
                let wait = SKAction.wait(forDuration: 4.5, withRange: 2)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnLongEnemy(in: lane)
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lane.laneType == "Lava" {
                spawnLava(in: lane)
                lavaYPositions.append(lane.startPosition.y)
                var waitTime: CGFloat = 0.0
                if lane.speed > 11 {
                    waitTime = CGFloat.random(in: 4..<4.5)
                } else {
                    waitTime = CGFloat.random(in: 1.5..<2.25)
                }
                let wait = SKAction.wait(forDuration: waitTime)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnRock(in: lane)
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            // Set prevLane
            prevLane = lane
        }
    }
    
    // Color lanes that are empty or eel type
    func colorLane(in lane: Lane) {
        let laneColor = SKShapeNode(rect: CGRect(x: -size.width, y: lane.startPosition.y - cellHeight / 2, width: size.width * 2, height: cellHeight))
        if lane.laneType == "Empty" {
            laneColor.fillColor = .white
            laneColor.fillTexture = SKTexture(imageNamed: "SAND")
        }
        else if lane.laneType == "Eel" {
            laneColor.fillColor = .white
            laneColor.fillTexture = SKTexture(imageNamed: "eelLane")
            
        }
        else {
            laneColor.fillColor = .red
        }
        laneColor.alpha = 0.55
        laneColor.zPosition = 0
        addChild(laneColor)
        //        print("Lane position: \(lane.startPosition.y)")
    }
    
    // Function to spawn the shells randomly in grid spaces
    func spawnShell() {
        let shell = SKSpriteNode(imageNamed: "Shell") // Use your shell asset
        shell.size = CGSize(width: 42, height: 42) // Adjust size as needed
        shell.alpha = 1 // Set the opacity (0.0 to 1.0, where 0.5 is 50% opacity)
        shell.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: 1))
        shell.physicsBody?.categoryBitMask = PhysicsCategory.shell
        shell.physicsBody?.contactTestBitMask = PhysicsCategory.box
        shell.physicsBody?.collisionBitMask = PhysicsCategory.none
        shell.physicsBody?.isDynamic = false
        
        // Create the pulsating effect with a pause
        let scaleUp = SKAction.scale(to: 1.30, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let wait = SKAction.wait(forDuration: 1.5) // Wait for x seconds before animation
        let pulsate = SKAction.sequence([scaleUp, scaleDown, wait])
        let repeatPulsate = SKAction.repeatForever(pulsate)
        shell.run(repeatPulsate)
        
        
        guard let box = box else { return }
        
        let currPosition = gridPosition(for: box.position)
        let playerRow = currPosition.row
        let playerColumn = currPosition.column
        
        let columns = Int(size.width / cellWidth)
        let columnRange = ((-columns / 2) + 1)...((columns / 2) - 1)
        let playableColumnRange = columnRange.filter { $0 != playerColumn} //Filter out where the player is so shell can be seen spawning
        
        let min = playerRow - 2
        let max = playerRow + 4
        let playableRowRange = min...max
        
        var randomRow = Int.random(in: playableRowRange)
        var randomColumn = playableColumnRange.randomElement()!
        shell.position = positionFor(row: randomRow, column: randomColumn)
        
        // Check lane type and ensure it's not "Eel" or "Lava" and make sure shell not spawning on seaweed
        var shellLaneType = currentLaneType(position: shell.position)?.lowercased()
        while shellLaneType == "eel" || shellLaneType == "lava" || seaweedPositions.contains(shell.position) {
            randomRow += 1
            randomColumn = playableColumnRange.randomElement()!
            shell.position = positionFor(row: randomRow, column: randomColumn)
            shellLaneType = currentLaneType(position: shell.position)?.lowercased()
        }
        addChild(shell)
    }
    
    // Function to add shells periodically
    func includeShells() {
        guard hasGameStarted else { return }
        let initialDelay = SKAction.wait(forDuration: 8) // Add an initial delay of 30 seconds
        let shellSpawnAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnShell()
                },
                SKAction.wait(forDuration: 15) // Shells spawn less frequently
            ])
        )
        let sequence = SKAction.sequence([initialDelay, shellSpawnAction])
        run(sequence, withKey: "spawnShells")
    }
    /*
     // Function to increase score by 5 when player collects a shell **HIDE FOR NOW
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
     */
    func shellAnimation() {
        let newShell = SKSpriteNode(imageNamed: "Shell") // Use your shell asset
        newShell.size = CGSize(width: 40, height: 40) // Initial size
        newShell.alpha = 0 // Start fully transparent
        
        // Adjust position more to the left and slightly upwards
        newShell.position = CGPoint(x: scoreLabel.position.x - 70, y: scoreLabel.position.y + 30)
        newShell.zPosition = scoreLabel.zPosition
        
        // Define fade-in and enlarge action
        let fadeInAction = SKAction.fadeAlpha(to: 1.0, duration: 0.5) // Fade in over 0.5 seconds
        let enlargeAction = SKAction.scale(to: 1.5, duration: 0.5) // Enlarge over 0.5 seconds
        
        // Pulsating effect (enlarge and shrink repeatedly)
        let scaleUp = SKAction.scale(to: 1.6, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.4, duration: 0.3)
        let pulsate = SKAction.sequence([scaleUp, scaleDown])
        let repeatPulsate = SKAction.repeatForever(pulsate)
        
        // Run pulsating action
        newShell.run(repeatPulsate, withKey: "pulsateAction")
        
        // Wait at the top for a set duration before fading out
        let waitAction = SKAction.wait(forDuration: 2.5) // Duration at the top with pulsating effect
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0) // Fade out over 1 second
        
        // Stop pulsating before fading out
        let stopPulsating = SKAction.run {
            newShell.removeAction(forKey: "pulsateAction") // Stop pulsating
        }
        let removeAction = SKAction.removeFromParent() // Remove from scene after fade-out
        
        // Sequence of actions
        let sequenceAction = SKAction.sequence([
            fadeInAction,  // Fade in
            enlargeAction, // Enlarge
            waitAction,    // Wait while pulsating
            stopPulsating, // Stop pulsating
            fadeOutAction, // Fade out
            removeAction   // Remove the shell node
        ])
        
        newShell.run(sequenceAction)
        cameraNode.addChild(newShell)
    }
    // TO SLOW DOWN THE AIR COUNTDOWN (UPON SHELL PICKUP, ETC)
    func adjustAirCountdown(isSlowed: Bool) {
        // Stop the current air countdown
        removeAction(forKey: "airCountdown")
        
        // Set the new countdown speed
        let duration = isSlowed ? 2.0 : 1.0 // Double the wait time when slowed
        let countdownAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.decreaseAir()
                },
                SKAction.wait(forDuration: duration)
            ])
        )
        run(countdownAction, withKey: "airCountdown")
    }
    
    
    //METHOD TO SLOW DOWN CAMERA
    func slowDownCamera() {
        // Reduce the speed of the camera
        let slowDownAction = SKAction.speed(to: 0.5, duration: 0.0) // Instantly slow down
        let waitAction = SKAction.wait(forDuration: 3.5) // Slow Length (Higher the longer it's slow)
        let speedUpAction = SKAction.speed(to: 1.0, duration: 0.0) // Revert to original speed
        
        // Adjust the air countdown timing
        adjustAirCountdown(isSlowed: true)
        
        let sequenceAction = SKAction.sequence([
            slowDownAction,
            waitAction,
            SKAction.run { [weak self] in
                self?.adjustAirCountdown(isSlowed: false)
            },
            speedUpAction
        ])
        
        cameraNode.run(sequenceAction)
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
        
        // Play the shell pickup sound
        playShellPickupSound()
        
        softImpactFeedback.impactOccurred()
        
        // Show a new shell next to the score
        shellAnimation()
        
        // Slow down the camera movement
        slowDownCamera()
    }
    
    func spawnBubble() {
        // Determine if the bubble should be a GoldBubble
        let isGoldBubble = Int.random(in: 0..<100) < 10 // Adjust as needed for spawn rate
        
        // Create the bubble (GoldBubble or regular Bubble)
        let bubble: SKSpriteNode
        if isGoldBubble && firstBubble != nil {
            bubble = SKSpriteNode(imageNamed: "GoldBubble") // GoldBubble asset
            bubble.size = CGSize(width: 40, height: 40) // Larger for GoldBubble
            bubble.alpha = 0.90
            bubble.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: 1))
            bubble.physicsBody?.categoryBitMask = PhysicsCategory.GoldBubble // Ensure this is correct
        } else {
            bubble = SKSpriteNode(imageNamed: "Bubble") // Regular bubble asset
            bubble.size = CGSize(width: 38, height: 38)
            bubble.alpha = 0.85
            bubble.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: 1))
            bubble.physicsBody?.categoryBitMask = PhysicsCategory.bubble
        }
        
        bubble.physicsBody?.contactTestBitMask = PhysicsCategory.box
        bubble.physicsBody?.collisionBitMask = PhysicsCategory.none
        bubble.physicsBody?.isDynamic = false
        
        // Create the pulsating effect with a pause (added delay between pulsations)
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.10)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.10)
        let scaleUp2 = SKAction.scale(to: 1.20, duration: 0.10)
        let scaleDown2 = SKAction.scale(to: 1.0, duration: 0.10)
        let wait = SKAction.wait(forDuration: 2.0) // Delay between pulsating
        let pulsate = SKAction.sequence([scaleUp, scaleDown, scaleUp2, scaleDown2, wait])
        // pulsate twice
        let repeatPulsate = SKAction.repeatForever(pulsate)
        bubble.run(repeatPulsate)
        
        // If this is the first bubble, set a fixed position
        if firstBubble == nil {
            let fixedRow = 3
            let fixedColumn = 0
            bubble.position = positionFor(row: fixedRow, column: fixedColumn)
            firstBubble = bubble
            addArrowAndText(to: bubble)
        } else {
            // Used to find the row range to place the bubble in randomly
            guard let box = box else { return }
            
            // Getting the current row and column of the box/player using gridPosition function
            let currPosition = gridPosition(for: box.position)
            let playerRow = currPosition.row // This is the current row the player is on
            let playerColumn = currPosition.column
            
            // Used to find the column range to place the bubble in randomly
            let columns = Int(size.width / cellWidth)
            let columnRange = ((-columns / 2) + 1)...((columns / 2) - 1)
            let playableColumnRange = columnRange.filter { $0 != playerColumn }
            
            // Create a row range for bubble to be placed randomly
            let min = playerRow - 2
            let max = playerRow + 4
            let playableRowRange = min...max
            
            // Now get a random row and column for the bubble to spawn in
            var randomRow = Int.random(in: playableRowRange)
            var randomColumn = playableColumnRange.randomElement()!
            
            // Set the bubble position
            bubble.position = positionFor(row: randomRow, column: randomColumn)
            
            // Check if bubble is on the lava or eel lane and make sure it doesn't spawn on seaweed
            var bubbleLaneType = currentLaneType(position: bubble.position)?.lowercased()
            while bubbleLaneType == "eel" || bubbleLaneType == "lava" || seaweedPositions.contains(bubble.position) {
                randomRow += 1
                randomColumn = playableColumnRange.randomElement()!
                bubble.position = positionFor(row: randomRow, column: randomColumn)
                bubbleLaneType = currentLaneType(position: bubble.position)?.lowercased()
            }
        }
        
        addChild(bubble)
    }
    
    func addArrowAndText(to bubble: SKSpriteNode) {
        // Create the arrow
        arrow = SKSpriteNode(imageNamed: "Arrow") // Use your arrow asset
        arrow?.size = CGSize(width: 40, height: 40) // Adjust size as needed
        arrow?.position = CGPoint(x: bubble.position.x - 30, y: bubble.position.y - 30) // Adjust position
        arrow?.zPosition = 1000
        arrow?.alpha = 0.5 // Set transparency (50% opacity)
        addChild(arrow!)
        
        // Create the text label
        bubbleText = SKLabelNode(text: "collect bubbles for air")
        bubbleText?.fontName = "Helvetica Neue Bold"
        bubbleText?.fontSize = 15
        bubbleText?.fontColor = .white
        bubbleText?.position = CGPoint(x: bubble.position.x - 10, y: bubble.position.y - 72) // Slightly higher for vertical centering
        bubbleText?.zPosition = 1
        
        // Create a background rectangle for the text
        bubbleTextBackground = SKShapeNode(rectOf: CGSize(width: bubbleText!.frame.width + 20, height: bubbleText!.frame.height + 5), cornerRadius: 8)
        bubbleTextBackground?.fillColor = SKColor.black.withAlphaComponent(0.5) // Black with 50% transparency
        bubbleTextBackground?.strokeColor = .clear // No border
        bubbleTextBackground?.position = CGPoint(x: bubbleText!.position.x, y: bubbleText!.position.y + bubbleText!.frame.height / 2) // Adjust for vertical centering
        bubbleTextBackground?.zPosition = bubbleText!.zPosition - 1 // Put it behind the text
        
        // Add the background and the text to the scene
        addChild(bubbleTextBackground!)
        addChild(bubbleText!)
    }

    func includeBubbles() {
        guard hasGameStarted else { return }
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
        // Remove existing airIcon and airLabel if they exist
        airIconBackground?.removeFromParent()
        airIconFill?.removeFromParent()
        airLabel?.removeFromParent()

        // Create and configure the air icon
        airIconBackground = SKSpriteNode(imageNamed: "AirMeterBackground")
        airIconFill = SKSpriteNode(imageNamed: "AirMeterFill")
        airIconBackground.size = CGSize(width: 30, height: 150) // Increased size
        airIconFill.size = CGSize(width: 30, height: 150)
        airIconBackground.position = CGPoint(x: size.width / 2 - 80, y: size.height / 2 - 90)
        airIconFill.position = CGPoint(x: size.width / 2 - 80, y: size.height / 2 - 165)
        airIconBackground.zPosition = 90
        airIconFill.zPosition = 100
        airIconFill.anchorPoint = CGPoint(x: 0.5, y: 0.0) // Anchor at the bottom-center for decreasing the air amount

        cameraNode.addChild(airIconFill)
        cameraNode.addChild(airIconBackground)

        // Create and configure the air label
        airLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        airLabel.fontSize = 23 // Increased font size
        airLabel.fontColor = UIColor.black.withAlphaComponent(0.50) // Slightly transparent text
        airLabel.zPosition = 1000
        
        // Position the air label at the center of the airIconBackground
        airLabel.position = CGPoint(x: airIconBackground.position.x, y: airIconBackground.position.y)
        airLabel.horizontalAlignmentMode = .center // Align horizontally to the center
        airLabel.verticalAlignmentMode = .center   // Align vertically to the center
        
        airLabel.text = "\(airAmount)"
        cameraNode.addChild(airLabel)
    }

    // Continuously decreases air during game
    func airCountDown() {
        guard hasGameStarted else { return } // Ensure countdown starts only if game has started
        let countdownAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.decreaseAir()
                },
                SKAction.wait(forDuration: 1)
            ])
        )
        run(countdownAction, withKey: "airCountdown")
    }
    
    func calculateScaleFactor(airAmount: Int) -> CGFloat {
        let fullCapacity = 30 // The maximum capacity of your meter
        let currentPercentage = CGFloat(airAmount) / CGFloat(fullCapacity)
        
        // Ensure the percentage doesn't exceed 100%
        let maxPercentage = min(currentPercentage, 1.0)
        
        // Calculate the scale factor (between 0 and 1)
        let scaleFactor = maxPercentage
        
        return scaleFactor
    }
    
    // Function to decrease air by 1 (called in aircountdown) // Air Meter Animation for Low Air
    func decreaseAir() {
        guard !isGameOver else { return }

        // Decrease the air amount immediately
        airAmount -= 1
        airLabel.text = "\(airAmount)"
        // Update the meter right after
        let targetScaleFactor = calculateScaleFactor(airAmount: airAmount)
        airIconFill.yScale = targetScaleFactor

        if airAmount < 12 && !red {
            // Keep the air label text unchanged but make it transparent
            airLabel.fontColor = UIColor(red: 0.19, green: 0.44, blue: 0.50, alpha: 0.5) // Darker blue with transparency

            // Enlarge and adjust the position of the background and fill
            let enlargeActionBackground = SKAction.scale(to: CGSize(width: 45, height: 165), duration: 0.05)
            let enlargeActionFill = SKAction.scaleX(to: 1.2, duration: 0.05)
            airIconBackground.run(enlargeActionBackground)
            airIconFill.run(enlargeActionFill)
            airIconFill.position = CGPoint(x: airIconBackground.position.x, y: airIconBackground.position.y - 83)

            // Pulsate the background and fill to red
            let redAction = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.5)
            let normalAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.5)
            let pulsateAction = SKAction.sequence([redAction, normalAction])
            airIconFill.run(SKAction.repeatForever(pulsateAction), withKey: "pulsateRed")
            airIconBackground.run(SKAction.repeatForever(pulsateAction), withKey: "pulsateRed")
            red = true
        } else if airAmount >= 12 && red {
            // Reset the visuals for air level above 12
            airLabel.fontColor = UIColor(red: 0.19, green: 0.44, blue: 0.50, alpha: 0.5) // Restore transparency

            let shrinkAction = SKAction.scale(to: CGSize(width: 35, height: 150), duration: 0.05)
            let shrinkActionFill = SKAction.scaleX(to: 1.0, duration: 0.05)
            airIconBackground.run(shrinkAction)
            airIconFill.position = CGPoint(x: airIconBackground.position.x, y: airIconBackground.position.y - 75)
            airIconFill.run(shrinkActionFill)
            airIconBackground.removeAction(forKey: "pulsateRed")
            airIconBackground.colorBlendFactor = 0.0
            airIconFill.removeAction(forKey: "pulsateRed")
            airIconFill.colorBlendFactor = 0.0
            red = false
        }

        // Trigger haptic feedback when air gets critically low
        if airAmount < 6 {
            if !mediumHapticActive { // Prevents multiple haptic generators
                mediumHapticActive = true
                startMediumHapticFeedback()
            }
        } else {
            mediumHapticActive = false // Stops haptic feedback if airAmount goes above 6
        }

        // End the game if airAmount reaches 0
        if airAmount <= 0 {
            mediumHapticActive = false // Ensures haptic stops when game ends
            gameOver(reason: "You Ran Out of Air and Drowned")
        }
    }

    // Property to track haptic state
    var mediumHapticActive = false
    let mediumImpactFeedback = UIImpactFeedbackGenerator(style: .medium) // For medium feedback

    // Function to handle medium haptic feedback
    func startMediumHapticFeedback() {
        DispatchQueue.global().async {
            while self.mediumHapticActive {
                self.mediumImpactFeedback.impactOccurred()
                usleep(500_000) // 0.5-second interval
            }
        }
    }
        
    // Function to increase air by a specific amount
    func increaseAir(by amount: Int) {
        guard !isGameOver else { return }
        
        airAmount += amount
        if airAmount > 30 {
            airAmount = 30 // Cap the air at 30
        }
        // Update air meter
        let scaleFactor = calculateScaleFactor(airAmount: airAmount)
        airIconFill.yScale = scaleFactor
        
        airLabel.text = "\(airAmount)"
    }
    
    /*
    func spawnTemporaryArrow() {
        // Create the temporary arrow
        let temporaryArrow = SKSpriteNode(imageNamed: "Arrow") // Use your arrow asset
        temporaryArrow.size = CGSize(width: 50, height: 50) // Adjust size as needed
        temporaryArrow.zPosition = 1000
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
    */
    
    // Handles player contact with bubbles, enemies, shells, and rocks
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        // Handle contact with enemies
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.enemy) ||
           (bodyA.categoryBitMask == PhysicsCategory.enemy && bodyB.categoryBitMask == PhysicsCategory.box) {
            if !isGameOver {
                // Play the contact sound effect
                playEnemyContactSound()

                // Trigger game over
                gameOver(reason: "A sea creature stopped your adventure!")
            }
        }
        
        // Handle contact with bubbles
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.bubble) ||
           (bodyA.categoryBitMask == PhysicsCategory.bubble && bodyB.categoryBitMask == PhysicsCategory.box) {
            
            // Play the bubble sound effect
            playBubbleSound()
            softImpactFeedback.impactOccurred()
            
            increaseAir(by: 5) // Regular bubble increases air by 5
            
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
                bubbleTextBackground?.removeFromParent()
            }
        }
        
        // Handle contact with GoldBubble
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.GoldBubble) ||
           (bodyA.categoryBitMask == PhysicsCategory.GoldBubble && bodyB.categoryBitMask == PhysicsCategory.box) {
            increaseAir(by: 30) // GoldBubble increases air by 30
            playBubbleSound() // sound for picking up bubbles
            
            // Check which body is the GoldBubble
            let goldBubbleNode: SKNode
            if bodyA.categoryBitMask == PhysicsCategory.GoldBubble {
                goldBubbleNode = bodyA.node!
            } else {
                goldBubbleNode = bodyB.node!
            }
            
            // Remove the GoldBubble from the scene
            goldBubbleNode.removeFromParent()
        }
        
        // Handle contact with shells
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.shell) ||
           (bodyA.categoryBitMask == PhysicsCategory.shell && bodyB.categoryBitMask == PhysicsCategory.box) {
            didBeginShellContact(contact)
        }
        
        // Handle contact with rocks
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.rock) ||
            (bodyA.categoryBitMask == PhysicsCategory.rock && bodyB.categoryBitMask == PhysicsCategory.box) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? OERockNode {
                
                isPlayerOnRock = true
                print("PLAYER ON ROCK")
                if isPlayerOnLava() {
                    print("PLAYER ON LAVA")
                    handleLavaContact()
                }
                
                currentRock = rock
                
                // Correctly place the player on top of the rock
                box?.position.y = rock.position.y + (rock.size.height / 2) + (box?.size.height ?? 0) / 2
                
            }
        }
        
        // Handle contact with rock2
        else if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.rock2) ||
            (bodyA.categoryBitMask == PhysicsCategory.rock2 && bodyB.categoryBitMask == PhysicsCategory.box) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock2 ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? OERockNode2 {
                isPlayerOnRock = true
                print("PLAYER ON ROCK")
                if isPlayerOnLava() {
                    print("PLAYER ON LAVA")
                    handleLavaContact()
                }
                
                currentRock2 = rock

                // Correctly place the player on top of the rock
                box?.position.y = rock.position.y + (rock.size.height / 2) + (box?.size.height ?? 0) / 2
                
                // Determine the closest snap zone
                let playerX = box?.position.x ?? 0
                let rockX = rock.position.x
                let snapToLeft = abs(playerX - (rockX - rock.size.width / 4)) < abs(playerX - (rockX + rock.size.width / 4))
                
                // Snap player to the left or right
                if snapToLeft {
                    currentRockZone = "Left"
                } else {
                    currentRockZone = "Right"
                }
                
            }
            
        }
        
        // Handle contact with rock3
        else if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.rock3) ||
            (bodyA.categoryBitMask == PhysicsCategory.rock3 && bodyB.categoryBitMask == PhysicsCategory.box) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock3 ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? OERockNode3 {
                isPlayerOnRock = true
                print("PLAYER ON ROCK")
                if isPlayerOnLava() {
                    print("PLAYER ON LAVA")
                    handleLavaContact()
                }
                
                currentRock3 = rock

                // Correctly place the player on top of the rock
                box?.position.y = rock.position.y + (rock.size.height / 2) + (box?.size.height ?? 0) / 2
                
                // Calculate distances to each snap zone
                let playerX = box?.position.x ?? 0
                
                let leftDistance = abs(playerX - rock.leftSnapZone.x)
                let centerDistance = abs(playerX - rock.centerSnapZone.x)
                let rightDistance = abs(playerX - rock.rightSnapZone.x)

                // Find the closest zone
                if leftDistance < centerDistance && leftDistance < rightDistance {
                    currentLongRockZone = "Left"
                } else if centerDistance < rightDistance {
                    currentLongRockZone = "Center"
                } else {
                    currentLongRockZone = "Right"
                }
            }
        }
        
        // Handle contact with lava
        else if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.lava) ||
                    (bodyA.categoryBitMask == PhysicsCategory.lava && bodyB.categoryBitMask == PhysicsCategory.box) {
            if !isPlayerOnRock {
                handleLavaContact()

            }
        }
    }
    
    func isPlayerOnLava() -> Bool {
        guard let box = box else { return false }
        let playerPosition = box.position.y
        // Check if the player's position overlaps the lava area
        for lavaPosition in lavaYPositions {
            if playerPosition > lavaPosition - 5 && playerPosition < lavaPosition + 5 && !isPlayerOnRock {
                return true
            }
        }
        return false
    }
    
    func isPlayerOnLavaLane(playerPositionY: CGFloat) -> Bool {
        // Check if the player's position overlaps the lava area
        for lavaPosition in lavaYPositions {
            if playerPositionY > lavaPosition - 5 && playerPositionY < lavaPosition + 5 {
                return true
            }
        }
        return false
    }

    func handleLavaContact() {
        if isPlayerOnRock {
            // Player is safe on the rock
            return
        }
        
        // check if the player dies due to lava
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !self.isGameOver && !self.isPlayerOnRock {
                // Play the "burned" sound only if the player dies
                self.playBurnedSound()
                
                print("PLAYER NOT ON ROCK")
                self.gameOver(reason: "You burned to death underwater!")
            }
        }
    }
    
    func playBackgroundMusic() { // play background music named "music" and loop
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
                backgroundMusicPlayer?.volume = 0.3       // Adjust volume as needed
                backgroundMusicPlayer?.play()
            } catch {
                print("Error playing background music: \(error.localizedDescription)")
            }
        } else {
            print("Background music file not found.")
        }
    }
    
    func stopBackgroundMusic() { // method to stop background music
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func playPufferfishInflateSound() {
        if let soundURL = Bundle.main.url(forResource: "pufferfish", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.75 // Set to maximum volume
                audioPlayer?.play()
            } catch {
                print("Error playing pufferfish inflate sound: \(error.localizedDescription)")
            }
        } else {
            print("Pufferfish sound file not found.")
        }
    }

    func playElectricitySound() {
        if let soundURL = Bundle.main.url(forResource: "electricity", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing gameOver sound: \(error.localizedDescription)")
            }
        } else {
            print("Electricity sound file not found.")
        }
    }

    
    func playGameOverSound() {
        if let soundURL = Bundle.main.url(forResource: "gameOver", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing gameOver sound: \(error.localizedDescription)")
            }
        } else {
            print("Game over sound file not found.")
        }
    }
    
    func playShellPickupSound() {
        if let soundURL = Bundle.main.url(forResource: "shellPickup", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing shellPickup sound: \(error.localizedDescription)")
            }
        } else {
            print("Shell pickup sound file not found.")
        }
    }
    
    func playRockJumpSound() {
        if let soundURL = Bundle.main.url(forResource: "rockjump", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.75 // Set to maximum volume
                audioPlayer?.play()
            } catch {
                print("Error playing rockjump sound: \(error.localizedDescription)")
            }
        } else {
            print("Rockjump sound file not found.")
        }
    }
    
    func playMoveSound() {
    
        AudioServicesPlaySystemSound(playerMovementAudio)
    }
    
    func playBubbleSound() {
        if let soundURL = Bundle.main.url(forResource: "bubble", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.90 // Set to maximum volume
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Bubble sound file not found.")
        }
    }

    func playEnemyContactSound() {
        if let soundURL = Bundle.main.url(forResource: "contact", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Contact sound file not found.")
        }
    }
    
    // Function to play the burned sound
    func playBurnedSound() {
        if let soundURL = Bundle.main.url(forResource: "burned", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Burned sound file not found.")
        }
    }
    
    func playFellSound() {
        if let soundURL = Bundle.main.url(forResource: "falling", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Fell sound file not found.")
        }
    }
    
    func handleSeaweedContact(nextPosition: CGPoint) -> Bool {
        
        // Check for collision with any seaweed node
        let seaweedNodes = children.filter { $0 is OESeaweedNode }
        
        for node in seaweedNodes {
            if let seaweed = node as? OESeaweedNode {
                // Use the node's frame to check for intersection
                if seaweed.frame.contains(nextPosition) {
                    return true // Collision detected
                }
            }
        }
        return false // No collision
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == (PhysicsCategory.box | PhysicsCategory.rock) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB
            if currentRock == rockBody.node as? OERockNode {
                currentRock = nil
                if !isPlayerInContactWithRock() && !isPlayerInContactWithRock2() && !isPlayerInContactWithRock3() {
                    isPlayerOnRock = false
                }
                print("PLAYER HAS LEFT ROCK")
                guard let box = box else { return }
                
                for lane in lanes {
                    if box.position.y > lane.startPosition.y - 5 && box.position.y < lane.startPosition.y + 5 {
                        if abs(box.position.x - round(box.position.x / cellWidth) * cellWidth + cellWidth / 2) > abs(box.position.x - round(box.position.x / cellWidth) * cellWidth - cellWidth / 2) {
                            snapToGrid(position: round(box.position.x / cellWidth) * cellWidth + cellWidth / 2)
                        } else {
                            snapToGrid(position: round(box.position.x / cellWidth) * cellWidth - cellWidth / 2)
                        }
                    }
                }
            }
        }
        
        if collision == (PhysicsCategory.box | PhysicsCategory.rock2) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock2 ? contact.bodyA : contact.bodyB
            if currentRock2 == rockBody.node as? OERockNode2 {
                currentRock2 = nil
                if !isPlayerInContactWithRock() && !isPlayerInContactWithRock2() && !isPlayerInContactWithRock3() {
                    isPlayerOnRock = false
                }
                print("PLAYER HAS LEFT LONG ROCK")
                guard let box = box else { return }
                
                for lane in lanes {
                    if box.position.y > lane.startPosition.y - 5 && box.position.y < lane.startPosition.y + 5 {
                        if abs(box.position.x - round(box.position.x / cellWidth) * cellWidth + cellWidth / 2) > abs(box.position.x - round(box.position.x / cellWidth) * cellWidth - cellWidth / 2) {
                            snapToGrid(position: round(box.position.x / cellWidth) * cellWidth + cellWidth / 2)
                        } else {
                            snapToGrid(position: round(box.position.x / cellWidth) * cellWidth - cellWidth / 2)
                        }
                    }
                }
            }
        }
        
        if collision == (PhysicsCategory.box | PhysicsCategory.rock3) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock3 ? contact.bodyA : contact.bodyB
            if currentRock3 == rockBody.node as? OERockNode3 {
                currentRock3 = nil
                if !isPlayerInContactWithRock() && !isPlayerInContactWithRock2() && !isPlayerInContactWithRock3() {
                    isPlayerOnRock = false
                }
                print("PLAYER HAS LEFT VERY LONG ROCK")
                guard let box = box else { return }
                
                for lane in lanes {
                    if box.position.y > lane.startPosition.y - 5 && box.position.y < lane.startPosition.y + 5 {
                        if lane.laneType != "Lava" {
                            if abs(box.position.x - round(box.position.x / cellWidth) * cellWidth + cellWidth / 2) > abs(box.position.x - round(box.position.x / cellWidth) * cellWidth - cellWidth / 2) {
                                snapToGrid(position: round(box.position.x / cellWidth) * cellWidth + cellWidth / 2)
                            } else {
                                snapToGrid(position: round(box.position.x / cellWidth) * cellWidth - cellWidth / 2)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func isPlayerInContactWithRock() -> Bool {
        guard let box = box else { return false }

        // Get all rock nodes in the scene
        let rocks = self.children.compactMap { $0 as? SKSpriteNode }.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.rock }

        // Check if the player's frame intersects with any rock's frame
        for rock in rocks {
            if box.frame.intersects(rock.frame) {
                print("PLAYER ON ROCK CONFIRMED")
                
                // Play the rock jump sound
                playRockJumpSound()
                
                return true
            }
        }

        return false
    }
    
    func isPlayerInContactWithRock2() -> Bool {
        guard let box = box else { return false }

        // Get all rock2 nodes in the scene
        let rocks = self.children.compactMap { $0 as? SKSpriteNode }.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.rock2 }

        // Check if the player's frame intersects with any rock's frame
        for rock in rocks {
            if box.frame.intersects(rock.frame) {
                print("PLAYER ON ROCK CONFIRMED")
                
                // Play the rock jump sound
                playRockJumpSound()
                
                return true
            }
        }

        return false
    }
    
    func isPlayerInContactWithRock3() -> Bool {
        guard let box = box else { return false }

        // Get all rock3 nodes in the scene
        let rocks = self.children.compactMap { $0 as? SKSpriteNode }.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.rock3 }

        // Check if the player's frame intersects with any rock's frame
        for rock in rocks {
            if box.frame.intersects(rock.frame) {
                print("PLAYER ON ROCK CONFIRMED")
                
                // Play the rock jump sound
                playRockJumpSound()
                
                return true
            }
        }

        return false
    }

    func snapToGrid(position: CGFloat) {
        
        guard let box = box else { return }
        
        box.snapToGrid(xPosition: position)
        playerNextPosition.x = position
    }
    
    func showStartOverlay() {
        // Create semi-transparent black background
        let backgroundBox = SKShapeNode(rectOf: CGSize(width: 1000, height: 1000))
        backgroundBox.name = "backgroundBox"
        backgroundBox.position = CGPoint(x: 0, y: 0) // Centered on screen
        backgroundBox.fillColor = .black
        backgroundBox.alpha = 0.7 // Set appropriate opacity
        backgroundBox.zPosition = 1001 // Ensure it is behind the text but above other nodes
        cameraNode.addChild(backgroundBox)

        // Add the game logo
        let logoTexture = SKTexture(imageNamed: "Logo1")
        let logoSprite = SKSpriteNode(texture: logoTexture)
        logoSprite.name = "logoSprite"

        logoSprite.position = CGPoint(x: 0, y: 240) // Positioned above the "Tap to Begin" text
        logoSprite.zPosition = 1002 // Make logo be the top visible layer
        logoSprite.xScale = 0.4 // Scale width to 60%
        logoSprite.yScale = 0.4 // Scale height to 60%

        cameraNode.addChild(logoSprite)

        // Display "Tap to Begin" message
        let startLabel = SKLabelNode(text: "Tap to Begin")
        startLabel.name = "startLabel"
        startLabel.fontSize = 38
        startLabel.fontColor = .white
        startLabel.zPosition = 1002 // Ensure top visibility
        startLabel.fontName = "Arial-BoldMT" // Use bold font
        startLabel.position = CGPoint(x: 0, y: 40) // Centered on screen
        cameraNode.addChild(startLabel)
    }
    
    func gameOver(reason: String) {
        isGameOver = true
        mediumHapticActive = false // Ensures haptic stops incase u die whilst on low air

        heavyImpactFeedback.impactOccurred()
        cameraNode.removeAllActions() // Stop camera movement
        removeAction(forKey: "spawnEnemies") // Stop spawning enemies

        // Stop the background music
        stopBackgroundMusic()
        
        // Delay the game over sound effect by 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            self.playGameOverSound()
        }
        
        // Create a background sprite for the end screen using the ocean image
        let backgroundSprite = SKSpriteNode(imageNamed: "gameOver")
        backgroundSprite.position = CGPoint(x: 0, y: 0) // Centered on screen
        backgroundSprite.zPosition = 1100 // Ensure it is behind the text but above other nodes
        backgroundSprite.size = self.size // Adjust to fill the screen
        cameraNode.addChild(backgroundSprite)

        // Add the game logo
        let logoTexture = SKTexture(imageNamed: "Logo1")
        let logoSprite = SKSpriteNode(texture: logoTexture)
        logoSprite.position = CGPoint(x: 0, y: 270) // Positioned above the reason text
        logoSprite.zPosition = 1101 // Make logo be the top visible layer
        logoSprite.xScale = 0.35 // Scale width
        logoSprite.yScale = 0.35 // Scale height
        
        cameraNode.addChild(logoSprite)

        // Save the current score
        let finalScore = score

        // Display Final Score
        let finalScoreLabel = SKLabelNode(text: "Score: \(finalScore)")
        finalScoreLabel.fontSize = 38
        finalScoreLabel.fontColor = .white
        finalScoreLabel.zPosition = 1101 // Make text be the top visible layer
        finalScoreLabel.fontName = "Helvetica Neue Bold" // Use bold font
        finalScoreLabel.position = CGPoint(x: 0, y: 40) // Positioned just below the reason text
        cameraNode.addChild(finalScoreLabel)
        
        // Display the reason for game over
        let reasonLabel = SKLabelNode(text: reason)
        reasonLabel.fontSize = 19
        reasonLabel.fontColor = .white
        reasonLabel.zPosition = 1101 // Ensure top visibility
        reasonLabel.fontName = "Helvetica Neue Bold" // Use bold font
        reasonLabel.position = CGPoint(x: 0, y: 90) // Centered on screen
        cameraNode.addChild(reasonLabel)
        
        // Display asset based on reason
        let reasonAsset: SKSpriteNode
        switch reason {
        case "You burned to death underwater!":
            reasonAsset = SKSpriteNode(imageNamed: "endGameBurned")
        case "A sea creature stopped your adventure!":
            reasonAsset = SKSpriteNode(imageNamed: "endGameContact")
        case "You Ran Out of Air and Drowned":
            reasonAsset = SKSpriteNode(imageNamed: "endGameDrowned")
        case "You were swept away by the rocks!":
            reasonAsset = SKSpriteNode(imageNamed: "endGameFell")
        case "You sank into the depths and disappeared!":
            reasonAsset = SKSpriteNode(imageNamed: "endGameFell")
        default:
            reasonAsset = SKSpriteNode() // Fallback to an empty node
        }
        
        // Position the reason asset below the final score
        reasonAsset.position = CGPoint(x: 0, y: -50)
        reasonAsset.zPosition = 1101
        reasonAsset.xScale = 1.0 // Adjust scale as needed
        reasonAsset.yScale = 1.0
        cameraNode.addChild(reasonAsset)

        // Display "Tap to Restart" message
        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 20
        restartLabel.fontColor = .white
        restartLabel.zPosition = 1101 // Make text be the top visible layer
        restartLabel.fontName = "Arial-BoldMT" // Use bold font
        restartLabel.position = CGPoint(x: 0, y: -350) // Positioned below the final score
        cameraNode.addChild(restartLabel)

        // Pause the scene to stop further actions
        self.isPaused = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver{
            restartGame()
        }
        else if !hasGameStarted {
            removeOverlay()
            startGame()
        }
    }
    
    func removeOverlay(){
        cameraNode.childNode(withName: "backgroundBox")?.removeFromParent()
        cameraNode.childNode(withName: "logoSprite")?.removeFromParent()
        cameraNode.childNode(withName: "startLabel")?.removeFromParent()
        
    }
    func startGame() {
        hasGameStarted = true
        
        playBackgroundMusic() //play background music
        
        score = 1 // Ensure score is greater than 0 to start
        // Start camera movement and air countdown
        setupAirDisplay()
        airCountDown()
        startCameraMovement()
        
        includeBubbles()
        includeShells()
        setupReef()
    }
    
    func restartGame() {
        // Clear all nodes and actions from the current scene
        removeAllActions()
        removeAllChildren()
        
        // Reset the game state
        isGameOver = false
        score = 0
        airAmount = 25

        // Load a new instance of the scene
        let newScene = OEGameScene(context: context!, size: size)
        newScene.scaleMode = .aspectFill
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
        
        // Start the background music
        playBackgroundMusic()
    }

}
