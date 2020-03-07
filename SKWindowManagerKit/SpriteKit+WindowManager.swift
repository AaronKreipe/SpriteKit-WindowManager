//
//  SpriteKit+WindowManager.swift
//  SKWindowManagerKit
//
//  Created by Aaron Kreipe on 10/27/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit

public protocol WMGestureResponder{
    func recognized(_ recognizer: WMGestureRecognizer)
}

public class WMGestureRecognizer: Equatable{
    public static func == (lhs: WMGestureRecognizer, rhs: WMGestureRecognizer) -> Bool {
        return lhs === rhs
    }
    
    public enum State{
        case possible
        case began
        case changed
        case failed
        case cancelled
        case ended
    }
    public enum Kind{
        case tap
        case longPress
        case pan
    }
    let kind: Kind
    
    fileprivate(set) public var state = State.possible
    fileprivate weak var windowManager: WindowManagerScene?
    fileprivate var scenePosition: CGPoint = .zero
    fileprivate weak var node: SKNode?
    public var target: WMGestureResponder?
    public func position(in node: SKNode?)->CGPoint{
        guard let windowManager = windowManager else {return .zero}
        return windowManager.convert(scenePosition, to: node ?? windowManager)
    }
    fileprivate func event(at point: CGPoint, with state: State){
        scenePosition = point
        self.state = state
        target?.recognized(self)
    }
    public init(kind: Kind){
        self.kind = kind
    }
}

extension SKNode{
    public func add(_ gestureRecognizer: WMGestureRecognizer){
        guard !gestureRecognizers.contains(gestureRecognizer) else {return}
        
        gestureRecognizer.node = self
        gestureRecognizers.append(gestureRecognizer)
        (scene as? WindowManagerScene)?.register(gestureRecognizer)
    }
    public func remove(_ gestureRecognizer: WMGestureRecognizer){
        (scene as? WindowManagerScene)?.unregister(gestureRecognizer)
        if let index = gestureRecognizers.index(of: gestureRecognizer){
            gestureRecognizers.remove(at: index)
        }
    }
    fileprivate(set) public var gestureRecognizers: [WMGestureRecognizer]{
        get{return (userData?["gestureRecognizer"] as? [WMGestureRecognizer]) ?? []}
        set{
            if userData == nil{
                userData = [:]
            }
            userData!["gestureRecognizer"] = newValue
        }
    }
}

typealias UserControlNode = SKNode & UserControl

open class WindowManagerScene: SKScene{
    // the queue used to load node controllers
    private lazy var loadingQueue: DispatchQueue = {
        let q = DispatchQueue(label: "WindowManager<\(Unmanaged.passUnretained(self).toOpaque())> loading Queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        return q
    }()
    // the gesture recognizers that have been registered with this scene
    private var skGestureRecognizers = [WMGestureRecognizer]()
    fileprivate func register(_ gestureRecognizer: WMGestureRecognizer){
        guard !skGestureRecognizers.contains(gestureRecognizer) else {return}
        gestureRecognizer.windowManager = self
        skGestureRecognizers.append(gestureRecognizer)
    }
    fileprivate func unregister(_ gestureRecognizer: WMGestureRecognizer){
        gestureRecognizer.windowManager = nil
        guard let index = skGestureRecognizers.index(of: gestureRecognizer) else{
            return
        }
        skGestureRecognizers.remove(at: index)
    }
    // the active control that is currently receiving events
    private var activeControl: UserControlNode?
    
    // public gesture functions - to be called from view by some input device
    public func tapGestureUpdate(at pos: CGPoint, with state: WMGestureRecognizer.State){
        for gestureRecognizer in skGestureRecognizers where gestureRecognizer.kind == .tap{
            guard let node = gestureRecognizer.node,
                let parent = node.parent else {return}
            let positionInParent = convert(pos, to: parent)
            if node.contains(positionInParent){
                gestureRecognizer.event(at: pos, with: state)
            }
        }
    }
    var activeLongPressGestureRecognizers = [WMGestureRecognizer]()
    public func longPressGestureUpdate(at pos: CGPoint, with state: WMGestureRecognizer.State){
        switch state{
        case .began:
            //send events to gesture recognizers
            for gestureRecognizer in skGestureRecognizers where gestureRecognizer.kind == .longPress{
                gestureRecognizer.state = state
                gestureRecognizer.scenePosition = pos
                guard let node = gestureRecognizer.node,
                    let parent = node.parent else {return}
                let positionInParent = convert(pos, to: parent)
                if node.contains(positionInParent){
                    gestureRecognizer.event(at: pos, with: state)
                    activeLongPressGestureRecognizers .append(gestureRecognizer)
                }
            }
            // send events to user controls
            let potentialUserControls = nodes(at: pos)
            for node in potentialUserControls where node is UserControlNode && node.isUserInteractionEnabled == true{
                let userControl = node as! UserControlNode
                let positionInParent = convert(pos, to: userControl.parent!) // can not be nil if this node is in our tree
                userControl.event(.began(point: positionInParent))
                activeControl = userControl
                break
            }
        case .changed:
            //send events to gesture recognizers
            for gestureRecognizer in activeLongPressGestureRecognizers{
                gestureRecognizer.state = state
                gestureRecognizer.scenePosition = pos
                gestureRecognizer.event(at: pos, with: state)
            }
            // send events to user controls
            guard let control = activeControl,
                let parent = control.parent else {return}
            let positionInParent = convert(pos, to: parent)
            control.event(.changed(point: positionInParent))
        case .ended:
            //send events to gesture recognizers
            for gestureRecognizer in activeLongPressGestureRecognizers{
                gestureRecognizer.state = state
                gestureRecognizer.scenePosition = pos
                gestureRecognizer.event(at: pos, with: state)
                gestureRecognizer.state = .possible
            }
            activeLongPressGestureRecognizers = []
            // send events to user controls
            guard let control = activeControl,
                let parent = control.parent else {return}
            activeControl = nil
            let positionInParent = convert(pos, to: parent)
            control.event(.ended(inside: control.contains(positionInParent)))
        case .cancelled, .failed:
            //send events to gesture recognizers
            for gestureRecognizer in activeLongPressGestureRecognizers{
                gestureRecognizer.state = state
                gestureRecognizer.scenePosition = pos
                gestureRecognizer.event(at: pos, with: state)
                gestureRecognizer.state = .possible
            }
            activeLongPressGestureRecognizers = []
            // send events to user controls
            activeControl?.event(.cancelled)
            activeControl = nil
        case .possible:
            break
        }
    }
    public func panGestureUpdate(at pos: CGPoint, with state: WMGestureRecognizer.State){
        for gestureRecognizer in skGestureRecognizers where gestureRecognizer.kind == .pan{
            guard let node = gestureRecognizer.node else {return}
            let positionInNode = convert(pos, to: node)
            if node.contains(positionInNode){
                gestureRecognizer.event(at: pos, with: state)
            }
        }
    }
    // a stack of blocks to run during the update lifecycle - if not empty, the last block will be popped from the stack and called each time update is called.
    private var updateBlocks = [()->()]()
    private func addUpdateBlock(_ block: @escaping ()->()){
        updateBlocks.insert(block, at: 0)
    }
    // public func to present a node controller
    public func present<T: SKNode>(_ nodeController: SKNodeController<T>, with action: SKAction = .sequence([.fadeOut(withDuration: 0), .fadeIn(withDuration: 0.25)])){
        nodeController.windowManager = self
        switch nodeController.state {
        case .inital:
            nodeController.state = .loading
            let node = nodeController.load()
            nodeController.node = node
            addUpdateBlock{[weak self] in
                self?._nodeControllerDidLoadNode(nodeController, node: node, action: action)
            }
//            loadingQueue.async{
//                let node = nodeController.load()
//                nodeController.node = node
//                DispatchQueue.main.async{[weak self] in
//                    self?._nodeControllerDidLoadNode(nodeController, node: node, action: action)
//                }
//            }
        case .loaded:
            updateBlocks.insert({[weak self] in
                self?._nodeControllerPresentNode(nodeController, node: nodeController.node, action: action)
                }, at: 0)
        default:
            fatalError("SKNode controller must be in the initalized or loaded state to be presented.  Current state is:\(nodeController.state)")
            break
        }
        
    }
    // node controller lifecycle functions
    private func _nodeControllerDidLoadNode<T: SKNode>(_ nodeController: SKNodeController<T>, node: T, action: SKAction){
        nodeController.state = .loaded
        nodeController.didLoad()
        updateBlocks.insert({[weak self] in
            self?._nodeControllerPresentNode(nodeController, node: node, action: action)
        }, at: 0)
    }
    private func _nodeControllerPresentNode<T: SKNode>(_ nodeController: SKNodeController<T>, node: T, action: SKAction){
        nodeController.state = .appearing
        nodeController.willAppear(true)
        node.alpha = 0
        addChild(node)
        node.run(.fadeIn(withDuration: 0.25)){
            nodeController.state = .presented
            nodeController.didAppear(true)
        }
    }
    fileprivate func dismiss<T: SKNode>(_ nodeController: SKNodeController<T>, animated: Bool = true, with action: SKAction = .fadeOut(withDuration: 0.25)){
        var dismissAction = SKAction()
        if animated{
            dismissAction = action
        }
        updateBlocks.insert({
            nodeController.state = .disappearing
            nodeController.willDisappear(true)
            nodeController.node.run(dismissAction){
                nodeController.state = .loaded
                nodeController.didDisappear(true)
                nodeController.node.removeFromParent()
            }
        }, at: 0)
    }
    // override update to process blocks form the update stack
    override open func update(_ currentTime: TimeInterval) {
        if let updateBlock = updateBlocks.popLast(){
            updateBlock()
        }
        super.update(currentTime)
    }
    // override add child to register gesture recognizers
    override open func addChild(_ node: SKNode) {
        ([node] + node.ancestors).forEach{$0.gestureRecognizers.forEach(register)}
        super.addChild(node)
    }
}

open class SKNodeController<Node: SKNode>{
    fileprivate weak var windowManager: WindowManagerScene?
    public enum State{
        case inital
        case loading
        case loaded
        case appearing
        case presented
        case disappearing
    }
    fileprivate(set) public var state: State = .inital
    public lazy var node: Node = {
        return load()
    }()
    open var title: String?
    open func load()->Node{return Node()}
    open func didLoad(){}
    open func willAppear(_ animated: Bool){}
    open func didAppear(_ animated: Bool){}
    open func willDisappear(_ animated: Bool){}
    open func didDisappear(_ animated: Bool){}
    public func dismiss(animated: Bool){
        windowManager?.dismiss(self, animated: animated)
    }
    public init(){}
}
