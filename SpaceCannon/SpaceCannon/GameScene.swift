//
//  GameScene.swift
//  SpaceCannon
//
//  Created by Yonglin Ma on 2/15/17.
//  Copyright © 2017 Sixlivesleft. All rights reserved.
//

import SpriteKit
import GameplayKit




func radiansToVector(radians : CGFloat) -> CGVector {
    var vector = CGVector()
    vector.dx = cos(radians)
    vector.dy = sin(radians)
    return vector
}

func randomInRange(low : CGFloat, high : CGFloat) -> CGFloat{
    var value = CGFloat(arc4random_uniform(UINT32_MAX) / UINT32_MAX)
    value = value * (high - low) + low
    return value
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let SHOOT_SPEED : CGFloat = 500.0
    let HaloLowAngle : CGFloat = 200.0 * CGFloat.pi / 180.0
    let HaloHighAngle : CGFloat = 340.0 * CGFloat.pi / 180.0
    let HaloSpeed : CGFloat = 100.0
    let haloCategory : UInt32 = 0x1 << 0
    let ballCategory : UInt32 = 0x1 << 1
    let edgeCategory : UInt32 = 0x1 << 2
    

    private var mainLayer : SKNode?
    private var menuLayer : SKNode?
    private var cannon : SKSpriteNode?
    private var didShoot = false
    
    
    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        self.physicsWorld.contactDelegate = self

        self.cannon = self.childNode(withName: "cannon") as? SKSpriteNode
        self.mainLayer = self.childNode(withName: "mainLayer")
        self.menuLayer = self.childNode(withName: "menuLayer")
        
        // Add edges
        let leftEdge = SKNode()
        leftEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        leftEdge.physicsBody?.categoryBitMask = edgeCategory
        leftEdge.position = CGPoint(x: 10, y: 0)
        self.addChild(leftEdge)

        let rightEdge = SKNode()
        rightEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        rightEdge.physicsBody?.categoryBitMask = edgeCategory
        rightEdge.position = CGPoint(x: self.size.width - 10, y: 0.0)
        self.addChild(rightEdge)
        
        /*if let cannon = self.cannon {
            cannon.run(SKAction.repeatForever(
                SKAction.sequence([SKAction.rotate(byAngle: CGFloat.pi, duration: 2),
                                SKAction.rotate(byAngle: -CGFloat.pi, duration: 2)])
            ))
        }*/
        
        
        self.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 2, withRange: 1),
                                                           SKAction.perform(#selector(spawnHalo), onTarget: self)])))
        
    }
    
    func spawnHalo() {
        let halo = SKSpriteNode(imageNamed: "Halo")
        halo.position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(self.size.width))), y: self.size.height)
        halo.xScale = 2.0
        halo.yScale = 2.0
        
        halo.physicsBody = SKPhysicsBody(circleOfRadius: 32.0)
        
        guard (halo.physicsBody != nil) else {return}
        
        let direction = radiansToVector(radians: randomInRange(low: HaloLowAngle, high: HaloHighAngle))
        halo.physicsBody?.velocity.dx = direction.dx * HaloSpeed
        halo.physicsBody?.velocity.dy = direction.dy * HaloSpeed
        halo.physicsBody?.restitution = 1.0
        halo.physicsBody?.linearDamping = 0.0
        halo.physicsBody?.friction = 0.0
        halo.physicsBody?.categoryBitMask = haloCategory
        halo.physicsBody?.collisionBitMask = edgeCategory
        halo.physicsBody?.contactTestBitMask = ballCategory

        
        
        mainLayer?.addChild(halo)
        
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
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 12.0)
        ball.physicsBody?.velocity = CGVector(dx: rotationVector.dx * SHOOT_SPEED, dy: rotationVector.dy * SHOOT_SPEED)
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.linearDamping = 0.0
        ball.physicsBody?.friction = 0.0
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.collisionBitMask = edgeCategory
        
        
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
    
    //MARK: collision handling
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody : SKPhysicsBody?
        var secondBody : SKPhysicsBody?
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody?.categoryBitMask == haloCategory && secondBody?.categoryBitMask == ballCategory) {
            self.addExplosion(position: (firstBody?.node?.position)!)
            firstBody?.node?.removeFromParent()
            secondBody?.node?.removeFromParent()
        }
        
    }
    
    func addExplosion(position : CGPoint) {
        guard let explosion = SKEmitterNode(fileNamed: "HaloExplosion.sks") else {return}
        explosion.position = position
        mainLayer?.addChild(explosion)
        
        explosion.run(SKAction.sequence([SKAction.wait(forDuration: 1.5),
                               SKAction.removeFromParent()]))
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
