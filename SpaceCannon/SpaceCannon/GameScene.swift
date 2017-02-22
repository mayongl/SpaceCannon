//
//  GameScene.swift
//  SpaceCannon
//
//  Created by Yonglin Ma on 2/15/17.
//  Copyright © 2017 Sixlivesleft. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation


func radiansToVector(radians : CGFloat) -> CGVector {
    var vector = CGVector()
    vector.dx = cos(radians)
    vector.dy = sin(radians)
    return vector
}

func randomInRange(low : CGFloat, high : CGFloat) -> CGFloat{
    var value = CGFloat(arc4random_uniform(10000)) / CGFloat(10000)
    value = value * (high - low) + low
    return value
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let SHOOT_SPEED : CGFloat = 2000.0
    let HaloLowAngle : CGFloat = 200.0 * CGFloat.pi / 180.0
    let HaloHighAngle : CGFloat = 340.0 * CGFloat.pi / 180.0
    let HaloSpeed : CGFloat = 200.0
    let haloCategory : UInt32 = 0x1 << 0
    let ballCategory : UInt32 = 0x1 << 1
    let edgeCategory : UInt32 = 0x1 << 2
    let shieldCategory : UInt32 = 0x1 << 3
    let lifeBarCategory : UInt32 = 0x1 << 4
    let keyTopScore = "TopScore"
    
    
    var ammo : Int = 5 {

        
       didSet {
            if (ammo >= 0 && ammo <= 5) {

                ammoDisplay?.texture = SKTexture(imageNamed: String.init(format: "Ammo%d", ammo))
            } else {
                ammo = 5
            }
        }
    }
    
    var score : Int = 0 {
        didSet {
            scoreLabel?.text = String.init(format: "Score: %d", score)
        }
    }
    
    var gamePaused : Bool = false {
        willSet {
            if !gameOver {  //It would be late if this is put into didSet
                pauseButton?.isHidden = newValue
                resumeButton?.isHidden = !newValue
            }
        }
        didSet {
            if !gameOver {
                if gamePaused {
//                    self.run(SKAction.sequence([//SKAction.wait(forDuration: 0.1),
//                                                SKAction.run {self.view?.isPaused = true}
//                        ]))
                    self.run(SKAction.run {self.view?.isPaused = true}) //The s can't be called directly, otherwise there would be no time to show the resume button

                } else {
                    self.view?.isPaused = false
                }
            }
        }
    }
    
    var topScore = 0
    var gameOver = true
    var appDefaults : UserDefaults?
    
    private var mainLayer : SKNode?
    private var menuLayer : SKNode?
    private var cannon : SKSpriteNode?
    private var ammoDisplay : SKSpriteNode?
    private var scoreLabel : SKLabelNode?
    private var pauseButton : SKSpriteNode?
    private var resumeButton : SKSpriteNode?
    //private var explosion : SKEmitterNode?
    private var didShoot = false
    
    /*override init() {
        
        appDefaults = UserDefaults.standard
        super.init()
        
        topScore = (userDefaults?.integer(forKey: keyTopScore))!
        

    }*/
    
    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        self.physicsWorld.contactDelegate = self

        //self.explosion = SKEmitterNode(fileNamed: "HaloExplosion.sks")

        self.cannon = self.childNode(withName: "cannon") as? SKSpriteNode
        self.ammoDisplay = self.childNode(withName: "ammoDisplay") as? SKSpriteNode
        self.scoreLabel = self.childNode(withName: "scoreLabel") as? SKLabelNode
        self.mainLayer = self.childNode(withName: "mainLayer")
        self.menuLayer = self.childNode(withName: "menuLayer")
        self.pauseButton = self.childNode(withName: "pause") as? SKSpriteNode
        self.pauseButton?.isHidden = true
        self.resumeButton = self.childNode(withName: "resume") as? SKSpriteNode
        self.resumeButton?.isHidden = true
        topScore = UserDefaults.standard.integer(forKey: keyTopScore)

        
        // Add edges
        let leftEdge = SKNode()
        leftEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        leftEdge.physicsBody?.categoryBitMask = edgeCategory
        leftEdge.position = CGPoint(x: 0, y: 0)
        self.addChild(leftEdge)

        let rightEdge = SKNode()
        rightEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        rightEdge.physicsBody?.categoryBitMask = edgeCategory
        rightEdge.position = CGPoint(x: self.size.width, y: 0.0)
        self.addChild(rightEdge)
        
        /*if let cannon = self.cannon {
            cannon.run(SKAction.repeatForever(
                SKAction.sequence([SKAction.rotate(byAngle: CGFloat.pi, duration: 2),
                                SKAction.rotate(byAngle: -CGFloat.pi, duration: 2)])
            ))
        }*/
        
        showMenu()
        
        // Spawn halos
        self.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 2, withRange: 1),
                                                           SKAction.perform(#selector(spawnHalo), onTarget: self)])))

        // Restore ammo
        self.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1),
                                                           SKAction.run {self.ammo += 1}
                                                            ])))
    }
    
    func newGame() {
        mainLayer?.removeAllChildren()
        menuLayer?.run(SKAction.scale(to: 0.0, duration: 0.5))
        
        //menuLayer?.isHidden = true
        
        gameOver = false
        
        ammo = 5
        score = 0
        pauseButton?.isHidden = false
        
        // Add shields
        for i in 0...6 {
            let shield = SKSpriteNode(imageNamed: "Block")
            shield.name = "shield"
            shield.position = CGPoint(x: 75 + 100*i, y: 150)
            shield.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 42, height: 9))
            shield.physicsBody?.categoryBitMask = shieldCategory
            shield.physicsBody?.collisionBitMask = 0
            shield.xScale = 2.0
            shield.yScale = 2.0
            mainLayer?.addChild(shield)
        }
        
        // Add life bar
        let lifeBar = SKSpriteNode(imageNamed: "BlueBar")
        lifeBar.position = CGPoint(x: self.size.width/2, y: 120)
        lifeBar.size = CGSize(width: self.size.width, height: lifeBar.size.height)
        lifeBar.xScale = 2.0
        lifeBar.yScale = 2.0
        lifeBar.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: -lifeBar.size.width/2, y: 0), to: CGPoint(x: lifeBar.size.width/2, y: 0))
        lifeBar.physicsBody?.categoryBitMask = lifeBarCategory
        lifeBar.physicsBody?.collisionBitMask = 0
        mainLayer?.addChild(lifeBar)
    }
    
    func spawnHalo() {
        let halo = SKSpriteNode(imageNamed: "Halo")
        halo.name = "halo"
        halo.position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(self.size.width-halo.size.width)))+halo.size.width, y: self.size.height)
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
        halo.physicsBody?.contactTestBitMask = ballCategory | shieldCategory | lifeBarCategory
        
        mainLayer?.addChild(halo)
        
    }
    
    
    func shoot() {
        guard self.ammo > 0 else {return}
        guard let cannon = self.cannon else { return }
        self.ammo -= 1

        
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
        ball.physicsBody?.contactTestBitMask = edgeCategory
        
        let trail = SKEmitterNode(fileNamed: "BallTrail")
        trail?.targetNode = mainLayer
        trail?.xScale = 2.0
        trail?.yScale = 2.0
        ball.addChild(trail!)
        mainLayer?.addChild(ball)
        self.run(SKAction.playSoundFileNamed("Laser.caf", waitForCompletion: false))

        
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
            for i in 0..<1 {
                self.run(SKAction.sequence([SKAction.wait(forDuration: 0.1 * Double(i)),
                                 SKAction.perform(#selector(shoot), onTarget: self)]))
            }
            didShoot = false

        }
        // Clean up balls
        mainLayer?.enumerateChildNodes(withName: "ball", using: { (node, stop) in
            if  !self.frame.contains(node.position) {
                node.removeFromParent()
            }
        })
 
        // Clean up halos
        mainLayer?.enumerateChildNodes(withName: "halo", using: { (node, stop) in
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
            self.addExplosion(position: (firstBody?.node?.position)!, name : "HaloExplosion")
            self.run(SKAction.playSoundFileNamed("Explosion.caf", waitForCompletion: false))
            self.score += 1

            //firstBody?.node?.isHidden = !(firstBody?.node?.isHidden)!
            firstBody?.categoryBitMask = 0
            firstBody?.node?.removeFromParent()
            secondBody?.node?.removeFromParent()
        }
        
        if (firstBody?.categoryBitMask == haloCategory && secondBody?.categoryBitMask == shieldCategory) {
            self.addExplosion(position: (firstBody?.node?.position)!, name : "HaloExplosion")
            self.run(SKAction.playSoundFileNamed("Explosion.caf", waitForCompletion: false))
            
            firstBody?.node?.isHidden = true
            firstBody?.categoryBitMask = 0
            //firstBody?.node?.removeFromParent()
            secondBody?.node?.removeFromParent()
        }
        
        if (firstBody?.categoryBitMask == haloCategory && secondBody?.categoryBitMask == lifeBarCategory) {
            //self.addExplosion(position: (firstBody?.node?.position)!, name : "HaloExplosion")
            self.addExplosion(position: (secondBody?.node?.position)!, name : "LifeBarExplosion")
            self.run(SKAction.playSoundFileNamed("DeepExplosion.caf", waitForCompletion: false))
            
            //firstBody?.node?.removeFromParent()
            secondBody?.node?.removeFromParent()
            endGame()
        }
        
        if (firstBody?.categoryBitMask == ballCategory && secondBody?.categoryBitMask == edgeCategory) {
            self.run(SKAction.playSoundFileNamed("Bounce.caf", waitForCompletion: false))
        }
    }
    
    func endGame() {

        mainLayer?.enumerateChildNodes(withName: "halo", using: { (node, stop) in
                self.addExplosion(position: node.position, name : "HaloExplosion")
                node.removeFromParent()
        })
        mainLayer?.enumerateChildNodes(withName: "ball", using: { (node, stop) in
            node.removeFromParent()
        })
        mainLayer?.enumerateChildNodes(withName: "shield", using: { (node, stop) in
            node.removeFromParent()
        })
        
        if (score > topScore) {
            topScore = score
            UserDefaults.standard.set(topScore, forKey: keyTopScore)
        }
        
        gameOver = true
        pauseButton?.isHidden = true
        
        
        showMenu()
        //self.run(SKAction.sequence([SKAction.wait(forDuration: 1.5),
          //                                                 SKAction.perform(#selector(newGame), onTarget: self)]))
    }
    
    func showMenu() {
        let scoreNode = menuLayer?.childNode(withName: "score") as? SKLabelNode
        scoreNode?.text = String.init(format : "%d", self.score)
        let topScoreNode = menuLayer?.childNode(withName: "topScore") as? SKLabelNode
        topScoreNode?.text = String.init(format : "%d", self.topScore)

        //menuLayer?.isHidden = false
        menuLayer?.run(SKAction.scale(to: 1.0, duration: 0.5))
    }
    
    func addExplosion(position : CGPoint, name : String) {
        guard let explosion = SKEmitterNode(fileNamed: name) else {return}
        explosion.position = position
        explosion.xScale = 2.0
        explosion.yScale = 2.0
        mainLayer?.addChild(explosion)
        
        explosion.run(SKAction.sequence([SKAction.wait(forDuration: 1.5),
                               SKAction.removeFromParent()]))
    }
    
    //MARK: - Touch handling
    
//    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
//    }
//    
//    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
//    }
//    
//    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
        if !gameOver && !(self.view?.isPaused)! {
            for t in touches {
                let nodes = self.nodes(at: t.location(in: self))
            
                if nodes.count == 0 || nodes[0].name != "pause" {
                    didShoot = true
                }
            }
        }
    }
    
    /*override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }*/
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        for t in touches {
            if gameOver {
                let nodes = menuLayer?.nodes(at: t.location(in: self).applying(CGAffineTransform(translationX: -((menuLayer?.position.x)!), y: -((menuLayer?.position.y)!))))
                
                if (nodes?.count)! > 0 && nodes?[0].name == "play" {
                    self.newGame()
                }
            } else {
                let nodes = self.nodes(at: t.location(in: self))
            
                if (nodes.count > 0){
                    if nodes[0].name == "pause" {
                        gamePaused = true
                    } else if nodes[0].name == "resume" {
                        gamePaused = false
                        
                    }
                }
            }
        }
    }
}
