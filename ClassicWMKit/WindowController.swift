//
//  WindowController.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 10/28/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit
#if os(iOS)
    import SKWindowManagerKit
#elseif os(watchOS)
    import SKWindowManagerKit_Watch
#endif

public extension SKNode{
    var origin: CGPoint{
        get{
            return frame.origin
        }set{
            position.x = newValue.x + (position.x - origin.x)
            position.y = newValue.y + (position.y - origin.y)
        }
    }
}

public class ClassicWindowManagerScene: WindowManagerScene{
    lazy var background: SKSpriteNode = {
        let tex = WMResources.shared.get(.classicGray)
        let image = tex.cgImage()
        let texture = SKTexture(image: UIImage(cgImage: image))
        let background = SKSpriteNode(repeating: texture, size: size)
        return background
    }()
    public override func sceneDidLoad() {
        super.sceneDidLoad()
        background.anchorPoint = anchorPoint
        addChild(background)
    }
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        background.size = size
        background.setValue(SKAttributeValue(vectorFloat2: vector_float2(size)), forAttribute: "spriteSize")
    }
}

public class TitleBarNode: ResizeableSpriteNode{
    lazy var font: UIFont = {
        WMResources.shared.registerFonts(in: Bundle(for: TitleBarNode.self))
        guard let font = UIFont(name: "Chicago", size: 12) else {
            fatalError("could not load font")
        }
        return font
    }()
    lazy var labelAttributes: [NSAttributedString.Key: Any] = {
        return [
           .font: font,
           .foregroundColor: SKColor.black.cgColor,
        ]
    }()
    var title: String?{
        didSet{
            label.attributedText = attributedString(for: title)
            labelBackground.size = CGSize(width: label.frame.width + 10, height: 15)
        }
    }
    private func attributedString(for title: String?)->NSAttributedString{
        return NSAttributedString(string: "\(title ?? "-")", attributes: labelAttributes)
    }
    lazy var closeButton: WMButton = {
        let closeButton = WMButton(textures: [.normal: WMResources.shared.get(.closeBoxNormal), .active: WMResources.shared.get(.closeBoxActive)])
        closeButton.anchorPoint = .zero
        closeButton.position = CGPoint(x: 8, y: 3)
        return closeButton
    }()
    lazy var labelBackground: SKSpriteNode = {
        let labelBackground = SKSpriteNode(color: .white, size: CGSize(width: label.frame.width + 10, height: 15))
        labelBackground.anchorPoint = CGPoint(x: 0.5, y: 0)
    
        return labelBackground
    }()
    lazy var label: SKLabelNode = {
        let label = SKLabelNode(attributedText: attributedString(for: title))
        label.position = CGPoint(x: (size.width * 0.5).rounded(), y: 4)
        label.blendMode = .add
        return label
    }()
    override public var size: CGSize{
        didSet{
            label.position = CGPoint(x: (size.width * 0.5).rounded(), y: 4)
            labelBackground.position = CGPoint(x: label.position.x, y: 2)
        }
    }
    convenience init(width: CGFloat, title: String? = nil){
        let texture = WMResources.shared.get(.titlebarActive)
        texture.filteringMode = .linear
        self.init(texture: texture, insets: UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3), size: CGSize(width: width, height: 19))
        self.title = title
        addChild(labelBackground)
        addChild(label)
        labelBackground.position = CGPoint(x: label.position.x, y: 2)
        addChild(closeButton)
    }
}

open class ClassicWindow: ResizeableSpriteNode, WMGestureResponder{
    public var title: String?{
        didSet{
            titleBar.title = title
        }
    }
    open var contentSize: CGSize = CGSize(width: 200, height: 200){
        didSet{
            let windowSize = CGSize(width: contentSize.width + 2, height: contentSize.height + 2)
            size = windowSize
            titleBar.size.width = windowSize.width
        }
    }
    let titleBarDragRecognizer = WMGestureRecognizer(kind: .longPress)
    lazy var titleBar: TitleBarNode = {
        let titleBar = TitleBarNode(width: contentSize.width + 2, title: title)
        titleBar.position = CGPoint(x: 0, y: -1)
        titleBar.anchorPoint = .zero
        titleBarDragRecognizer.target = self
        titleBar.add(titleBarDragRecognizer)
        return titleBar
    }()
    convenience init(size: CGSize){
        let texture = WMResources.shared.get(.windowBorder)
        texture.filteringMode = .linear
        self.init(texture: texture, insets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2), size: CGSize(width: size.width + 2, height: size.height + 2))
        anchorPoint = CGPoint(x: 0, y: 1)
        addChild(titleBar)
    }
    private var lastTouchPosition: CGPoint?
    public func recognized(_ recognizer: WMGestureRecognizer) {
        func updatePosition(in parent: SKNode?){
            guard let initalPos = lastTouchPosition else {return}
            let newPos = recognizer.position(in: parent)
            position.x -= (initalPos.x - newPos.x)
            position.y -= (initalPos.y - newPos.y)
            lastTouchPosition = newPos
        }
        switch recognizer.state {
        case .began:
            lastTouchPosition = recognizer.position(in: parent)
        case .changed:
            updatePosition(in: parent)
        default:
            break
        }
    }
}

open class WindowController: SKNodeController<ClassicWindow>{
    private var initalContentSize: CGSize = CGSize(width: 200, height: 200)
    override open func load()->ClassicWindow{
        return  ClassicWindow(size: initalContentSize)
    }
    lazy var button: WMButton = {
        let button = WMButton(
            textures: [
                .normal: WMResources.shared.get(.selectedButtonNormal),
                .active: WMResources.shared.get(.selectedButtonActive)
            ],
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            size: CGSize(width: 100, height: 30)
        ){
            print("sweet :)")
        }
        button.texture?.filteringMode = .linear
        return button
    }()
    override open func didLoad() {
        node.title = title
        node.titleBar.closeButton.action = {[weak self] in
            self?.node.titleBar.remove(self!.node.titleBarDragRecognizer)
            self?.dismiss(animated: true)
        }
        node.position = CGPoint(x: 30, y: 230)
    }
    override open func didAppear(_ animated: Bool) {
        node.addChild(button)
        button.position = CGPoint(x: 80, y: -50)
    }
}

