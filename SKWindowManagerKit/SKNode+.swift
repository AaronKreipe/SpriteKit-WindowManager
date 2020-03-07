//
//  SKNode+.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 10/30/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit

extension SKNode{
    var ancestors: [SKNode]{
        return children + children.reduce([SKNode](), {$0 + $1.ancestors})
    }
}
