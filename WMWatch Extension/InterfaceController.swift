//
//  InterfaceController.swift
//  WMWatch Extension
//
//  Created by Aaron Kreipe on 10/28/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import WatchKit
import SpriteKit
import SKWindowManagerKit_Watch
import ClassicWMKit_Watch

let deviceScreenPixels: CGSize = {
    let currentDevice = WKInterfaceDevice.current()
    let width = currentDevice.screenBounds.width
    let height = currentDevice.screenBounds.height
    let scale = currentDevice.screenScale
    return CGSize(width: width * scale, height: height * scale)
}()

class InterfaceController: WKInterfaceController{
    @IBOutlet var group: WKInterfaceGroup!
    
    @IBOutlet var sceneInterface: WKInterfaceSKScene!
    
    @IBAction func tapped(_ gestureRecognizer: WKTapGestureRecognizer){
        let location = gestureRecognizer.positionInScene
        let state = WMGestureRecognizer.State(gestureRecognizer.state)
        windowManager.tapGestureUpdate(at: location, with: state)
    }
    
    @IBAction func longPressed(_ gestureRecognizer: WKLongPressGestureRecognizer){
        let location = gestureRecognizer.positionInScene
        let state = WMGestureRecognizer.State(gestureRecognizer.state)
        windowManager.longPressGestureUpdate(at: location, with: state)
    }
    
    
    let sceneSize = deviceScreenPixels
    
    lazy var windowManager: ClassicWindowManagerScene = {
        let wm = ClassicWindowManagerScene(size: sceneSize)
        //wm.backgroundColor = .clear
        return wm
    }()
    lazy var windowController: WindowController = {
        let controller = WindowController()
        controller.title = "Toys"
        return controller
    }()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        //group.setBackgroundColor(UIColor(patternImage: #imageLiteral(resourceName: "ClassicGray.png")))
        sceneInterface.presentScene(windowManager)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        sceneInterface.isPaused = false
        if !windowManager.children.contains(windowController.node){
             windowManager.present(windowController)
        }
    }
    
    override func didAppear() {
        super.didAppear()
        hideFSTime()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

func hideFSTime(){
    guard let cls =  NSClassFromString("SPFullScreenView") else {return}
    let viewControllers = (((NSClassFromString("UIApplication")?.value(forKey: "sharedApplication") as? NSObject)?.value(forKey: "keyWindow") as? NSObject)?.value(forKey: "rootViewController") as? NSObject)?.value(forKey: "viewControllers") as? [NSObject]
    viewControllers?.forEach{
        let views = ($0.value(forKey: "view") as? NSObject)?.value(forKey: "subviews") as? [NSObject]
        views?.forEach{
            if $0.isKind(of: cls){
                (($0.value(forKey: "timeLabel") as? NSObject)?.value(forKey: "layer") as? NSObject)?.perform(NSSelectorFromString("setOpacity:"), with: CGFloat(0))
            }
        }
    }
}
