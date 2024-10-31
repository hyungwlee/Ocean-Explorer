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

    init(context: OEGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        self.cameraNode = SKCameraNode() // Initialize the camera node
        self.camera = cameraNode // Set the scene's camera to this camera node
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard let context else { return }
        
        setupBackground()
        prepareGameContext()
        prepareStartNodes()
        
        context.stateMachine?.enter(OEGameIdleState.self)
    }
    
    func setupBackground() {
        // Set up the background image, scaled to the scene size
        let backgroundNode = SKSpriteNode(imageNamed: "Background")
        backgroundNode.size = size
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -1
        addChild(backgroundNode)
        
        // Add the camera to the scene
        addChild(cameraNode)
    }
    
    func prepareGameContext() {
        guard let context else { return }
        context.scene = self
        context.updateLayoutInfo(withScreenSize: size)
        context.configureStates()
    }
    
    func prepareStartNodes() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        box = OEBoxNode()
        box?.position = center
        if let box = box {
            addChild(box)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Update camera position to follow the character as it moves up
        followCharacter()
    }
    
    func followCharacter() {
        // Ensure the camera follows the character's position, clamping if necessary
        if let box = box {
            // Adjust the camera's y position based on the character's y position
            cameraNode.position.y = box.position.y
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        box?.jump() // Make the character jump up on tap
    }
}
