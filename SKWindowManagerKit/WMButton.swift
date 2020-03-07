//
//  WMButton.swift
//  SKWindowManagerKit
//
//  Created by Aaron Kreipe on 10/28/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit

public enum UserInteractionEvent{
    case began(point: CGPoint)
    case changed(point: CGPoint)
    case ended(inside: Bool)
    case cancelled
    case textInput(string: String)
}

public protocol UserControl{
    var isUserInteractionEnabled: Bool{get set}
    func event(_ event: UserInteractionEvent)
}

open class WMButton: ResizeableSpriteNode{
    public enum State{
        case disabled
        case normal
        case active
    }
    private(set) public var state = State.normal{
        didSet{
            if oldValue != state,
                let tex = texture(for: state){
                runSpriteAction(.animate(with: [tex], timePerFrame: 1/60))
            }
        }
    }
    override open var isUserInteractionEnabled: Bool{
        didSet{
            if isUserInteractionEnabled{
                state = .normal
            }else{
                state = .disabled
            }
        }
    }
    private var normalStateTexture: SKTexture?
    open var activeTexture: SKTexture?
    open var disabledTexture: SKTexture?
    public var action: (()->())?
    public func texture(for state: State)->SKTexture?{
        switch state {
            case .disabled: return activeTexture ?? normalStateTexture
            case .normal: return normalStateTexture
            case .active: return activeTexture ?? normalStateTexture
        }
    }
    public convenience init(textures: [WMButton.State: SKTexture], insets: UIEdgeInsets = .zero, size: CGSize? = nil, action: (()->())? = nil){
        let texture = textures[.normal]
        self.init(texture: texture, insets: insets, size: size ?? texture?.size() ?? .zero)
        self.action = action
        normalStateTexture = texture
        activeTexture = textures[.active]
        disabledTexture = textures[.disabled]
        isUserInteractionEnabled = true
        
    }
}

extension WMButton: UserControl{
    public func event(_ event: UserInteractionEvent) {
        guard state != .disabled else {return}
        switch event {
        case .began:
            state = .active
        case .ended(let inside):
            state = .normal
            if inside{
                action?()
            }
        case .cancelled:
            state = .normal
        default:
            break
        }
    }
}


