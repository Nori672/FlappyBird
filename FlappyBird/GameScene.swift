//
//  GameScene.swift
//  FlappyBird
//
//  Created by Norihiro.Nakano on 2020/12/30.
//  Copyright © 2020 Norihiro.Nakano. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene,SKPhysicsContactDelegate {
    var scrollNode:SKNode!
    var wallNode: SKNode!
    var bird:SKSpriteNode!
    var coinNode:SKNode! //課題として追加
    
    
    //衝突判定カテゴリー。32桁の中のどこに1があるかをみて衝突相手を判定する
    let birdCategory: UInt32 = 1 << 0 //0....00001
    let groundCategory: UInt32 = 1 << 1 //0....00010
    let wallCategory: UInt32 = 1 << 2 //0....00100
    let scoreCategory:UInt32 = 1 << 3 //0....01000  ※壁を潜ったことを判定するため、上側と下側の壁の間に見えない物体を配置して、これに衝突した時にくぐったと判断してスコアをカウントアップする
    let itemScoreCategory:UInt32 = 1 << 4 //課題として追加
    //UInt32: 32ビットの数字を表す。他にも16,32,64もある
    //演算子「<<」でビットをずらすことができる
    
    
    //スコア用
    var score = 0
    let userDefaults:UserDefaults = UserDefaults.standard //ベストスコアを1つ保存するためのプロパティを作成
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    
//課題として追加
    var itemScore = 0
    var itemScoreLabelNode:SKLabelNode!
    var itemBestScoreLabelNode:SKLabelNode!
    var sound:SKAction!
    
    //didMoveメソッド：SKView上にSceneが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        //重力を設定（物理演算はSpriteKitがする）
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self //衝突判定の機能をつけるために設定。
        //重力の設定はSKPhysicsWorldクラスのgravityプロパティで設定。
        //SceneクラスのphysicsWorldプロパティがプロトコルとしてSKPhysicsWorldクラスを持っている。
        
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.9, alpha: 1)
        
        //スクロールするスプライトの親ノード
        //SKNode：シーン上の画面を構成する要素（ノードという）。このSKNodeクラスを継承したクラスが実際のUI部品になる（例　SKSpriteNode,SKLabelNode,SKShapeNodeなど）
        //ここではゲームオーバーになったらスクロールを一括で止めることができるように親ノードを作成
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
//課題として追加
        coinNode = SKNode()
        scrollNode.addChild(coinNode)
        
//        sound = SKAudioNode()
//        addChild(sound)
//ここまで
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
//課題として追加
        setupItem()
    }
    
    func setupGround(){
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground") //SKTexture:SpriteKitで表示する画像を扱う
        groundTexture.filteringMode = .nearest
        //filteringMode:画像が元々サイズとは違うサイズで使われる時に、画質の処理をするプロパティ。
        //.nearest:画質は荒くなるが、処理を早くする。　.liner:画質は綺麗になるが、処理が遅くなる
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成。左方向に画像一枚分をスクロールさせる
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール->元の位置->左にスクロールを無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber{
            //テクスチャを指定してスプライトを作成。（スプライト：コンピュータの処理の負荷を上げずに、高速で画像を描写する仕組み。画像を表示するためのものという認識でOK）
            //SpriteKitではSKSpriteNodeを使って表示する
            let groundSprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            groundSprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().width / 2
            )
            
            //スプライトにアクションを設定
            groundSprite.run(repeatScrollGround)
            
            //スプライトに物理演算を設定
            groundSprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突のカテゴリー設定
            groundSprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突の時に動かないように設定
            groundSprite.physicsBody?.isDynamic = false
            
            //Sceneにスプライトを追加。addChildメソッドでスプライトを画面に表示
            scrollNode.addChild(groundSprite)
        }

    }
    
    func setupCloud(){
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成。左方向に画像一枚分をスクロールさせる
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール->元の位置->左にスクロールを無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //groundのスプライトを配置する
        for i in 0..<needCloudNumber{
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            
            //スプライトの表示する位置を指定する
            cloudSprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            //スプライトにアクションを設定
            cloudSprite.run(repeatScrollCloud)
            
            //Sceneにスプライトを追加。addChildメソッドでスプライトを画面に表示
            scrollNode.addChild(cloudSprite)
        }
    }
    
    func setupWall(){
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let moveDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -moveDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順番に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3
        
        //隙間位置の上下の振れ幅を鳥のサイズの3倍をする
        let random_y_range = birdSize.height * 3
        
        //下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "groud").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 //雲より手前、紙面より奥に
            
            //0~random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //スプライトに物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の時に動かないように設定
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の時に動かないように設定
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory //categorybitMask:自分が属するカテゴリ値を設定
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory //contactTestBitMask:衝突を検知したい相手カテゴリーを設定
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁作成->時間待ち->壁作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird(){
        //鳥の画像を2種類読み込む(鳥が羽ばたいて見えるようにするため、2種類の画像を交互に表示させる)
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を受けるようにする
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        //SKNodeクラスのphysicsBodyに値を設定することで、物理演算を受ける
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリーを設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | itemScoreCategory //itemScoreCategoryは課題用で追加
        //collisionBitMask:自分に当たってくる（触れる）bitを選択
        //contactTestBitMask:衝突を検知できるbitを選択（重なるでもOK ->当たる、当たらないは関係ない？）
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加
        addChild(bird)
    }
    
    //画面をタップした時に呼ばれるメソッド
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{ //ゲーム中の時(スクロールが止まっていないとき)だけ鳥が羽ばたく
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            //鳥に縦方向の力を加える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0{ //ゲームオーバー（スクロールが止まった時）はrestart()メソッドを呼び出してゲームを再開
            restart()
        }
        
    }
    
    //SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーの時には何もしない。（壁に当たった後、地面にも必ず衝突するので、そこで2度目の処理を行わないようにするため）
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score\(score)"
            
            //ベストスコアを更新したかを確認する
            //UserDefaultはキーと値を指定して保存する。今回はBESTというキーでスコアの保存・取り出しをする
            var bestScore = userDefaults.integer(forKey:"BEST") //キーを指定して値を確認
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
//課題用に追加（ここから）
        }else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory{
            //アイテム(coin)と衝突した時
//            let soundAction = SKAudioNode.init(fileNamed: "coin.mp3")
            
            //効果音を鳴らす
            sound = SKAction.playSoundFileNamed("coin.mp3", waitForCompletion: true)
            self.run(sound)
            
            print("ジャリンジャリン稼ぐぜ！")
            itemScore += 1
            itemScoreLabelNode.text = "Coin:¥\(itemScore)"
            var itemBody:SKPhysicsBody
            if contact.bodyA.categoryBitMask <  contact.bodyB.categoryBitMask{
                itemBody = contact.bodyB
            }else{
                itemBody = contact.bodyA
            }
            itemBody.node?.removeFromParent()
//            self.addChild(soundAction)
            
            //アイテム獲得のベストスコア
            var itemBestScore = userDefaults.integer(forKey: "itemBest")
            if itemScore > itemBestScore{
                itemBestScore = itemScore
                itemBestScoreLabelNode.text = "Coin Score:\(itemBestScore)"
                userDefaults.set(itemBestScore, forKey: "itemBest")
                userDefaults.synchronize()
            }
//ここまで
        }else{
            //壁か地面と衝突した
            print("GameOver")
            
            //スクロールを停止
            scrollNode.speed = 0
            
            //壁と衝突したとき地面まで落下させるために、一時的にgroundCategoryだけにして壁とは衝突させないようにする
            bird.physicsBody?.collisionBitMask = groundCategory
            
            //衝突したことを表現させるために回転させ、回転が終わった時にbirdのspeedも0にする
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
        }
    }
    
    //衝突後、画面をタップしたらリスタートするメソッド。
    //スコアを0、鳥の位置を初期位置に、壁をすべて取り除き、スクロール・鳥のspeedを1にもどす
    func restart(){
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        
//課題用に追加
        itemScore = 0
        itemScoreLabelNode.text = "Coin:¥\(itemScore)"
//ここまで
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
//課題用に追加
        coinNode.removeAllChildren()
//ここまで
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    //スコア・ベストスコアを表示する
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
// 課題として追加（ここから）
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Coin:¥\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        itemBestScoreLabelNode = SKLabelNode()
        itemBestScoreLabelNode.fontColor = .black
        itemBestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 150)
        itemBestScoreLabelNode.zPosition = 100
        itemBestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let itemBestScore = userDefaults.integer(forKey: "itemBest")
        itemBestScoreLabelNode.text = "Coin Score:\(itemBestScore)"
        self.addChild(itemBestScoreLabelNode)
// ここまで
    }
    
//課題として追加
    func setupItem(){
        let coinTexture = SKTexture(imageNamed: "coin.jpeg")
        coinTexture.filteringMode = .linear
        
        //coinの移動する距離
        let moveCoinDistance = CGFloat(self.frame.size.width + coinTexture.size().width)
        
        //画面外まで移動するアクション
        let moveCoin = SKAction.moveBy(x: -moveCoinDistance, y: 0, duration: 4)
        
        //coinを取り除くアクション
        let removeCoin = SKAction.removeFromParent()
        
        //画面外までのアクションと取り除くアクションを順に実行するアクション
        let coinAnimation = SKAction.sequence([moveCoin, removeCoin])
        
        
        //coinのY軸の下限位置
        let wallSize = SKTexture(imageNamed: "wall").size()

        
        //coinを生成するアクション
        let createCoinAnimation = SKAction.run({
            //coin関連のノードを乗せるノードを作成
            let coin = SKNode()
            coin.position = CGPoint(x: self.frame.size.width + coinTexture.size().width, y: wallSize.height)
            coin.zPosition = -70
            coin.xScale = 0.1
            coin.yScale = 0.1
            
            //coinの生成
            let coinCreate = SKSpriteNode(texture: coinTexture)
            coinCreate.position = CGPoint(x: 0, y: wallSize.height)
            
            //coinに物理演算を設定
            coinCreate.physicsBody = SKPhysicsBody(texture: coinTexture, size: coinTexture.size())
            
            //衝突の時に動かないようにする
            coinCreate.physicsBody?.isDynamic = false
            
            coin.addChild(coinCreate)
            
            //コインと鳥が衝突できるようにビットマスクを追加
            //※setupbBird()メソッドのカテゴリー設定にもitemScoreCategoryを追加した
            coinCreate.physicsBody?.categoryBitMask = self.itemScoreCategory
            
            coin.run(coinAnimation)
            
            self.coinNode.addChild(coin)
        })
        
        //次のcoin作成の待ち時間
        let waitCoinAnimation = SKAction.wait(forDuration: 1)
        
        let repeatForeverCoinAnimation = SKAction.repeatForever(SKAction.sequence([createCoinAnimation, waitCoinAnimation]))
        
        coinNode.run(repeatForeverCoinAnimation)
    }

}
