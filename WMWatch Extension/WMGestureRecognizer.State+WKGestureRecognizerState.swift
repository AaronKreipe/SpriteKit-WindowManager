//
//  WMGestureRecognizer.State+WKGestureRecognizerState.swift
//  WMWatch Extension
//
//  Created by Aaron Kreipe on 11/7/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SKWindowManagerKit_Watch
import WatchKit

extension WMGestureRecognizer.State{
    init(_ state: WKGestureRecognizerState){
        switch state {
        case .began: self = .began
        case .changed: self = .changed
        case .recognized, .ended: self = .ended
        case .failed: self = .failed
        case .cancelled: self = .cancelled
        case .possible: self = .possible
        }
    }
}
