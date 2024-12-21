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
    static let coral: UInt32 = 0b100000000000 
}

struct Lane {
    let startPosition: CGPoint
    let endPosition: CGPoint
    let direction: CGVector
    var speed: CGFloat
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

// haptics for rumble
func quickRumbleEffect() {
    // Use multiple generators for varying intensities
    let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    lightGenerator.prepare()
    mediumGenerator.prepare()
    heavyGenerator.prepare()
    
    // Sequence of impacts to simulate a rumble
    let sequence: [(UIImpactFeedbackGenerator, Double)] = [
        (heavyGenerator, 0.0),  // Start with heavy
        (mediumGenerator, 0.05), // Medium after 50ms
        (lightGenerator, 0.1),  // Light after 100ms
        (heavyGenerator, 0.15), // Heavy after 150ms
        (mediumGenerator, 0.2), // Medium after 200ms
        (lightGenerator, 0.25)  // Light after 250ms
    ]
    
    for (generator, delay) in sequence {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            generator.impactOccurred()
        }
    }
}

    
@available(iOS 17.0, *)
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
    
    // To lock the tapping at the end of the game
    var isInputLocked = false
    
    // Score properties
    var score = 0
    var scoreDisplayed = 0
    var scoreLabel: SKLabelNode!
    
    // Air properties
    var airAmount = 20
    var o2Icon: SKSpriteNode?
    var airLabel: SKLabelNode!
    var airIconBackground: SKSpriteNode!
    var airIconFill: SKSpriteNode!
    var airIconTicks : SKSpriteNode!
    var firstBubble: SKSpriteNode? = nil
    var arrow: SKSpriteNode?
    var bubbleText: SKLabelNode?
    var bubbleTextBackground: SKShapeNode?
    var red = false
    
    var warningIcon: SKSpriteNode?

    
    // Tapping properties
    var tapQueue: [CGPoint] = [] // Queue to hold pending tap positions
    var isActionInProgress = false // Flag to indicate if a movement is in progress
    
    var playerNextPosition: CGPoint = .zero
    var playerNextX: CGFloat = -100000
    
    // Game state variable
    var isGameOver = false
    var lanes: [Lane] = []  // Added this line to define lanes
    var laneDirection: Int = 0
    var prevLane: Lane? = nil
    
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
    var heartbeatSound: SystemSoundID = 0
    var rockSound: SystemSoundID = 0
    var bubbleSound: SystemSoundID = 0
    var shellPickup: SystemSoundID = 0
    var falling: SystemSoundID = 0
    var pufferfish: SystemSoundID = 0

    
    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        self.scaleMode = .aspectFill

        isPlayerOnRock = false
        currentRock = nil
        currentRock2 = nil
        currentRock3 = nil
        currentRockZone = ""
        currentLongRockZone = ""
        
        // Initially slow rock speed
        currentRockSpeed = "Slow"
 
        // FOR MOVE SOUND
        guard let url = Bundle.main.url(forResource: "move", withExtension: "mp3") else {
                return
            }
            let osstatus2 = AudioServicesCreateSystemSoundID(url as CFURL, &playerMovementAudio)
            if osstatus2 != noErr { // or kAudioServicesNoError. same thing.
                print("could not create system sound")
                print("osstatus2: \(osstatus2)")
            }
        
        // FOR BUBBLE SOUND
        guard let url = Bundle.main.url(forResource: "bubble", withExtension: "mp3") else {
                print("Bubble sound file not found.")
                return
            }
        
            let osstatus4 = AudioServicesCreateSystemSoundID(url as CFURL, &bubbleSound)
            if osstatus4 != noErr { // or kAudioServicesNoError
                print("Could not create system sound. osstatus4: \(osstatus4)")
            }
        
        // FOR ROCK JUMP SOUND
            guard let url = Bundle.main.url(forResource: "rockjump", withExtension: "mp3") else {
                print("Rockjump sound file not found.")
                return
            }

            let osstatus3 = AudioServicesCreateSystemSoundID(url as CFURL, &rockSound)
            if osstatus3 != noErr { // or kAudioServicesNoError
                print("Could not create system sound. osstatus3: \(osstatus3)")
            }
        
        // FOR SHELL PICKUP SOUND
        guard let url = Bundle.main.url(forResource: "shellPickup", withExtension: "mp3") else {
                print("Shell pickup sound file not found.")
                return
            }
            let osstatus6 = AudioServicesCreateSystemSoundID(url as CFURL, &shellPickup)
            if osstatus6 != noErr { // or kAudioServicesNoError
                print("Could not create system sound. osstatus6: \(osstatus6)")
            }
        
        // FOR PUFFER
        guard let url = Bundle.main.url(forResource: "pufferfish", withExtension: "mp3") else {
                print("Shell pickup sound file not found.")
                return
            }
            let osstatus8 = AudioServicesCreateSystemSoundID(url as CFURL, &pufferfish)
            if osstatus8 != noErr { // or kAudioServicesNoError
                print("Could not create system sound. osstatus8: \(osstatus8)")
            }
        
        
        // FOR HEARTBEAT SOUND
        guard let url = Bundle.main.url(forResource: "heartbeat", withExtension: "mp3") else {
                return
            }
            let osstatus = AudioServicesCreateSystemSoundID(url as CFURL, &heartbeatSound)
            if osstatus != noErr { // or kAudioServicesNoError. same thing.
                    print("could not create system sound")
                    print("osstatus: \(osstatus)")
            }
        
        // FOR FALLING SOUND
        guard let url = Bundle.main.url(forResource: "falling", withExtension: "mp3") else {
                print("Falling sound file not found.")
                return
            }

            let osstatus7 = AudioServicesCreateSystemSoundID(url as CFURL, &falling)
            if osstatus7 != noErr {
                print("Could not create system sound. osstatus7: \(osstatus7)")
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
        }
        
        for i in 1..<lanes.count {
            if lanes[i - 1].laneType == "Lava" && lanes[i].laneType != "Lava" {
                if lanes[i - 1].speed > 12 {
                    lanes[i].speed = CGFloat.random(in: 6...7)
                } else {
                    lanes[i].speed = CGFloat.random(in: 10...13)
                }
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
        let backgroundNode = SKSpriteNode(imageNamed: "OEBackground")
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
        let reef = SKSpriteNode(imageNamed: "OEReef")
        
        // Adjust position as needed
        reef.position = CGPoint(x: size.width / 350, y: reef.size.height / 20 - size.height / 32)
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
        guard let box = box else { return }
        score = box.getScore()

        // Trigger the popup effect when the score is a multiple of 10
        if score % 10 == 0 && score != scoreDisplayed {
            scoreLabel.removeAction(forKey: "popOut") // Remove any ongoing pop-out action
            scoreLabel.run(createPopOutAction(), withKey: "popOut")
        }

        // Update displayed score
        if score >= scoreDisplayed + 1 {
            scoreDisplayed += 1
        }

        // Update font colors and effects
        if score % 100 == 0 {
            scoreLabel.fontColor = .red // Highlight for multiples of 100
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
        let scaleUp = SKAction.scale(to: 1.45, duration: 0.10)  // Increase to 1.5 scale, slightly slower
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.10) // Return to normal size
        return SKAction.sequence([scaleUp, scaleDown])
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
        
        score = box.getScore()
        
        updateScore()
        
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
        
        let screenBottom = (camera?.position.y ?? 0) - size.height
        
        // Check for proximity to player for each pufferfish enemy
        for child in children {
            if let pufferfish = child as? OEEnemyNode2 {
                pufferfish.checkProximityToPlayer(playerPosition: box.position)
            }
            
            let nodePositionInScene = child.convert(child.position, to: self)

            if nodePositionInScene.y < screenBottom && child.name != "lane" {
                child.removeFromParent()
            }
        }
        
        // Game over if the character falls below the camera's view
        if box.position.y < cameraNode.position.y - size.height / 2 {
            // Play the "fell" sound effect
            playFellSound()
            startMediumHapticFeedback()
            
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
            
            let laneSet = Int.random(in: 0..<laneDifficulty.count)
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
        }
        
        // Update global lanes with new Lanes
        lanes.append(contentsOf: newLanes)
        
        for i in (lanes.count - newLanes.count)..<lanes.count {
            if lanes[i - 1].laneType == "Lava" && lanes[i].laneType != "Lava" {
                if lanes[i - 1].speed > 12 {
                    lanes[i].speed = CGFloat.random(in: 6.5...9)
                } else {
                    lanes[i].speed = CGFloat.random(in: 10...13)
                }
            }
        }
        
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
        
        guard let box, !isInputLocked, !isGameOver else { return }
        // Haptic feedback for each movement
      //  softImpactFeedback.impactOccurred()
        if playerNextX != -100000 {
            playerNextPosition.x = playerNextX
            playerNextX = -100000
        }
        
        
        print("SETTING ROCKS TO NIL")
        currentRock = nil
        currentRock2 = nil
        currentRock3 = nil
        
        
        isPlayerOnRock = false
        
        var didMoveToRock = false
        
        for node in children {
            
            if let rock = node as? OERockNode {
                                    
                let dx = rock.velocity * CGFloat(0.15)
                let rockPositionX = rock.position.x + dx
                
                if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                    isPlayerOnRock = true
                    let nextPosition = CGPoint(x: rockPositionX, y: self.playerNextPosition.y + self.cellHeight)
                    self.playerNextPosition = nextPosition
                    self.isPlayerOnRock = true
                    box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                    self.updateScore()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                        self.playRockJumpSound()

                        if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                            print("SET ROCK")
                            self.currentRock = rock
                            self.handleLavaContact()
                        }

                    }
                
                    didMoveToRock = true
                    return
                }
            }
            
            if let rock = node as? OERockNode2 {
                                    
                let dx = rock.velocity * CGFloat(0.15)
                let rockPositionX = rock.position.x + dx
                
                if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                    isPlayerOnRock = true
                    print("ROCK2 IDENTIFIED")
                    let playerX = box.position.x
                    let rockX = rockPositionX
                    let snapToLeft = abs(playerX - (rockX - rock.size.width / 4)) < abs(playerX - (rockX + rock.size.width / 4))
                    
                    if snapToLeft {
                        currentRockZone = "Left"
                        let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.2, y: self.playerNextPosition.y + self.cellHeight)
                        self.playerNextPosition = nextPosition
                        print("MOVING TO LEFT ZONE")
                        self.isPlayerOnRock = true
                        box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                        self.updateScore()
                        didMoveToRock = true
                        handleLavaContact()
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                            self.playRockJumpSound()

                            if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                print("SET ROCK2")
                                self.currentRock2 = rock
                                self.handleLavaContact()
                            }

                        }
                        return
                    } else {
                        currentRockZone = "Right"
                        let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.2, y: self.playerNextPosition.y + self.cellHeight)
                        self.playerNextPosition = nextPosition
                        print("MOVING TO RIGHT ZONE")
                        self.isPlayerOnRock = true
                        box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                        self.updateScore()
                        didMoveToRock = true
                        handleLavaContact()
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                            self.playRockJumpSound()

                            if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                print("SET ROCK2")
                                self.currentRock2 = rock
                                self.handleLavaContact()
                            }

                        }
                        return
                    }
                }
            }
            
            if let rock = node as? OERockNode3 {
                                    
                let dx = rock.velocity * CGFloat(0.15)
                let rockPositionX = rock.position.x + dx
                
                if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                    isPlayerOnRock = true

                    let playerX = box.position.x
                    
                    let leftDistance = abs(playerX - rockPositionX - rock.size.width * 0.25)
                    let centerDistance = abs(playerX - rockPositionX)
                    let rightDistance = abs(playerX - rockPositionX + rock.size.width * 0.25)

                    // Find the closest zone
                    if leftDistance < centerDistance && leftDistance < rightDistance {
                        currentLongRockZone = "Right"
                        print("MOVING TO Right ZONE")
                        let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.25, y: playerNextPosition.y + self.cellHeight)
                        self.playerNextPosition = nextPosition
                        isPlayerOnRock = true
                        box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                        self.updateScore()
                        didMoveToRock = true
                        handleLavaContact()
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                            self.playRockJumpSound()

                            if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                print("SET ROCK3")
                                self.currentRock3 = rock
                                self.handleLavaContact()
                            }

                        }
                        return
                    } else if centerDistance < rightDistance {
                        currentLongRockZone = "Center"
                        print("MOVING TO CENTER ZONE")
                        let nextPosition = CGPoint(x: rockPositionX, y: playerNextPosition.y + self.cellHeight)
                        self.playerNextPosition = nextPosition
                        isPlayerOnRock = true
                        box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                        self.updateScore()
                        didMoveToRock = true
                        handleLavaContact()
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                            self.playRockJumpSound()

                            if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                print("SET ROCK3")
                                self.currentRock3 = rock
                                self.handleLavaContact()
                            }

                        }
                        return
                    } else {
                        currentLongRockZone = "Left"
                        print("MOVING TO LEFT ZONE")
                        let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.25, y: playerNextPosition.y + self.cellHeight)
                        self.playerNextPosition = nextPosition
                        box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                        self.updateScore()
                        didMoveToRock = true
                        isPlayerOnRock = true
                        handleLavaContact()
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                            if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                self.playRockJumpSound()

                                print("SET ROCK3")
                                self.currentRock3 = rock
                                self.handleLavaContact()
                            }

                        }
                        return
                    }
                }
                
            }
        }
        
        
        print(didMoveToRock)
        print(isPlayerOnLavaLane(playerPositionY: playerNextPosition.y + cellHeight))
        if !didMoveToRock && isPlayerOnLavaLane(playerPositionY: playerNextPosition.y + cellHeight) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.playBurnedSound()
                self.dissolveCharacter(box)
                self.gameOver(reason: "You burned to death underwater!")
            }
        }
        
        for i in 0..<lanes.count {
            if playerNextPosition.y > lanes[i].startPosition.y - 10 && playerNextPosition.y < lanes[i].startPosition.y + 10 {
                print("CURRENT LANE FOUND")
                if lanes[i].laneType == "Lava" && lanes[i+1].laneType != "Lava" {
                    print("NEXT LANE IDENTIFIED-NOT LAVA")
                    if abs(box.position.x - round(box.position.x / cellWidth) * cellWidth + cellWidth / 2) > abs(box.position.x - round(box.position.x / cellWidth) * cellWidth - cellWidth / 2) {
                        let nextPosition = CGPoint(x: round(box.position.x / cellWidth) * cellWidth + cellWidth / 2, y: playerNextPosition.y + cellHeight)
                        playerNextPosition = nextPosition
                        playerNextX = playerNextPosition.x
                        box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Up")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            self.handleLavaContact()
                        }
                        updateScore()
                        isPlayerOnRock = false
                        return
                    } else {
                        let nextPosition = CGPoint(x: round(box.position.x / cellWidth) * cellWidth - cellWidth / 2, y: playerNextPosition.y + cellHeight)
                        playerNextPosition = nextPosition
                        playerNextX = playerNextPosition.x
                        box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Up")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            self.handleLavaContact()
                        }
                        updateScore()
                        isPlayerOnRock = false
                        return
                    }
                }
            }
        }
        print("I MADE IT")
        let nextPosition = CGPoint(x: playerNextPosition.x, y: playerNextPosition.y + cellHeight)
        if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x, y: playerNextPosition.y + cellHeight)) {
            playerNextPosition.y += cellHeight
            
            
            // Play the move sound effect
            playMoveSound()
            
            // If an action is already in progress, queue the next tap position
            print("QUEUING MOVEMENT")
            tapQueue.append(playerNextPosition)
            box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Up")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.handleLavaContact()
            }
            updateScore()
            handleLavaContact()
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        
        if playerNextX != -100000 {
            playerNextPosition.x = playerNextX
            playerNextX = -100000
        }
        
        var hitSeaweed = false
        if isActionInProgress {
            return
        }
        
        guard let box, !isInputLocked, !isGameOver else { return }
        
        var nextPosition: CGPoint
        // softImpactFeedback.impactOccurred() // HAPTICS for swiping left/right
        switch sender.direction {
            
        case.up:
         
            print("SETTING ROCKS TO NIL")
            currentRock = nil
            currentRock2 = nil
            currentRock3 = nil
            
            
            isPlayerOnRock = false
            
            var didMoveToRock = false
            
            for node in children {
                
                if let rock = node as? OERockNode {
                                        
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    
                    if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                        isPlayerOnRock = true
                        let nextPosition = CGPoint(x: rockPositionX, y: self.playerNextPosition.y + self.cellHeight)
                        self.playerNextPosition = nextPosition
                        self.isPlayerOnRock = true
                        box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                        self.updateScore()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                            if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                print("SET ROCK")
                                self.currentRock = rock
                                self.handleLavaContact()
                                self.playRockJumpSound()
                            }

                        }
                    
                        didMoveToRock = true
                        return
                    }
                }
                
                if let rock = node as? OERockNode2 {
                                        
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    
                    if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                        isPlayerOnRock = true
                        print("ROCK2 IDENTIFIED")
                        let playerX = box.position.x
                        let rockX = rockPositionX
                        let snapToLeft = abs(playerX - (rockX - rock.size.width / 4)) < abs(playerX - (rockX + rock.size.width / 4))
                        
                        if snapToLeft {
                            currentRockZone = "Left"
                            let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.2, y: self.playerNextPosition.y + self.cellHeight)
                            self.playerNextPosition = nextPosition
                            print("MOVING TO LEFT ZONE")
                            self.isPlayerOnRock = true
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                            self.updateScore()
                            didMoveToRock = true
                            handleLavaContact()
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                    print("SET ROCK2")
                                    self.currentRock2 = rock
                                    self.handleLavaContact()
                                    self.playRockJumpSound()
                                }

                            }
                            return
                        } else {
                            currentRockZone = "Right"
                            let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.2, y: self.playerNextPosition.y + self.cellHeight)
                            self.playerNextPosition = nextPosition
                            print("MOVING TO RIGHT ZONE")
                            self.isPlayerOnRock = true
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                            self.updateScore()
                            didMoveToRock = true
                            handleLavaContact()
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                    print("SET ROCK2")
                                    self.currentRock2 = rock
                                    self.handleLavaContact()
                                    self.playRockJumpSound()
                                }

                            }
                            return
                        }
                    }
                }
                
                if let rock = node as? OERockNode3 {
                                        
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    
                    if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                        isPlayerOnRock = true

                        let playerX = box.position.x
                        
                        let leftDistance = abs(playerX - rockPositionX - rock.size.width * 0.25)
                        let centerDistance = abs(playerX - rockPositionX)
                        let rightDistance = abs(playerX - rockPositionX + rock.size.width * 0.25)

                        // Find the closest zone
                        if leftDistance < centerDistance && leftDistance < rightDistance {
                            currentLongRockZone = "Right"
                            print("MOVING TO Right ZONE")
                            let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.25, y: playerNextPosition.y + self.cellHeight)
                            self.playerNextPosition = nextPosition
                            isPlayerOnRock = true
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                            self.updateScore()
                            didMoveToRock = true
                            handleLavaContact()
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                    print("SET ROCK3")
                                    self.currentRock3 = rock
                                    self.handleLavaContact()
                                    self.playRockJumpSound()
                                }

                            }
                            return
                        } else if centerDistance < rightDistance {
                            currentLongRockZone = "Center"
                            print("MOVING TO CENTER ZONE")
                            let nextPosition = CGPoint(x: rockPositionX, y: playerNextPosition.y + self.cellHeight)
                            self.playerNextPosition = nextPosition
                            isPlayerOnRock = true
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                            self.updateScore()
                            didMoveToRock = true
                            handleLavaContact()
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                    print("SET ROCK3")
                                    self.currentRock3 = rock
                                    self.handleLavaContact()
                                    self.playRockJumpSound()
                                }

                            }
                            return
                        } else {
                            currentLongRockZone = "Left"
                            print("MOVING TO LEFT ZONE")
                            let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.25, y: playerNextPosition.y + self.cellHeight)
                            self.playerNextPosition = nextPosition
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Up")
                            self.updateScore()
                            didMoveToRock = true
                            isPlayerOnRock = true
                            handleLavaContact()
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                if self.isPlayerOnLavaLane(playerPositionY: self.playerNextPosition.y) {
                                    print("SET ROCK3")
                                    self.currentRock3 = rock
                                    self.handleLavaContact()
                                    self.playRockJumpSound()
                                }

                            }
                            return
                        }
                    }
                    
                }
            }
            
            
            print(didMoveToRock)
            print(isPlayerOnLavaLane(playerPositionY: playerNextPosition.y + cellHeight))
            if !didMoveToRock && isPlayerOnLavaLane(playerPositionY: playerNextPosition.y + cellHeight) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.playBurnedSound()
                    self.dissolveCharacter(box)
                    self.gameOver(reason: "You burned to death underwater!")
                }
            }
            
            for i in 0..<lanes.count {
                if playerNextPosition.y > lanes[i].startPosition.y - 10 && playerNextPosition.y < lanes[i].startPosition.y + 10 {
                    print("CURRENT LANE FOUND")
                    if lanes[i].laneType == "Lava" && lanes[i+1].laneType != "Lava" {
                        print("NEXT LANE IDENTIFIED-NOT LAVA")
                        if abs(box.position.x - round(box.position.x / cellWidth) * cellWidth + cellWidth / 2) > abs(box.position.x - round(box.position.x / cellWidth) * cellWidth - cellWidth / 2) {
                            let nextPosition = CGPoint(x: round(box.position.x / cellWidth) * cellWidth + cellWidth / 2, y: playerNextPosition.y + cellHeight)
                            playerNextPosition = nextPosition
                            playerNextX = playerNextPosition.x
                            box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Up")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                self.handleLavaContact()
                            }
                            updateScore()
                            isPlayerOnRock = false
                            return
                        } else {
                            let nextPosition = CGPoint(x: round(box.position.x / cellWidth) * cellWidth - cellWidth / 2, y: playerNextPosition.y + cellHeight)
                            playerNextPosition = nextPosition
                            playerNextX = playerNextPosition.x
                            box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Up")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                self.handleLavaContact()
                            }
                            updateScore()
                            isPlayerOnRock = false
                            return
                        }
                    }
                }
            }
            print("I MADE IT")
            let nextPosition = CGPoint(x: playerNextPosition.x, y: playerNextPosition.y + cellHeight)
            if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x, y: playerNextPosition.y + cellHeight)) {
                playerNextPosition.y += cellHeight
                
                
                // Play the move sound effect
                playMoveSound()
                
                // If an action is already in progress, queue the next tap position
                print("QUEUING MOVEMENT")
                tapQueue.append(playerNextPosition)
                box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Up")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.handleLavaContact()
                }
                updateScore()
                handleLavaContact()
            }
            
            return

        case .down:
    
            if handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x, y: playerNextPosition.y - cellHeight)) {
                return
            }
            
            print("SETTING ROCKS TO NIL")
            currentRock = nil
            currentRock2 = nil
            currentRock3 = nil
            isPlayerOnRock = false
            
            if playerNextX != -100000 {
                playerNextPosition.x = playerNextX
                playerNextX = -100000
            }
     
            var didMoveToRock = false
            
            for node in children {
                
                if let rock = node as? OERockNode {
                                            
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    
                    if playerNextPosition.y - self.cellHeight > rock.position.y - 5 && playerNextPosition.y - self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                        isPlayerOnRock = true

                        let nextPosition = CGPoint(x: rockPositionX, y: self.playerNextPosition.y - self.cellHeight)
                        self.playerNextPosition = nextPosition
                        box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Rock")
                        self.isPlayerOnRock = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                            print("SETTING CURRENTROCK")
                            self.currentRock = rock
                            self.handleLavaContact()
                            self.playRockJumpSound()
                        }
                        didMoveToRock = true
                        return
                    }
                }
                
                if let rock = node as? OERockNode2 {
                                            
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    
                    if playerNextPosition.y - self.cellHeight > rock.position.y - 5 && playerNextPosition.y - self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                        isPlayerOnRock = true

                        print("ROCK2 IDENTIFIED")
                        let playerX = box.position.x
                        let rockX = rockPositionX
                        let snapToLeft = abs(playerX - (rockX - rock.size.width / 4)) < abs(playerX - (rockX + rock.size.width / 4))
                        
                        if snapToLeft {
                            currentRockZone = "Left"
                            let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.2, y: self.playerNextPosition.y - self.cellHeight)
                            self.playerNextPosition = nextPosition
                            print("MOVING TO LEFT ZONE")
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Rock")
                            didMoveToRock = true
                            isPlayerOnRock = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                print("SETTING CURRENTROCK2")
                                self.currentRock2 = rock
                                self.handleLavaContact()
                                self.playRockJumpSound()
                            }
                            return
                        } else {
                            currentRockZone = "Right"
                            let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.2, y: self.playerNextPosition.y - self.cellHeight)
                            self.playerNextPosition = nextPosition
                            print("MOVING TO RIGHT ZONE")
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Rock")
                            didMoveToRock = true
                            isPlayerOnRock = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                print("SETTING CURRENTROCK2")
                                self.currentRock2 = rock
                                self.handleLavaContact()
                                self.playRockJumpSound()
                            }
                            return
                        }
                    }
                }
                
                if let rock = node as? OERockNode3 {
                                            
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    
                    if playerNextPosition.y - self.cellHeight > rock.position.y - 5 && playerNextPosition.y - self.cellHeight < rock.position.y + 5 && box.position.x > rockPositionX - rock.size.width * 0.65 && box.position.x < rockPositionX + rock.size.width * 0.65 {
                        isPlayerOnRock = true

                        let playerX = box.position.x
                        
                        let leftDistance = abs(playerX - rockPositionX - rock.size.width * 0.25)
                        let centerDistance = abs(playerX - rockPositionX)
                        let rightDistance = abs(playerX - rockPositionX + rock.size.width * 0.25)

                        // Find the closest zone
                        if leftDistance < centerDistance && leftDistance < rightDistance {
                            currentLongRockZone = "Right"
                            print("MOVING TO RIGHT ZONE")
                            let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.25, y: playerNextPosition.y - self.cellHeight)
                            self.playerNextPosition = nextPosition
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Rock")
                            didMoveToRock = true
                            isPlayerOnRock = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                print("SETTING CURRENTROCK3")
                                self.currentRock3 = rock
                                self.handleLavaContact()
                                self.playRockJumpSound()
                            }
                            return
                        } else if centerDistance < rightDistance {
                            currentLongRockZone = "Center"
                            print("MOVING TO CENTER ZONE")
                            let nextPosition = CGPoint(x: rockPositionX, y: playerNextPosition.y - self.cellHeight)
                            self.playerNextPosition = nextPosition
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Rock")
                            didMoveToRock = true
                            isPlayerOnRock = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                print("SETTING CURRENTROCK3")
                                self.currentRock3 = rock
                                self.handleLavaContact()
                                self.playRockJumpSound()
                            }
                            return
                        } else {
                            currentLongRockZone = "Left"
                            print("MOVING TO LEFT ZONE")
                            let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.25, y: playerNextPosition.y - self.cellHeight)
                            self.playerNextPosition = nextPosition
                            box.hop(to: nextPosition, inQueue: self.playerNextPosition, up: "Rock")
                            didMoveToRock = true
                            isPlayerOnRock = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.15 + 0.1 * Double((box.getMovementQueueLength())))) {
                                print("SETTING CURRENTROCK3")
                                self.currentRock3 = rock
                                self.handleLavaContact()
                                self.playRockJumpSound()
                            }
                            return
                        }
                    }
                    
                }
            }
            
            
            print(didMoveToRock)
            print(isPlayerOnLavaLane(playerPositionY: playerNextPosition.y - cellHeight))
            if !didMoveToRock && isPlayerOnLavaLane(playerPositionY: playerNextPosition.y - cellHeight) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.playBurnedSound()
                    self.dissolveCharacter(box)
                    self.gameOver(reason: "You burned to death underwater!")
                }
            }
            
            if didMoveToRock {
                playRockJumpSound()
            }
            
            for i in 0..<lanes.count {
                if playerNextPosition.y > lanes[i].startPosition.y - 10 && playerNextPosition.y < lanes[i].startPosition.y + 10 {
                    print("CURRENT LANE FOUND")
                    if lanes[i].laneType == "Lava" && lanes[i-1].laneType != "Lava" {
                        print("NEXT LANE IDENTIFIED-NOT LAVA")
                        if abs(box.position.x - round(box.position.x / cellWidth) * cellWidth + cellWidth / 2) > abs(box.position.x - round(box.position.x / cellWidth) * cellWidth - cellWidth / 2) {
                            let nextPosition = CGPoint(x: round(box.position.x / cellWidth) * cellWidth + cellWidth / 2, y: playerNextPosition.y - cellHeight)
                            playerNextPosition = nextPosition
                            playerNextX = playerNextPosition.x
                            box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Down")
                            isPlayerOnRock = false
                            return
                        } else {
                            let nextPosition = CGPoint(x: round(box.position.x / cellWidth) * cellWidth - cellWidth / 2, y: playerNextPosition.y - cellHeight)
                            playerNextPosition = nextPosition
                            playerNextX = playerNextPosition.x
                            box.hop(to: nextPosition, inQueue: playerNextPosition, up: "Down")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                self.handleLavaContact()
                            }
                            isPlayerOnRock = false
                            return
                        }
                    }
                }
            }
            nextPosition = CGPoint(x: box.position.x, y: playerNextPosition.y - cellHeight)
            if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x, y: playerNextPosition.y - cellHeight)) {
                playerNextPosition.y -= cellHeight
                playMoveSound()
            } else {
                hitSeaweed = true
            }
            handleLavaContact()
        case .left:
          
            nextPosition = CGPoint(x: playerNextPosition.x - cellWidth, y: box.position.y)
            // Check the column the player is moving into
            let targetColumn = gridPosition(for: nextPosition).column
            if targetColumn == -4 {
                return // Stop movement
            }
            
            if box.getIsMoving() || box.getMovementQueueLength() > 0 {
                return
            }
            
            if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x - cellWidth, y: playerNextPosition.y)) && !box.getIsMoving() && !isPlayerOnRock {
                print(isActionInProgress)
                print("MOVING LEFT")
                playerNextPosition.x -= cellWidth
                playMoveSound()
            } else {
                hitSeaweed = true
            }

            if currentRock2 != nil && currentRockZone == "Right" {
                
                guard let rock = currentRock2 else { return }
                let dx = rock.velocity * CGFloat(0.15)
                let rockPositionX = rock.position.x + dx
                currentRock2 = nil
                
                let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.2, y: playerNextPosition.y)
                box.hop(to: nextPosition, inQueue: nextPosition, up: "Left")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.currentRock2 = rock
                }
                
                print("SWITCHING ROCK ZONE")
                currentRockZone = "Left"
                playRockJumpSound()
                return
            }
            if currentRock3 != nil {
                if currentLongRockZone == "Right" {
                    
                    guard let rock = currentRock3 else { return }
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    currentRock3 = nil
                    
                    let nextPosition = CGPoint(x: rockPositionX, y: playerNextPosition.y)
                    box.hop(to: nextPosition, inQueue: nextPosition, up: "Left")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.currentRock3 = rock
                    }
                    
                    print("SWITCHING ROCK ZONE")
                    currentLongRockZone = "Center"
                    playRockJumpSound()
                    return
                }
                else if currentLongRockZone == "Center" {
                    
                    guard let rock = currentRock3 else { return }
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    currentRock3 = nil
                    
                    let nextPosition = CGPoint(x: rockPositionX - rock.size.width * 0.25, y: playerNextPosition.y)
                    box.hop(to: nextPosition, inQueue: nextPosition, up: "Left")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.currentRock3 = rock
                    }
                    
                    print("SWITCHING ROCK ZONE")
                    currentLongRockZone = "Left"
                    playRockJumpSound()
                    return
                }
            }
        case .right:
            
            nextPosition = CGPoint(x: playerNextPosition.x + cellWidth, y: box.position.y)
            // Check the column the player is moving into
            let targetColumn = gridPosition(for: nextPosition).column
            if targetColumn == 4 {
                return // Stop movement
            }
            
            if box.getIsMoving() || box.getMovementQueueLength() > 0 {
                return
            }
            
            if !handleSeaweedContact(nextPosition: CGPoint(x: playerNextPosition.x + cellWidth, y: playerNextPosition.y)) && !box.getIsMoving() && !isPlayerOnRock {
                print("MOVING RIGHT")
                playerNextPosition.x += cellWidth
                playMoveSound()
            } else {
                hitSeaweed = true
            }
            if currentRock2 != nil && currentRockZone == "Left" {
                
                guard let rock = currentRock2 else { return }
                let dx = rock.velocity * CGFloat(0.15)
                let rockPositionX = rock.position.x + dx
                currentRock2 = nil
                
                let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.2, y: playerNextPosition.y)
                box.hop(to: nextPosition, inQueue: nextPosition, up: "Right")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.currentRock2 = rock
                }
                
                print("SWITCHING ROCK ZONE")
                currentRockZone = "Right"
                playRockJumpSound()
                return
            }
            if currentRock3 != nil {
                if currentLongRockZone == "Left" {
                    
                    guard let rock = currentRock3 else { return }
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    currentRock3 = nil
                    
                    let nextPosition = CGPoint(x: rockPositionX, y: playerNextPosition.y)
                    box.hop(to: nextPosition, inQueue: nextPosition, up: "Right")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.currentRock3 = rock
                    }
                    
                    print("SWITCHING ROCK ZONE")
                    currentLongRockZone = "Center"
                    playRockJumpSound()
                    return
                }
                else if currentLongRockZone == "Center" {
                    
                    guard let rock = currentRock3 else { return }
                    let dx = rock.velocity * CGFloat(0.15)
                    let rockPositionX = rock.position.x + dx
                    currentRock3 = nil
                    
                    let nextPosition = CGPoint(x: rockPositionX + rock.size.width * 0.25, y: playerNextPosition.y)
                    box.hop(to: nextPosition, inQueue: nextPosition, up: "Right")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.currentRock3 = rock
                    }
                    
                    print("SWITCHING ROCK ZONE")
                    currentLongRockZone = "Right"
                    playRockJumpSound()
                    return
                }
            }
            
        default:
            return
        }
        if !hitSeaweed {
                box.hop(to: nextPosition, inQueue: nextPosition, up: "Down")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.handleLavaContact()
                }
                handleLavaContact()
            }
        
    }
    
    func spawnEnemy(in lane: Lane) {
        let enemy = OEEnemyNode(gridSize: gridSize)
        addChild(enemy)
        enemy.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed + CGFloat.random(in: -0.5...1))
        enemy.animate()
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
        enemy.animate()
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
            let rock = OERockNode(height: cellHeight)
            addChild(rock)
            rock.name = "rock"
            rock.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
        } else if rockType == 1{
            let rock = OERockNode2(height: cellHeight)
            addChild(rock)
            rock.name = "rock2"
            rock.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
        } else {
            let rock = OERockNode3(height: cellHeight)
            addChild(rock)
            rock.name = "rock3"
            rock.startMoving(from: lane.startPosition, to: lane.endPosition, speed: lane.speed)
        }
    }
    
    func spawnSeaweed(in lane: Lane) {
        // Randomly decide how many seaweed assets to spawn (3 to 5)
        let numberOfSeaweed = Int.random(in: 1...4)
        
        // Exclude the 0 in the middle
        let validColumns = (-4...3).filter { $0 != 0 }
        
        // Randomly select distinct columns for seaweed placement
        var selectedColumns = Set<Int>()
        while selectedColumns.count < numberOfSeaweed {
            if let columnIndex = validColumns.randomElement() {
                selectedColumns.insert(columnIndex)
            }
        }
        
        // Spawn seaweed in the selected columns
        for columnIndex in selectedColumns {
            
            // Randomly choose between OESeaweedNode and OESeaweedNode2
            let seaweed: SKSpriteNode
            
            if Bool.random() {
                seaweed = OESeaweedNode(size: CGSize(width: 48, height: 52))
            } else {
                seaweed = OESeaweedNode2(size: CGSize(width: 45, height: 50))
            }
            
            // Add the seaweed to the scene
            addChild(seaweed)
            
            
            // Calculate the x-position for the selected column
            let columnXPosition = (CGFloat(columnIndex) + 0.5) * cellWidth
            
            // Use the lane's startPosition y-coordinate for the row
            seaweed.position = CGPoint(x: columnXPosition, y: lane.startPosition.y)
            
            //Keep track of seaweed spots for bubble and shell placement
            seaweedPositions.insert(seaweed.position)
            
            //Trigger seaweed animation
            if let animatableSeaweed = seaweed as? AnimatableSeaweed {
                animatableSeaweed.animate()
            }
        }
    }
    
    func spawnCoral(in lane: Lane) {
        let coralR: SKSpriteNode
        let coralL: SKSpriteNode

        coralL = OECoralNode(size: CGSize(width: 60, height: 72))
        coralR = OECoralNode(size: CGSize(width: 60, height: 72))

        addChild(coralR)
        addChild(coralL)

        // Adjust positions slightly
        let leftCoralX = (CGFloat(-5) + 0.5) * cellWidth - 12 // Move left coral more to the left
        let rightCoralX = (CGFloat(4) + 0.5) * cellWidth + 12 // Move right coral more to the right

        coralL.position = CGPoint(x: leftCoralX, y: lane.startPosition.y)
        coralR.position = CGPoint(x: rightCoralX, y: lane.startPosition.y)
    }

    
    
    func warn(in lane: Lane, completion: @escaping () -> Void) {
        
        let warningLabel = SKSpriteNode(imageNamed: "OEEelWarning")
        warningLabel.position = CGPoint(x: 0.0, y: lane.startPosition.y)
        warningLabel.size = CGSize(width: warningLabel.size.width * 0.85, height: warningLabel.size.height * 0.68)
        addChild(warningLabel)
        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        let fadeIn = SKAction.fadeIn(withDuration: 0.25)
        let removeWarning = SKAction.removeFromParent()
        let playSound = SKAction.run {
            if lane.startPosition.y > self.cameraNode.position.y - self.size.height / 2 && lane.startPosition.y < self.cameraNode.position.y + self.size.height * 3 / 4 {
                self.playElectricitySound()
            }
        }
        let sequence = SKAction.sequence([playSound, fadeOut, fadeIn, fadeOut, fadeIn, fadeOut, removeWarning])
        // Run the sequence and trigger the completion block
        warningLabel.run(sequence) {
            completion()
        }
    }
    
    func startSpawning(lanes: [Lane]) {
        
        for i in 0..<lanes.count {
            
            if lanes[i].laneType == "Empty" {
                colorLane(in: lanes[i])
                
                // If Lava then empty then don't spawn any seaweed
                if prevLane?.laneType == "Lava" {
                    spawnCoral(in: lanes[i])
                    // Set prevLane
                    prevLane = lanes[i]
                    continue
                }
                let spawn = SKAction.run { [weak self] in
                    self?.spawnSeaweed(in: lanes[i])
                    self?.spawnCoral(in: lanes[i])
                }
                run(spawn)
            }
            
            if lanes[i].laneType == "Tutorial" {
                let wait = SKAction.wait(forDuration: 5.0)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnEnemy(in: lanes[i])
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lanes[i].laneType == "Eel" {
                colorLane(in: lanes[i])
                let wait = SKAction.wait(forDuration: CGFloat.random(in: 7...10))
                let warn = SKAction.run { [weak self] in
                    self?.warn(in: lanes[i]) {
                        // Trigger spawn after warning is completed
                        self?.spawnEel(in: lanes[i])
                    }
                }
                let sequence = SKAction.sequence([wait, warn])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lanes[i].laneType == "Pufferfish" {
                let wait = SKAction.wait(forDuration: 4.0)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnPufferfish(in: lanes[i])
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lanes[i].laneType == "Spike" {
                
                let wait = SKAction.wait(forDuration: 4.25, withRange: 2)
                let spawn = SKAction.run { [weak self] in
                    let enemyType = Int.random(in: 0..<8)
                    if enemyType == 7 {
                        self?.spawnPufferfish(in: lanes[i])
                    } else {
                        self?.spawnEnemy(in: lanes[i])
                    }
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lanes[i].laneType == "Jellyfish" {
                
                let wait = SKAction.wait(forDuration: 4, withRange: 2)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnJellyfish(in: lanes[i])
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lanes[i].laneType == "Shark" {
                
                let wait = SKAction.wait(forDuration: 4.5, withRange: 2)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnLongEnemy(in: lanes[i])
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
            
            if lanes[i].laneType == "Lava" {
       
                spawnLava(in: lanes[i])
                lavaYPositions.append(lanes[i].startPosition.y)
                var waitTime: CGFloat = 0.0
                if lanes[i].speed > 11 {
                    waitTime = CGFloat.random(in: 4..<4.5)
                } else {
                    waitTime = CGFloat.random(in: 1.5..<2.25)
                }
                let wait = SKAction.wait(forDuration: waitTime)
                let spawn = SKAction.run { [weak self] in
                    self?.spawnRock(in: lanes[i])
                }
                let sequence = SKAction.sequence([spawn, wait])
                let repeatAction = SKAction.repeatForever(sequence)
                
                run(repeatAction)
            }
    
            // Set prevLane
            prevLane = lanes[i]
        }
    }
    
    // Color lanes that are empty or eel type
    // Variable to track texture alternation
    var sandTextureToggle = true // Tracks which texture to use (true -> "SAND", false -> "SAND2")

    func colorLane(in lane: Lane) {
        let laneColor = SKShapeNode(rect: CGRect(
            x: -size.width,
            y: lane.startPosition.y - cellHeight / 2,
            width: size.width * 2,
            height: cellHeight
        ))
        
        if lane.laneType == "Empty" {
            laneColor.fillColor = .white
            // Alternate between SAND and SAND2
            let textureName = sandTextureToggle ? "OESAND" : "OESAND2"
            laneColor.fillTexture = SKTexture(imageNamed: textureName)
            laneColor.fillTexture?.filteringMode = .nearest

            sandTextureToggle.toggle() // Switch to the other texture for next lane
        } else if lane.laneType == "Eel" {
            laneColor.fillColor = .white
            laneColor.fillTexture = SKTexture(imageNamed: "OEeelLane")
            laneColor.fillTexture?.filteringMode = .nearest
        }
        
        laneColor.name = "lane"
        laneColor.strokeColor = .clear // Remove the border
        laneColor.alpha = 0.50
        laneColor.zPosition = 0
        addChild(laneColor)
    }

    
    // Function to spawn the shells randomly in grid spaces
    func spawnShell() {
        let shell = SKSpriteNode(imageNamed: "OEShell") // Use your shell asset
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
        while shellLaneType == "eel" || shellLaneType == "lava" || seaweedPositions.contains(shell.position) || isOverlappingBubble(at: shell.position) {
            randomRow += 1
            randomColumn = playableColumnRange.randomElement()!
            shell.position = positionFor(row: randomRow, column: randomColumn)
            shellLaneType = currentLaneType(position: shell.position)?.lowercased()
        }
        addChild(shell)
    }
    
    func isOverlappingBubble(at position: CGPoint) -> Bool {
        // Create a temporary physics body for the shell's spawn area
        let spawnArea = SKPhysicsBody(rectangleOf: CGSize(width: 40, height: 40)) // Match shell size
        spawnArea.categoryBitMask = PhysicsCategory.shell
        spawnArea.collisionBitMask = PhysicsCategory.none
        spawnArea.contactTestBitMask = PhysicsCategory.bubble // Check for overlap with bubbles
        spawnArea.isDynamic = false

        for node in children {
            if let physicsBody = node.physicsBody,
               physicsBody.categoryBitMask == PhysicsCategory.bubble,
               node.frame.intersects(CGRect(origin: position, size: CGSize(width: 40, height: 40))) {
                return true
            }
        }
        return false
    }

    func isOverlappingShell(at position: CGPoint) -> Bool {
        // Create a temporary physics body for the shell's spawn area
        let spawnArea = SKPhysicsBody(rectangleOf: CGSize(width: 42, height: 42)) // Match shell size
        spawnArea.categoryBitMask = PhysicsCategory.bubble
        spawnArea.collisionBitMask = PhysicsCategory.none
        spawnArea.contactTestBitMask = PhysicsCategory.shell // Check for overlap with bubbles
        spawnArea.isDynamic = false

        for node in children {
            if let physicsBody = node.physicsBody,
               physicsBody.categoryBitMask == PhysicsCategory.shell,
               node.frame.intersects(CGRect(origin: position, size: CGSize(width: 42, height: 42))) {
                return true
            }
        }
        return false
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
   
    func shellAnimation() {
        let newShell = SKSpriteNode(imageNamed: "OEShell") // Use your shell asset
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
            bubble = SKSpriteNode(imageNamed: "OEGoldBubble") // GoldBubble asset
            bubble.size = CGSize(width: 40, height: 40) // Larger for GoldBubble
            bubble.alpha = 0.90
            bubble.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: 1))
            bubble.physicsBody?.categoryBitMask = PhysicsCategory.GoldBubble // Ensure this is correct
        } else {
            bubble = SKSpriteNode(imageNamed: "OEBubble") // Regular bubble asset
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
            while bubbleLaneType == "eel" || bubbleLaneType == "lava" || seaweedPositions.contains(bubble.position) || isOverlappingShell(at: bubble.position) {
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
        arrow = SKSpriteNode(imageNamed: "OEArrow") // Use your arrow asset
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
    var meterShadow: SKSpriteNode?

    func setupAirDisplay() {
        // Remove existing airIcon, airLabel, O2 icon, and shadow if they exist
        airIconBackground?.removeFromParent()
        airIconFill?.removeFromParent()
        airIconTicks?.removeFromParent()
        airLabel?.removeFromParent()
        o2Icon?.removeFromParent()
        meterShadow?.removeFromParent()
        warningIcon?.removeFromParent()

        // Calculate new width for the air meter (20% wider)
        let originalWidth: CGFloat = 30
        let newWidth = originalWidth * 1.25 // Increase width by xx

        // Offset for shifting the meter to the left
        let meterXOffset: CGFloat = -35 // Move xx points to the left

        // Create and configure the air icon
        airIconBackground = SKSpriteNode(imageNamed: "OEAirMeterBackground")
        airIconFill = SKSpriteNode(imageNamed: "OEAirMeterFill")
        airIconTicks = SKSpriteNode(imageNamed: "OEAirMeterTicks")
        airIconTicks.alpha = 0.15
        airIconBackground.size = CGSize(width: newWidth, height: 175)
        airIconFill.size = CGSize(width: newWidth, height: 175)
        airIconTicks.size = CGSize(width: newWidth * 1.833, height: 198) // Adjust tick width proportionally (55 / 30)

        // Adjust positions for moving the meter and shifting to the left
        airIconBackground.position = CGPoint(x: size.width / 2 - 50 + meterXOffset, y: size.height / 2 - 98)
        airIconFill.position = CGPoint(x: size.width / 2 - 50 + meterXOffset, y: size.height / 2 - 185)
        airIconTicks.position = CGPoint(x: size.width / 2 - 50 + meterXOffset, y: size.height / 2 - 98)

        airIconBackground.zPosition = 90
        airIconTicks.zPosition = 95
        airIconFill.zPosition = 100
        airIconFill.anchorPoint = CGPoint(x: 0.5, y: 0.0) // Anchor at the bottom-center for decreasing the air amount

        cameraNode.addChild(airIconFill)
        cameraNode.addChild(airIconBackground)
        cameraNode.addChild(airIconTicks)

        // Create and configure the shadow for the air meter
        let shadowOffset = CGPoint(x: 3, y: -3) // Adjust offset as desired
        meterShadow = SKSpriteNode(imageNamed: "OEmeterShadow") // Replace with your actual shadow asset name
        meterShadow?.size = CGSize(width: newWidth, height: 175) // Adjust width
        meterShadow?.position = CGPoint(x: airIconBackground.position.x + shadowOffset.x, y: airIconBackground.position.y + shadowOffset.y)
        meterShadow?.zPosition = 80 // Place it behind the air meter
        meterShadow?.alpha = 0.45 // Make it semi-transparent for a realistic shadow effect
        if let shadow = meterShadow {
            cameraNode.addChild(shadow)
        }

        // Create and configure the air label
        airLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        airLabel.fontSize = 23 // Increased font size
        airLabel.fontColor = UIColor.black.withAlphaComponent(0.65) // Slightly transparent text
        airLabel.zPosition = 1000

        // Position the air label at the center of the airIconBackground
        airLabel.position = CGPoint(x: airIconBackground.position.x, y: airIconBackground.position.y)
        airLabel.horizontalAlignmentMode = .center // Align horizontally to the center
        airLabel.verticalAlignmentMode = .center   // Align vertically to the center

        airLabel.text = "\(airAmount)"
        cameraNode.addChild(airLabel)
            
        // Create and configure the warning icon
        warningIcon = SKSpriteNode(imageNamed: "OEWarning")
        if let warningIcon = warningIcon {
            let scorePosition = scoreLabel.position
            warningIcon.size = CGSize(width: 170, height: 60) // Adjust size as needed
            warningIcon.position = CGPoint(x: scorePosition.x, y: scorePosition.y - 50) // Adjust y offset as needed
            warningIcon.zPosition = 110
            warningIcon.alpha = 0.90 // transparent value
            warningIcon.isHidden = true // Initially hide the warning icon
            cameraNode.addChild(warningIcon)
        }
            
        // Add the O2 icon to the left of the air meter
        o2Icon = SKSpriteNode(imageNamed: "OEO2") // Replace with your actual asset name
        if let o2Icon = o2Icon {
            let originalO2Size = CGSize(width: 52, height: 50)
            let newO2Size = CGSize(width: originalO2Size.width * 1.0, height: originalO2Size.height * 1.0) // edit size
            o2Icon.size = newO2Size
            o2Icon.alpha = 0.75
            o2Icon.position = CGPoint(x: airIconBackground.position.x + 0, y: airIconBackground.position.y - 80)
            o2Icon.zPosition = 100
            cameraNode.addChild(o2Icon)
        }
    }

    // Animation when collecting gold bubble
    func animateGoldBubble() {
        let goldBubble = SKSpriteNode(imageNamed: "OEGoldBubble")
        goldBubble.size = CGSize(width: 40, height: 40) // Initial size
        goldBubble.alpha = 0 // Start fully transparent
        
        // Adjust position more to the left and slightly upwards
        goldBubble.position = CGPoint(x: airLabel.position.x, y: airLabel.position.y - 78)
        goldBubble.zPosition = airLabel.zPosition + 1
        
        // Define fade-in and enlarge action
        let fadeInAction = SKAction.fadeAlpha(to: 1.0, duration: 0.5) // Fade in over 0.5 seconds
        let enlargeAction = SKAction.scale(to: 1.5, duration: 0.5) // Enlarge over 0.5 seconds
        
        // Pulsating effect (enlarge and shrink repeatedly)
        let scaleUp = SKAction.scale(to: 1.6, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.4, duration: 0.3)
        let pulsate = SKAction.sequence([scaleUp, scaleDown])
        let repeatPulsate = SKAction.repeatForever(pulsate)
        
        // Run pulsating action
        goldBubble.run(repeatPulsate, withKey: "pulsateAction")
        
        // Wait at the top for a set duration before fading out
        let waitAction = SKAction.wait(forDuration: 2.5) // Duration at the top with pulsating effect
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0) // Fade out over 1 second
        
        // Stop pulsating before fading out
        let stopPulsating = SKAction.run {
            goldBubble.removeAction(forKey: "pulsateAction") // Stop pulsating
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
        
        goldBubble.run(sequenceAction)
        cameraNode.addChild(goldBubble)
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
    
    func startWarningFlash() {
        guard let warningIcon = warningIcon else { return }
        
        if warningIcon.action(forKey: "flashWarning") == nil { // Prevent multiple actions
            let flashOn = SKAction.run { [weak self] in
                self?.warningIcon?.isHidden = false
            }
            let flashOff = SKAction.run { [weak self] in
                self?.warningIcon?.isHidden = true
            }
            let wait = SKAction.wait(forDuration: 0.75)
            let flashSequence = SKAction.sequence([flashOn, wait, flashOff, wait])
            let repeatFlash = SKAction.repeatForever(flashSequence)
            
            warningIcon.run(repeatFlash, withKey: "flashWarning")
        }
    }
    
    func stopWarningFlash() {
        warningIcon?.removeAction(forKey: "flashWarning")
        warningIcon?.isHidden = true // Ensure the warning icon is hidden
    }
    
    
    // Function to decrease air by 1 (called in aircountdown) // Air Meter Animation for Low Air
    func decreaseAir() {
        guard !isGameOver else { return }
        // Decrease the air amount immediately
        airAmount -= 1
        airLabel.text = "\(airAmount)"
        
        // Smoothly update the meter fill
        let targetScaleFactor = calculateScaleFactor(airAmount: airAmount)
        smoothUpdateMeterFill(to: targetScaleFactor, duration: 1.0) // Adjust duration for smooth transition

        if airAmount < 11 && !red {
            // Keep the air label text unchanged but make it transparent
            airLabel.fontColor = UIColor(red: 0.19, green: 0.44, blue: 0.50, alpha: 0.5) // Darker blue with transparency

            // Flash the air meter red without changing size
            let redAction = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.5)
            let normalAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.5)
            let flashAction = SKAction.sequence([redAction, normalAction])
            airIconBackground.run(SKAction.repeatForever(flashAction), withKey: "flashRed")
            airIconFill.run(SKAction.repeatForever(flashAction), withKey: "flashRed")
            airIconTicks.run(SKAction.repeatForever(flashAction), withKey: "flashRed")
            red = true

            // Add pulsating effect to the O2 icon
            if let o2Icon = o2Icon {
                let enlargeO2 = SKAction.scale(to: 1.15, duration: 0.5)
                let shrinkO2 = SKAction.scale(to: 1.0, duration: 0.75)
                let pulsateO2 = SKAction.sequence([enlargeO2, shrinkO2])
                o2Icon.run(SKAction.repeatForever(pulsateO2), withKey: "pulsateO2")
            }
        } else if airAmount >= 12 && red {
            // Reset the visuals for air level above 12
            airLabel.fontColor = UIColor(red: 0.19, green: 0.44, blue: 0.50, alpha: 0.5) // Restore transparency

            airIconBackground.removeAction(forKey: "flashRed")
            airIconBackground.colorBlendFactor = 0.0
            airIconFill.removeAction(forKey: "flashRed")
            airIconFill.colorBlendFactor = 0.0
            airIconTicks.removeAction(forKey: "flashRed")
            airIconTicks.colorBlendFactor = 0.0
            red = false

            // Stop pulsating the O2 icon
            o2Icon?.removeAction(forKey: "pulsateO2")
        }
        
        // Trigger haptic feedback when air gets critically low
        if airAmount < 8 {
            if !mediumHapticActive { // Prevents multiple haptic generators
                mediumHapticActive = true
                startMediumHapticFeedback()
            }

            startWarningFlash() // Start flashing the warning icon
            playHeartbeatSound()

        } else {
            mediumHapticActive = false // Stops haptic feedback if airAmount goes above 6
            
            stopWarningFlash() // Stop flashing the warning icon
        }

        // End the game if airAmount reaches 0
        if airAmount <= 0 {
            mediumHapticActive = false // Ensures haptic stops when game ends
            gameOver(reason: "You Ran Out of Air and Drowned")
        }
    }


    func smoothUpdateMeterFill(to targetScale: CGFloat, duration: TimeInterval) {
        let scaleAction = SKAction.scaleY(to: targetScale, duration: duration)
        airIconFill.run(scaleAction)
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
        // Instantly update air meter
        let scaleFactor = calculateScaleFactor(airAmount: airAmount)
        airIconFill.yScale = scaleFactor

        airLabel.text = "\(airAmount)"
    }
    
    func dissolveCharacter(_ characterNode: SKSpriteNode) {
        
        guard let box = box else { return }
        
        box.stopMoving()
        
        // Disable the character's physics to prevent further interactions
        characterNode.physicsBody?.isDynamic = false
        
        // Create a dissolve animation using fade and scale actions
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)  // Gradual fade
        let scaleDown = SKAction.scale(to: 0.0, duration: 0.5)  // Shrink down
        let dissolveAction = SKAction.group([fadeOut, scaleDown])  // Combine actions
        let removeNode = SKAction.removeFromParent()  // Remove from scene after dissolve
        
        // Run the dissolve and removal sequence
        characterNode.run(SKAction.sequence([dissolveAction, removeNode]))
    }
    
    func shockCharacter(_ characterNode: SKSpriteNode) {
        guard let box = box else { return }
        
        box.stopMoving()
        box.removeFromParent()

        let shockedPlayer  = OEShockedNode(size: gridSize)
        shockedPlayer.position = characterNode.position
        addChild(shockedPlayer)
        shockedPlayer.animate()
        
        // Disable the character's physics to prevent further interactions
        characterNode.physicsBody?.isDynamic = false
        
        // Trigger the game over with a specific message
        gameOver(reason: "An eel gave you a shocking surprise!")
    }
        
          
    func dissolveEnemy(_ enemy: SKNode, after delay: TimeInterval = 0.0) {
        let dissolveAction = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        enemy.run(dissolveAction)
    }
    
    // Handles player contact with bubbles, enemies, shells, and rocks
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        // Handle contact with enemies
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.enemy) ||
           (bodyA.categoryBitMask == PhysicsCategory.enemy && bodyB.categoryBitMask == PhysicsCategory.box) {
            
            if !isGameOver {
                
                // Check if the enemy involved is an OEEnemyNode3
                let enemyNode: SKNode
                if bodyA.categoryBitMask == PhysicsCategory.enemy {
                    enemyNode = bodyA.node!
                } else {
                    enemyNode = bodyB.node!
                }
                
                // Additional logic for OEEnemyNode3-specific behavior EEL
                if let enemyNode3 = enemyNode as? OEEnemyNode3 {
                    if let boxNode = box {
                        shockCharacter(boxNode)
                        handleEnemyContact()
                        quickRumbleEffect()
                    }
                }
                else {
                    if let boxNode = box {
                        handleEnemyContact()
                        quickRumbleEffect()
                        dissolveCharacter(boxNode)
                    }
                }
                
                
                // Freeze the enemy
                enemyNode.physicsBody?.isDynamic = false
            }
            
        }
        
        // Handle contact with bubbles
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.bubble) ||
           (bodyA.categoryBitMask == PhysicsCategory.bubble && bodyB.categoryBitMask == PhysicsCategory.box) {
            
            playBubbleSound()
            mediumImpactFeedback.impactOccurred()
            increaseAir(by: 5)
            
            let bubbleNode: SKNode
            if bodyA.categoryBitMask == PhysicsCategory.bubble {
                bubbleNode = bodyA.node!
            } else {
                bubbleNode = bodyB.node!
            }
            bubbleNode.removeFromParent()
            
            if bubbleNode == firstBubble {
                arrow?.removeFromParent()
                bubbleText?.removeFromParent()
                bubbleTextBackground?.removeFromParent()
            }
        }
        
        // Handle contact with GoldBubble
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.GoldBubble) ||
           (bodyA.categoryBitMask == PhysicsCategory.GoldBubble && bodyB.categoryBitMask == PhysicsCategory.box) {
            mediumImpactFeedback.impactOccurred()
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
            
            animateGoldBubble()
        }
        
        // Handle contact with shells
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.shell) ||
           (bodyA.categoryBitMask == PhysicsCategory.shell && bodyB.categoryBitMask == PhysicsCategory.box) {
            didBeginShellContact(contact)
            mediumImpactFeedback.impactOccurred()
        }
        
        
        
        // Handle contact with rocks
        if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.rock) ||
            (bodyA.categoryBitMask == PhysicsCategory.rock && bodyB.categoryBitMask == PhysicsCategory.box) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? OERockNode {
                
                handleLavaContact()
                
                if isPlayerInContactWithRock() {
                    currentRock = rock
                }
                print("PLAYER ON ROCK")
                print(currentRock)
                if isPlayerOnLava() {
                    print("PLAYER ON LAVA")
                    quickRumbleEffect()
                    handleLavaContact()
                }

               
            }
        }
        
        // Handle contact with rock2
        else if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.rock2) ||
            (bodyA.categoryBitMask == PhysicsCategory.rock2 && bodyB.categoryBitMask == PhysicsCategory.box) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock2 ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? OERockNode2 {
                
                handleLavaContact()
                
                if isPlayerInContactWithRock2() {
                    currentRock2 = rock
                }
                
                print("PLAYER ON ROCK")
                print(currentRock2)

                if isPlayerOnLava() {
                    print("PLAYER ON LAVA")
                    handleLavaContact()
                }

                

            }
            
        }
        
        // Handle contact with rock3
        else if (bodyA.categoryBitMask == PhysicsCategory.box && bodyB.categoryBitMask == PhysicsCategory.rock3) ||
            (bodyA.categoryBitMask == PhysicsCategory.rock3 && bodyB.categoryBitMask == PhysicsCategory.box) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock3 ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? OERockNode3 {
                
                handleLavaContact()

                if isPlayerInContactWithRock3() {
                    currentRock3 = rock
                }
                print("PLAYER ON ROCK")
                print(currentRock3)

                if isPlayerOnLava() {
                    print("PLAYER ON LAVA")
                    handleLavaContact()
                }
             

            }
        }
        
        if isPlayerOnLava() {
            if let boxNode = box {
                quickRumbleEffect()
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
            if playerPosition > lavaPosition - 10 && playerPosition < lavaPosition + 10 && !isPlayerOnRock {
                return true
            }
        }
        return false
    }
    
    func isPlayerOnLavaLane(playerPositionY: CGFloat) -> Bool {
        // Check if the player's position overlaps the lava area
        for lavaPosition in lavaYPositions {
            if playerPositionY > lavaPosition - 5 && playerPositionY < lavaPosition + 5 {
                print("player on lava lane")
                return true
            }
        }
        return false
    }
    
    func handleEnemyContact() {
        
        // Trigger game over (after the dissolve)
        if !self.isGameOver {
            // Play the contact sound effect
            self.playEnemyContactSound()
            self.gameOver(reason: "A sea creature stopped your adventure!")
        }
    }

    func handleLavaContact() {
        if isPlayerOnRock {
            // Player is safe on the rock
            return
        }
        
        guard let box = box else { return }

        // check if the player dies due to lava
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !self.isGameOver && !box.getIsMoving() && !self.isPlayerOnRock && self.isPlayerOnLava() && !self.isPlayerInContactWithRock() && !self.isPlayerInContactWithRock2() && !self.isPlayerInContactWithRock3() {
                // Play the "burned" sound only if the player dies
                self.playBurnedSound()
                print(box.getIsMoving())
                print(self.isPlayerOnRock)
                print(self.isPlayerOnLava())
                print(self.isPlayerInContactWithRock())
                print(self.isPlayerInContactWithRock2())
                print(self.isPlayerInContactWithRock3())

                print("PLAYER NOT ON ROCK")
                self.dissolveCharacter(box)
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
    
    func playPufferfishInflateSound() // new puffer sound
    {
        AudioServicesPlaySystemSound(pufferfish)
    
    }
    
    var audioPlayers: [AVAudioPlayer] = [] // Array to hold multiple players

    func playElectricitySound() {
        if let soundURL = Bundle.main.url(forResource: "electricity", withExtension: "mp3") {
            do {
                let newPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayers.append(newPlayer) // Add player to array
                newPlayer.play()
                
                // Set a delegate to remove the player when it finishes
                newPlayer.delegate = self
            } catch {
                print("Error playing electricity sound: \(error.localizedDescription)")
            }
        } else {
            print("Electricity sound file not found.")
        }
    }
    
    func playGameOverSound() {
        if let soundURL = Bundle.main.url(forResource: "gameOver", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.20 // Set the volume to % (range: 0.0 to 1.0)
                audioPlayer?.play()
            } catch {
                print("Error playing gameOver sound: \(error.localizedDescription)")
            }
        } else {
            print("Game over sound file not found.")
        }
    }
    
    func playShellPickupSound() {
        
        AudioServicesPlaySystemSound(shellPickup)
    }
    
    // Call this method to play the sound
    func playHeartbeatSound() {
        AudioServicesPlaySystemSound(heartbeatSound)
    }
    
    func playRockJumpSound() {
        AudioServicesPlaySystemSound(rockSound)
    }
    
    func playMoveSound() {
    
        AudioServicesPlaySystemSound(playerMovementAudio)
    }
    
    func playBubbleSound() {
     
        AudioServicesPlaySystemSound(bubbleSound)
    }

    func playEnemyContactSound() {
        if let soundURL = Bundle.main.url(forResource: "contact", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.75 // Set the volume to 50% (range: 0.0 to 1.0)
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
    
    func playFellSound()
    {
        AudioServicesPlaySystemSound(falling)
    }
    
    func stopAllSounds() {
        
    }
    
    func handleSeaweedContact(nextPosition: CGPoint) -> Bool {
        
        // Check for collision with any seaweed node
        let seaweedNodes = children.filter { $0 is OESeaweedNode }
        let seaweedNodes2 = children.filter { $0 is OESeaweedNode2}
        let coralNodes = children.filter { $0 is OECoralNode}

        
        for node in seaweedNodes {
            if let seaweed = node as? OESeaweedNode {
                // Use the node's frame to check for intersection
                if seaweed.frame.contains(nextPosition) {
                    return true // Collision detected
                }
            }
        }
        
        for node in seaweedNodes2 {
            if let seaweed = node as? OESeaweedNode2 {
                // Use the node's frame to check for intersection
                if seaweed.frame.contains(nextPosition) {
                    return true // Collision detected
                }
            }
        }
        
        for node in coralNodes {
            if let coral = node as? OECoralNode {
                // Use the node's frame to check for intersection
                if coral.frame.contains(nextPosition) {
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
              
           

            }
        }
        
        
        if collision == (PhysicsCategory.box | PhysicsCategory.rock2) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock2 ? contact.bodyA : contact.bodyB
            if currentRock2 == rockBody.node as? OERockNode2 {
          
                print("PLAYER HAS LEFT LONG ROCK")

            }
        }
        
        if collision == (PhysicsCategory.box | PhysicsCategory.rock3) {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock3 ? contact.bodyA : contact.bodyB
            if currentRock3 == rockBody.node as? OERockNode3 {
            
        
                
                print("PLAYER HAS LEFT VERY LONG ROCK")

            }
        }
    }
    
    func isPlayerInContactWithRock() -> Bool {
        guard let box = box else { return false }
        
        if box.getIsMoving() { return false }

        // Check if the player's frame intersects with any rock's frame
        for node in children {
            
            if let rock = node as? OERockNode {
                
                if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && playerNextPosition.x > rock.position.x - rock.size.width * 0.65 && playerNextPosition.x < rock.position.x + rock.size.width * 0.65 {
                    return true
                }
            }
        }
        return false
    }
    
    func isPlayerInContactWithRock2() -> Bool {
        guard let box = box else { return false }
        
        if box.getIsMoving() { return false }

        // Check if the player's frame intersects with any rock's frame
        for node in children {
            
            if let rock = node as? OERockNode2 {
                
                if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && playerNextPosition.x > rock.position.x - rock.size.width * 0.65 && playerNextPosition.x < rock.position.x + rock.size.width * 0.65 {
                    return true
                }
            }
        }
        return false
    }
    
    func isPlayerInContactWithRock3() -> Bool {
        guard let box = box else { return false }
        
        if box.getIsMoving() { return false }
        
        // Check if the player's frame intersects with any rock's frame
        for node in children {
            
            if let rock = node as? OERockNode3 {
                
                if playerNextPosition.y + self.cellHeight > rock.position.y - 5 && playerNextPosition.y + self.cellHeight < rock.position.y + 5 && playerNextPosition.x > rock.position.x - rock.size.width * 0.65 && playerNextPosition.x < rock.position.x + rock.size.width * 0.65 {
                    return true
                }
            }
        }
        return false
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
        let logoTexture = SKTexture(imageNamed: "OELogo1")
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
        startLabel.fontSize = 35
        startLabel.alpha = 0.70
        startLabel.fontColor = .white
        startLabel.zPosition = 1002 // Ensure top visibility
        startLabel.fontName = "Arial-BoldMT" // Use bold font
        startLabel.position = CGPoint(x: 0, y: -10) // Centered on screen
        cameraNode.addChild(startLabel)
        
        // Create a blink action
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
        let blinkForever = SKAction.repeatForever(blinkSequence)
        
        startLabel.run(blinkForever)
        
        // Lock input for xx seconds
        isInputLocked = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.80) {
            self.isInputLocked = false
        }
    }
    
    func gameOver(reason: String) {
        isGameOver = true
        guard !isInputLocked else { return } // Prevent multiple taps triggering game over
        isInputLocked = true // Lock input
        
        
        mediumHapticActive = false // Ensures haptic stops in case you die whilst on low air

        cameraNode.removeAllActions() // Stop camera movement
        removeAction(forKey: "spawnEnemies") // Stop spawning enemies

        // Stop the background music
        stopBackgroundMusic()
        
        // Enable gravity for the player to make them fall
        if let playerBox = box {
            playerBox.physicsBody?.affectedByGravity = true
            playerBox.physicsBody?.velocity = CGVector(dx: 0, dy: 0) // Reset any current velocity
            playerBox.physicsBody?.angularVelocity = 0 // Stop rotation
        }

        // Delay the game over sound effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            self.playGameOverSound()
        }

        // Show the game over overlay after a delay to allow the player to fall
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.showGameOverScreen(reason: reason) // Extracted overlay logic into its own function
            self.isInputLocked = false // Unlock input once game over overlay is shown
        }
    }

    
    func showGameOverScreen(reason: String) {
        // Create a background sprite for the end screen using the ocean image
        let backgroundSprite = SKSpriteNode(imageNamed: "OEgameOver")
        backgroundSprite.position = CGPoint(x: 0, y: 0) // Centered on screen
        backgroundSprite.zPosition = 1100 // Ensure it is behind the text but above other nodes
        backgroundSprite.size = self.size // Adjust to fill the screen
        self.cameraNode.addChild(backgroundSprite)

        // Add the game logo
        let logoTexture = SKTexture(imageNamed: "OELogo1")
        let logoSprite = SKSpriteNode(texture: logoTexture)
        logoSprite.position = CGPoint(x: 0, y: 270) // Positioned above the reason text
        logoSprite.zPosition = 1101
        logoSprite.xScale = 0.35
        logoSprite.yScale = 0.35
        self.cameraNode.addChild(logoSprite)

        // Save the current score
        let finalScore = self.scoreDisplayed

        // Display Final Score
        let finalScoreLabel = SKLabelNode(text: "Score: \(finalScore)")
        finalScoreLabel.fontSize = 38
        finalScoreLabel.fontColor = .white
        finalScoreLabel.zPosition = 1101
        finalScoreLabel.fontName = "Helvetica Neue Bold"
        finalScoreLabel.position = CGPoint(x: 0, y: 40)
        self.cameraNode.addChild(finalScoreLabel)
        
        // Display the reason for game over
        let reasonLabel = SKLabelNode(text: reason)
        reasonLabel.fontSize = 19
        reasonLabel.fontColor = .white
        reasonLabel.zPosition = 1101
        reasonLabel.fontName = "Helvetica Neue Bold"
        reasonLabel.position = CGPoint(x: 0, y: 90)
        self.cameraNode.addChild(reasonLabel)
        
        // Display asset based on reason
        let reasonAsset: SKSpriteNode
        switch reason {
        case "You burned to death underwater!":
            reasonAsset = SKSpriteNode(imageNamed: "OEendGameBurned")
        case "A sea creature stopped your adventure!":
            reasonAsset = SKSpriteNode(imageNamed: "OEendGameContact")
        case "You Ran Out of Air and Drowned":
            reasonAsset = SKSpriteNode(imageNamed: "OEendGameDrowned")
        case "You were swept away by the rocks!":
            reasonAsset = SKSpriteNode(imageNamed: "OEendGameFell")
        case "You sank into the depths and disappeared!":
            reasonAsset = SKSpriteNode(imageNamed: "OEendGameFell")
        case "An eel gave you a shocking surprise!":
            reasonAsset = SKSpriteNode(imageNamed: "OEgameoverEel")
        default:
            reasonAsset = SKSpriteNode()
        }
        
        reasonAsset.position = CGPoint(x: 0, y: -50)
        reasonAsset.zPosition = 1101
        self.cameraNode.addChild(reasonAsset)

        // Display "Tap to Restart" message
        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 25
        restartLabel.fontColor = .white
        restartLabel.alpha = 0.80
        restartLabel.zPosition = 1101
        restartLabel.fontName = "Arial-BoldMT"
        restartLabel.position = CGPoint(x: 0, y: -300)
        self.cameraNode.addChild(restartLabel)

        // Create a blink action
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
        let blinkForever = SKAction.repeatForever(blinkSequence)

        restartLabel.run(blinkForever)

        // Pause the scene
        self.isPaused = true

        
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isInputLocked else { return } // Ignore input if locked
        
        
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
        
        score = 0 // Ensure score is greater than 0 to start
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

extension OEGameScene: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Remove the player from the array when it finishes
        if let index = audioPlayers.firstIndex(of: player) {
            audioPlayers.remove(at: index)
        }
    }
}
