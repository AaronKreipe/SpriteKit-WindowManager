//
//  MyNodeController.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 10/28/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit
import SKWindowManagerKit

extension CGRect{
    var center: CGPoint{
        return CGPoint(x: midX, y: midY)
    }
}

class MyNodeController: SKNodeController<SKSpriteNode>{
    override func load() -> SKSpriteNode {
        return SKSpriteNode(color: .green, size: CGSize(width: 100, height: 100))
    }
    override func didLoad() {
        node.position = CGPoint(x: 200, y: 200)
        
    }
    override func didAppear(_ animated: Bool) {
        node.run(.group([.scale(to: node.scene?.size ?? .zero, duration: 5.0), .move(to: node.scene?.frame.center ?? .zero, duration: 5.0)]))
        
    }
}
