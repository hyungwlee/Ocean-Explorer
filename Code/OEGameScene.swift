//
//  OEGameScene.swift
//  Ocean Explorer (iOS)
//
//  Created by Alexander Chakmakian on 10/30/24.
//

import SpriteKit

class OEGameScene: SKScene {
    weak var context: OEGameContext?
    var box: OEBoxNode?
    var cameraNode: SKCameraNode!
    
    // Array to track background tiles
    var backgroundTiles: [SKSpriteNode] = []

    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        
        // Center the scene’s anchor point
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
        
        // Center the camera initially on the scene
        cameraNode.position = CGPoint(x: 0, y: 0)
        
        context.stateMachine?.enter(OEGameIdleState.self)
    }
    
    func setupBackground() {
        // Create the initial background tile
        addBackgroundTile(at: CGPoint(x: 0, y: 0))
        
        // Add the camera to the scene
        addChild(cameraNode)
    }

    // Helper function to add a new background tile
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
        let center = CGPoint(x: 0, y: 0) // Centered in the scene
        box = OEBoxNode()
        box?.position = center
        if let box = box {
            addChild(box)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        followCharacter()
        updateBackgroundTiles()
        //generateObstacles()
    }
    
    func followCharacter() {
        if let box = box {
            cameraNode.position.y = box.position.y
        }
    }

    // Function to update background tiles as the player progresses
    func updateBackgroundTiles() {
        guard let box else { return }
        
        // Define when to add new tiles (adjust as needed)
        let thresholdY = cameraNode.position.y + size.height / 2
        
        // Add a new tile if the last one is too far behind
        if let lastTile = backgroundTiles.last, lastTile.position.y < thresholdY {
            addBackgroundTile(at: CGPoint(x: 0, y: lastTile.position.y + size.height))
        }

        // Remove background tiles that are off-screen
        backgroundTiles = backgroundTiles.filter { tile in
            if tile.position.y < cameraNode.position.y - size.height {
                tile.removeFromParent()
                return false
            }
            return true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        box?.jump()
    }
}
