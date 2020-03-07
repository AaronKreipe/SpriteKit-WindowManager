//
//  SKViewController.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 10/27/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit
import SKWindowManagerKit
import ClassicWMKit

class SKViewController: UIViewController{
    @IBOutlet var skView: SKView!{
        didSet{
            skView.showsDrawCount = true
            skView.showsNodeCount = true
        }
    }
    lazy var sceneTapGestureRecognizer: UITapGestureRecognizer = {
        let tapper = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapper.delegate = self
        return tapper
    }()
    lazy var sceneLongPressGestureRecognizer: UILongPressGestureRecognizer = {
        let longPresser = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        longPresser.delegate = self
        longPresser.minimumPressDuration = 0
        return longPresser
    }()
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        windowManager.size = nativeSizeForSize(size)
    }
    
    func nativeSizeForSize(_ size: CGSize? = nil)->CGSize{
        let nativeSize = (size ?? view.frame.size).applying(CGAffineTransform(scaleX: UIScreen.main.nativeScale, y: UIScreen.main.nativeScale))
        print("nativeSize: \(nativeSize) function:\(#function)")
        return nativeSize
    }
    lazy var windowManager: ClassicWindowManagerScene = {
        let wm = ClassicWindowManagerScene(size: nativeSizeForSize())
        return wm
    }()
    lazy var windowController: WindowController = {
        let controller = WindowController()
        controller.title = "Toys"
        return controller
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        skView.addGestureRecognizer(sceneTapGestureRecognizer)
        skView.addGestureRecognizer(sceneLongPressGestureRecognizer)
        sceneTapGestureRecognizer.require(toFail: sceneLongPressGestureRecognizer)
        skView.presentScene(windowManager)
        
        skView.isPaused = false
        if !windowManager.children.contains(windowController.node){
            windowManager.present(windowController)
        }
    }
    @objc func tapped(_ recognizer: UITapGestureRecognizer){
        let positionInView = skView.convert(recognizer.location(in: skView), to: windowManager)
        let state = WMGestureRecognizer.State.init(recognizer.state)
        windowManager.tapGestureUpdate(at: positionInView, with: state)
    }
    @objc func longPressed(_ recognizer: UITapGestureRecognizer){
        let positionInView = skView.convert(recognizer.location(in: skView), to: windowManager)
        let state = WMGestureRecognizer.State.init(recognizer.state)
        windowManager.longPressGestureUpdate(at: positionInView, with: state)
    }
}

extension SKViewController: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


