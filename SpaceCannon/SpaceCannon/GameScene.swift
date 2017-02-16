//
//  GameScene.swift
//  SpaceCannon
//
//  Created by Yonglin Ma on 2/15/17.
//  Copyright © 2017 Sixlivesleft. All rights reserved.
//

import SpriteKit
import GameplayKit

let SHOOT_SPEED : CGFloat = 1000.0

class GameScene: SKScene {
    
//    private var label : SKLabelNode?
//    private var spinnyNode : SKSpriteNode?

    private var mainLayer : SKNode?
    private var cannon : SKSpriteNode?
    private var didShoot = false
    
    
    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)

        
        mainLayer = SKNode()
        
        // Add edges
        let leftEdge = SKNode()
        leftEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        leftEdge.position = CGPoint(x: 20, y: 0)
        self.addChild(leftEdge)

        let rightEdge = SKNode()
        rightEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        rightEdge.position = CGPoint(x: self.size.width - 20, y: 0.0)
        self.addChild(rightEdge)
        
        self.cannon = self.childNode(withName: "cannon") as? SKSpriteNode
        if let cannon = self.cannon {
            cannon.run(SKAction.repeatForever(
                SKAction.sequence([SKAction.rotate(byAngle: CGFloat(Float.pi), duration: 2),
                                SKAction.rotate(byAngle: -(CGFloat)(Float.pi), duration: 2)])
            ))
        }
        
        self.addChild(mainLayer!)
        
    }
    
    func radiansToVector(radians : CGFloat) -> CGVector {
        var vector = CGVector()
        vector.dx = CGFloat(cosf(Float(radians)))
        vector.dy = CGFloat(sinf(Float(radians)))
        return vector
    }
    
    func shoot() {
        guard let cannon = self.cannon else { return }
        
        let ball = SKSpriteNode(imageNamed: "Ball")
        ball.name = "ball"
        ball.xScale = 2.0
        ball.yScale = 2.0
        let rotationVector = radiansToVector(radians: (cannon.zRotation))
        ball.position = CGPoint(x: (cannon.position.x + cannon.size.width * 0.5 * rotationVector.dx),
                                y: (cannon.position.y + cannon.size.height * 0.5 * rotationVector.dy))
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 6.0)
        ball.physicsBody?.velocity = CGVector(dx: rotationVector.dx * SHOOT_SPEED, dy: rotationVector.dy * SHOOT_SPEED)
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.linearDamping = 0.0
        ball.physicsBody?.friction = 0.0
        
        mainLayer?.addChild(ball)
        
    }
    
    //MARK: Frame life cycle
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered

    }
    override func didEvaluateActions() {
        // code
    }
    override func didSimulatePhysics() {
        if didShoot {
            shoot()
            didShoot = false
        }
        // Clean up balls
        mainLayer?.enumerateChildNodes(withName: "ball", using: { (node, stop) in
            if  !self.frame.contains(node.position) {
                node.removeFromParent()
            }
        })
    }
    
    override func didApplyConstraints() {
        //<#code#>
    }
    override func didFinishUpdate() {
        //<#code#>
    }
    
    
    //MARK: - Touch handling
    
    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
        didShoot = true
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
}
