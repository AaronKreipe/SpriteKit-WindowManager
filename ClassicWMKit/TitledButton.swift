//
//  TitledButton.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 11/2/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit
#if os(iOS)
import SKWindowManagerKit
#elseif os(watchOS)
import SKWindowManagerKit_Watch
#endif

class TitledButton: WMButton{
    var title: String?
    
    lazy var titleLabel: SKLabelNode = {
        return SKLabelNode(attributedText: nil)
    }()
    var isActive: Bool = false{
        didSet{
            if isActive{
                if let selectedTexture = selectedTextures[state]{
                    texture = selectedTexture
                }
            }else{
                texture = texture(for: state)
            }
        }
    }
    private var selectedTextures: [State: SKTexture] = [
        .normal: WMResources.shared.get(.selectedButtonNormal),
        .active: WMResources.shared.get(.selectedButtonActive)
    ]
    convenience init(size: CGSize, title: String? = nil, action: (()->())? = nil){
        self.init(
            textures: [
                .normal: WMResources.shared.get(.buttonNormal),
                .active: WMResources.shared.get(.buttonActive)
            ],
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            size: size,
            action: action
        )
    }
}
