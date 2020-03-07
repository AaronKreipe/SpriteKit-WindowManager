//
//  WMGestureRecognizer.State+UIGestureRecognizerState.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 11/7/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import UIKit
import SKWindowManagerKit

extension WMGestureRecognizer.State{
    init(_ uiState: UIGestureRecognizer.State){
        switch uiState {
        case .possible: self = .possible
        case .began: self = .began
        case .changed: self = .changed
        case .ended: self = .ended
        case .failed: self = .failed
        case .cancelled: self = .cancelled
        }
    }
}
