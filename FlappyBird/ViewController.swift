//
//  ViewController.swift
//  FlappyBird
//
//  Created by Norihiro.Nakano on 2020/12/28.
//  Copyright © 2020 Norihiro.Nakano. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //SKView型に変換する
        let skView = self.view as! SKView
        
        //FPSを表示する
        skView.showsFPS = true
        //showsFPS:画面が1秒間に何回更新されているかを示すFPSを画面右下に表示させる。
        
        //ノードの数を表示する
        skView.showsNodeCount = true
        //showsNodeCount:ノードがいくつ表示されているかを画面の右下に表示させる
        
        //ビューと同じサイズでシーンを作成
//      let scene = SKScene(size: skView.frame.size)
        let scene = GameScene(size: skView.frame.size) //←SKSceneをGameSeceneに変更
        
        //ビューにシーンを表示する
        skView.presentScene(scene)
    }
    
    //ステータスバーを消す
    override var prefersStatusBarHidden: Bool{
        get{
            return true
        }
    }


}

