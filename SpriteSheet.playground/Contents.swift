import SpriteKit

extension Array{
    init(reserving count: Int){
        self.init()
        reserveCapacity(capacity)
    }
    mutating func dequeNext()->Element?{
        guard !isEmpty else {return nil}
        return removeFirst()
    }
}

extension CGRect{
    var area: CGFloat{
        return size.width * size.height
    }
    func contains(x: CGFloat)->Bool{
        return self.contains(CGPoint(x: x, y: midY))
    }
    func contains(y: CGFloat)->Bool{
        return self.contains(CGPoint(x: midX, y: y))
    }
}

extension Collection where Element == CGRect{
    var area: CGFloat{
        return self.reduce(0, {$0 + $1.area})
    }
}

extension Collection where Element: Collection, Element.Element == CGRect{
    var area: CGFloat{
        return self.reduce(0, {$0 + $1.area})
    }
}

extension CGPoint{
    func fits(in rect: CGRect)->Bool{
        return (rect.minX...rect.maxX).contains(x) && (rect.minY...rect.maxY).contains(y)
    }
}


extension CGImage{
    var size: CGSize{
        return CGSize(width: width, height: height)
    }
}

public class SpriteSheet: Codable{
     let data: Data
    private let size: CGSize
    private lazy var texture: SKTexture = {
        let image = UIImage(data: data, scale: 1)!
        let texture = SKTexture(image: image)
        return texture
    }()
     let spriteRects: [String: CGRect]
    public func sprite(named name: String)->SKTexture{
        let tex = SKTexture(rect: spriteRects[name]!, in: texture)
        tex.filteringMode = .linear
        return tex
    }
    public init(data: Data, size: CGSize, spriteRects: [String: CGRect]){
        self.data = data
        self.size = size
        self.spriteRects = spriteRects
    }
}

class SpriteSheetGenerator{
    let count: Int
    let minimumWidth: CGFloat
    let names: [String]
    let images: [CGImage]
    let sheetWidths: [CGFloat]
    init(_ dict: [String: CGImage]){
        count = dict.count
        var n = [String](reserving: count)
        var i = [CGImage](reserving: count)
        var w = [CGFloat](reserving: count)
        var sheetWidth: CGFloat = 0
        var minWidth: CGFloat = 0
        var width: CGFloat
        for (name, image) in dict.sorted(by: {$0.value.height > $1.value.height}){
            n.append(name)
            i.append(image)
            width = CGFloat(image.width)
            sheetWidth += width
            w.append(sheetWidth)
            if width > minWidth{
                minWidth = width
            }
        }
        self.minimumWidth = minWidth
        self.names = n
        self.images = i
        self.sheetWidths = w
    }
    struct FrameInfo{
        let spriteFrame: CGRect
        let emptyRect: CGRect
        let occupiedEmptyRectIndex: Int?
    }
    class Row: CustomStringConvertible{
        
        private weak var previous: Row?
        let startIndex: Int
        var endIndex: Int{
            return startIndex + imageFrames.count
        }
        private(set) var frame: CGRect
        private var position: CGPoint
        
        private(set) var imageFrames = [CGRect]()
        private(set) var emptyRects = [CGRect]()
        private var lastAddedImageFrame = CGRect.zero
        private func imageAboveY(atX x: CGFloat)->CGFloat{
            return imageFrames.filter({$0.contains(x: x)}).first?.maxY ?? previous?.imageAboveY(atX: x) ?? 0
        }
        
        // this only works if images are added in order from tallest to shortest
        public func spriteFrameInfo(for image: CGImage)->FrameInfo?{
            let imageSize = image.size
            var newEmptyRect = CGRect.zero
            var occupiedEmptyRectIndex: Int?
            if imageFrames.isEmpty{
                // first frame is the tallest -> set frame height
                // position is already set to .zero
                frame.size.height = CGFloat(imageSize.height)
                newEmptyRect = .zero // just to keep indices in sync
                print("firstFrame:\(frame) imageFrame:\(CGRect(origin: position, size: imageSize))")
            }else{
                // calculate next pos
                let imageSize = image.size
                var fitVertical = false
                
                for i in emptyRects.indices{
                    let verticalExtent = CGPoint(x: emptyRects[i].origin.x + imageSize.width, y: emptyRects[i].origin.y + imageSize.height)
                    if verticalExtent.fits(in: emptyRects[i]){ // will fit below image i
                        print("frame:\(frame) contains verticalExtent:\(verticalExtent), index:\(endIndex + 1)")
                        position = emptyRects[i].origin
                        newEmptyRect = CGRect(x: position.x, y: verticalExtent.y, width: frame.maxX - position.x, height: frame.maxY - verticalExtent.y)
                        occupiedEmptyRectIndex = i
                        //emptyRects[i] = CGRect(x: emptyRects[i].minX + imageSize.width, y: emptyRects[i].minY, width: emptyRects[i].width - imageSize.width, height: emptyRects[i].height)
                        fitVertical = true
                        break
                    }
                }
                if !fitVertical{// check horizontal
                    let imageMinY = previous?.imageAboveY(atX: position.x) ?? frame.origin.y
                    let horizontalExtent = CGPoint(x: imageFrames.last!.maxX + imageSize.width, y: imageMinY + imageSize.height)
                    if horizontalExtent.fits(in: frame){
                        print("frame:\(frame) contains horizontalExtent:\(horizontalExtent), index:\(endIndex + 1)")
                        position.x = imageFrames.last!.maxX
                        newEmptyRect = CGRect(x: position.x, y: horizontalExtent.y, width: frame.maxX - position.x, height: frame.maxY - horizontalExtent.y)
                    }else{
                        print("frame:\(frame) wontFit:\(horizontalExtent), index:\(endIndex + 1)")
                        return nil
                    }
                }
            }
            let frameInfo = FrameInfo(spriteFrame: CGRect(origin: position, size: imageSize), emptyRect: newEmptyRect, occupiedEmptyRectIndex: occupiedEmptyRectIndex)
            return frameInfo
        }
        public func add(_ frameInfo: FrameInfo){
            imageFrames.append(frameInfo.spriteFrame)
            if let occupiedEmptyIndex = frameInfo.occupiedEmptyRectIndex{
                // modify occupied empty rects
                for i in occupiedEmptyIndex..<emptyRects.count{
                    if CGPoint(x: frameInfo.spriteFrame.maxX, y: frameInfo.spriteFrame.maxY).fits(in: emptyRects[i]){
                        if i > occupiedEmptyIndex{
                            // need to add a new empty rect above the sprite (between the sprite above this one and the sprite) 
                            emptyRects[i-1].size.height = frameInfo.spriteFrame.origin.y - emptyRects[i-1].origin.y
                            i
                        }
                        // the sprite will create a new empty rect below it -> set the front edge of this empty rect to the sprite frame maxX and resize it.
                        let newMaxX = min(frame.maxX, frameInfo.spriteFrame.maxX)
                        emptyRects[i].origin.x = newMaxX
                        emptyRects[i].size.width = emptyRects[i].maxX - newMaxX
                        i
                    }else{
                        // the sprite doesnt overlap any other empty rects -> were done here
                        break
                    }
                }
            }
            emptyRects.append(frameInfo.emptyRect)
        }
        public init(width: CGFloat){
            startIndex = 0
            frame = CGRect(x: 0, y: 0, width: width, height: 0)
            position = .zero
        }
        public init(_ previousRow: Row){
            previous = previousRow
            startIndex = previousRow.endIndex
            position = CGPoint(x: 0, y: previousRow.frame.maxY)
            frame = CGRect(x: 0, y: position.y, width: previousRow.frame.width, height: 0)
        }
        public var description: String{
            return "Row<\(startIndex)..<\(endIndex)> frame:\(frame), imageFrames:\(imageFrames)"
        }
    }
    
    private func buildRows(maximumWidth: CGFloat)->[Row]{
        var rows = [Row]()
        var row: Row?
        var createRow = true
        var i = 0
        while i < count{
            i
            if createRow{
                createRow = false
                if let previousRow = row{
                    rows.append(previousRow)
                    row = Row(previousRow)
                }else{
                    row = Row(width: maximumWidth)
                }
            }
            if let imageFrameInfo = row?.spriteFrameInfo(for: images[i]){
                row?.add(imageFrameInfo)
                i += 1
            }else{
                createRow = true
            }
        }
        if let lastRow = row{
            rows.append(lastRow)
        }
        return rows
    }
    
    private func calculateBestRows()->[Row]{
        var bestArea = CGFloat.greatestFiniteMagnitude
        var bestRows = [Row]()
        sheetWidths
        for width in sheetWidths.filter({$0 >= minimumWidth}).reversed(){
            width
            let rows = buildRows(maximumWidth: width)
            print(rows)
            let (x,y) = (rows.last!.frame.maxX, rows.last!.frame.maxY)
            print(x,y)
            let area = x * y
            print(area)
            if area < bestArea{
                bestArea = area
                bestRows = rows
            }
        }
        return bestRows
    }
    
    private func createRenderer(for frame: CGRect)->UIGraphicsImageRenderer{
        let format = UIGraphicsImageRendererFormat(for: UITraitCollection(displayScale: 1.0))
        let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)
        return renderer
    }
    public func build(_ completion: (SpriteSheet)->()){
        precondition(count > 0, "cannot build SpriteSheet with no sprites!")
        let rows = calculateBestRows()
        let imageFrame = CGRect(x: 0, y: 0, width: rows.last!.frame.maxX, height: rows.last!.frame.maxY)
        let renderer = createRenderer(for: imageFrame)
        let spriteFrames = rows.flatMap{$0.imageFrames}
        let image = renderer.pngData{
            for i in 0..<count{
                $0.cgContext.setShouldAntialias(false)
                $0.cgContext.setAllowsAntialiasing(false)
                $0.cgContext.draw(images[i], in: spriteFrames[i])
            }
        }
        //convert imageRects to spriteRects 0...1
        let transform = CGAffineTransform(scaleX: 1/imageFrame.width, y: -1/imageFrame.height).concatenating(CGAffineTransform(translationX: 0, y: 1))
        let spriteRects = spriteFrames.map{$0.applying(transform)}
        
        completion(SpriteSheet(data: image, size: imageFrame.size, spriteRects: Dictionary(uniqueKeysWithValues: zip(names,spriteRects))))
    }
}

let imageNames =
    ["buttonNormal",
     "buttonActive",
     "classicGray",
     "closeBoxActive",
     "closeBoxNormal",
     "selectedButtonActive",
     "selectedButtonNormal",
     "titlebarActive",
     "titlebarDisabled",
     "windowBorder"]

let imageDict = Dictionary(uniqueKeysWithValues: imageNames.map{($0, UIImage(named: $0)!.cgImage!)})

let gen = SpriteSheetGenerator(imageDict)

gen.build{
    let sheet = UIImage(data: $0.data, scale: 1)
    let sprite = SKSpriteNode(texture:  $0.sprite(named: "titlebarActive"))
    let encoder = JSONEncoder()
    let encodedData = try? encoder.encode($0)
    encodedData
    
    let decoder = JSONDecoder()
    let decodedSheet = try? decoder.decode(SpriteSheet.self, from: encodedData!)
    let tex = decodedSheet?.sprite(named: "buttonNormal")
    let n = SKSpriteNode(texture: tex!)
}




