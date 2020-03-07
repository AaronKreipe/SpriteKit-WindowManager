//
//  WMResources.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 11/2/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//
import ImageIO
import SpriteKit
#if os(iOS)
import SKWindowManagerKit
#elseif os(watchOS)
import SKWindowManagerKit_Watch
#endif



public class WMResources{
    let bundle = Bundle(for: TitleBarNode.self)
    
    public lazy var atlas: SKTextureAtlas = {
        guard let resourceURL = bundle.resourceURL else {preconditionFailure("resourceURL not found for bundle: \(bundle)")}
        return SKTextureAtlas(imageNames: Resource.allCases.map{$0.rawValue + ".png"}, in: resourceURL)
    }()
    public enum Resource: String, CaseIterable{
        case colorsFourByFour
        case classicGray
        case buttonActive
        case buttonNormal
        case closeBoxActive
        case closeBoxNormal
        case selectedButtonActive
        case selectedButtonNormal
        case titlebarActive
        case titlebarDisabled
        case windowBorder
    }
    public func get(_ resource: Resource)->SKTexture{
        let texture = atlas.textureNamed(resource.rawValue)
        print("loading texture named:\(resource.rawValue)\n\tsize:\(texture.size())\n\trect:\(texture.textureRect())")
        texture.filteringMode = .linear
        return texture
    }
    public static let shared = WMResources()
    func registerFonts(in bundle: Bundle){
        
        let allFontUrls = bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil)
        for fontUrl in allFontUrls ?? []{
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(fontUrl as CFURL, .process, &error)
            if let error = error{
                print("error loading font at url: \(fontUrl) - \(error.takeUnretainedValue().localizedDescription)")
            }
        }
    }
}
