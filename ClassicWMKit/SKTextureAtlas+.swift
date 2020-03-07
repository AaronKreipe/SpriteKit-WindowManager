//
//  SKTextureAtlas+.swift
//  SpriteKitWindowManager
//
//  Created by Aaron Kreipe on 11/2/18.
//  Copyright © 2018 Aaron Kreipe. All rights reserved.
//

import SpriteKit

extension UIImage.Orientation{
    public var customDescription: String{
        switch self {
        case .up: return "⬆︎"
        case .down: return "⬇︎"
        case .left: return "⬅︎"
        case .right: return "➡︎"
        case .upMirrored: return "!⬆︎?"
        case .downMirrored: return "!⬇︎?"
        case .leftMirrored: return "!⬅︎?"
        case .rightMirrored: return "!➡︎?"
        }
    }
}

extension SKTextureAtlas{
    convenience init(imageNames: [String], in directory: URL){
        var imageDict = [String: UIImage]()
        for imageName in imageNames{
            let imageURL = directory.appendingPathComponent(imageName)
            do{
                let imageData = try Data(contentsOf: imageURL)
                guard let cgImage = UIImage(data: imageData, scale: 1.0)?.cgImage else{
                    preconditionFailure("unable to create UIImage from image data at: \(imageURL)")
                }
                let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
                imageDict[imageName] = image
            }catch let error{
                preconditionFailure("error loading imageData from: \(imageURL) error:\(error.localizedDescription)")
            }
        }
        self.init(dictionary: imageDict)
    }
}

