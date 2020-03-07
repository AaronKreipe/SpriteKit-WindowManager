//
//  ResizeableSpriteNode.swift
//  WMWatch Extension
//
//  Created by Aaron Kreipe on 11/1/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit

open class ResizeableSpriteNode: SKNode{
    open var insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0){
        didSet{
            spriteNode.centerRect = centerRect
        }
    }
    private var centerRect: CGRect{
        get{
            guard let textureSize = texture?.size() else{
                return .zero
            }
            return CGRect(
                x: insets.left/textureSize.width,
                y: insets.bottom/textureSize.height,
                width: (textureSize.width - (insets.left + insets.right))/textureSize.width,
                height: (textureSize.height - (insets.top + insets.bottom))/textureSize.height
            )
        }
    }
    open var texture: SKTexture?{
        didSet{
            spriteNode.anchorPoint = anchorPoint
            spriteNode.texture = texture
            spriteNode.size = texture?.size() ?? .zero
            spriteNode.centerRect = centerRect
            spriteNode.scale(to: size)
        }
    }
    open var anchorPoint = CGPoint(x: 0.5, y: 0.5){
        didSet{
            spriteNode.anchorPoint = anchorPoint
        }
    }
    open var size: CGSize{
        didSet{
            spriteNode.scale(to: size)
        }
    }
    private lazy var spriteNode: SKSpriteNode = {
        let spriteNode = SKSpriteNode(texture: texture)
        spriteNode.anchorPoint = anchorPoint
        spriteNode.texture = texture
        spriteNode.centerRect = centerRect
        spriteNode.scale(to: size)
        return spriteNode
    }()
    override open var frame: CGRect{
        get{return CGRect(origin: position.applying(CGAffineTransform(translationX: -size.width * anchorPoint.x, y: -size.height * anchorPoint.y)), size: size)}
        set{}
    }
    public init(texture: SKTexture?, insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), size: CGSize? = nil){
        self.insets = insets
        self.size = size ?? texture?.size() ?? .zero
        self.texture = texture
        super.init()
        addChild(spriteNode)
    }
    enum CodingKey: String{
        case insets
        case size
        case texture
    }
    required public init?(coder aDecoder: NSCoder){
        insets = aDecoder.decodeUIEdgeInsets(forKey: CodingKey.insets.rawValue)
        size = aDecoder.decodeCGSize(forKey: CodingKey.size.rawValue)
        texture = aDecoder.decodeObject(forKey: CodingKey.texture.rawValue) as! SKTexture?
        super.init(coder: aDecoder)
    }
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(insets, forKey: CodingKey.insets.rawValue)
        aCoder.encode(size, forKey: CodingKey.size.rawValue)
        aCoder.encode(texture, forKey: CodingKey.texture.rawValue)
    }
    func runSpriteAction(_ action: SKAction, completion: (()->())? = nil){
        if let completion = completion{
            spriteNode.run(action, completion: completion)
        }else{
            spriteNode.run(action)
        }
    }
}
