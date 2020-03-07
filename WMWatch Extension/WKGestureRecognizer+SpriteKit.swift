//
//  WKGestureRecognizer+SpriteKit.swift
//  AK⌚️
//
//  Created by Aaron Kreipe on 10/26/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import WatchKit

extension WKGestureRecognizer{
    var positionInScene: CGPoint{
        var pos = locationInObject()
        pos.y = objectBounds().maxY - pos.y
        return pos.applying(CGAffineTransform(scaleX: 2.0, y: 2.0))
    }
}
