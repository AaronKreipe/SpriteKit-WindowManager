//
//  SKSpriteNode+RepeatTexture.swift
//  SKWindowManagerKit
//
//  Created by Aaron Kreipe on 11/10/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit

extension vector_float2{
    public init(_ cgSize: CGSize){
        self.init(Float(cgSize.width), Float(cgSize.height))
    }
}

extension SKShader{
    public static let repeatingPattern: SKShader = {
        let shader = SKShader(source: """
void main(void){
    vec2 outOffset = 1.0/(spriteSize * 2.0);
    vec2 inOffset = 1.0/(textureSize * 2.0);
    vec2 oneOutputPixel = outOffset * 2.0;
    vec2 oneInputPixel = inOffset * 2.0;
    
    vec2 pCoord = (v_tex_coord - outOffset)/oneOutputPixel;
    pCoord = floor(pCoord + 0.5);

    vec2 tCoord = mod(pCoord, textureSize);
    tCoord = floor(tCoord + 0.5);
    
    vec2 lookupCoord = inOffset + (tCoord * oneInputPixel);
    
    gl_FragColor = texture2D(u_texture, lookupCoord);
}
""")
        shader.attributes = [
            SKAttribute(name: "textureSize", type: .vectorFloat2),
            SKAttribute(name: "spriteSize", type: .vectorFloat2)
        ]
        return shader
    }()
}

extension SKSpriteNode{
    public convenience init(repeating pattern: SKTexture, size: CGSize){
        self.init(texture: pattern)
        shader = SKShader.repeatingPattern
        setValue(SKAttributeValue(vectorFloat2: vector_float2(pattern.size())), forAttribute: "textureSize")
        setValue(SKAttributeValue(vectorFloat2: vector_float2(size)), forAttribute: "spriteSize")
        print("texSize: \(pattern.size())")
        print("size: \(size)")
        self.size = size
    }
}
