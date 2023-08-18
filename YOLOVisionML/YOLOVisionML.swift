//
//  YOLOVisionML.swift
//  YOLOVisionML
//
//  Created by Jade Choghari on 17/08/2023.
//

import Foundation
import Vision
import Accelerate
import CoreML
import UIKit

public final class YOLOVisionML {
    
    
    // functionality here
//    let img_width: Double = 1170
//    let img_height: Double = 1516
    public var img_width: Double
    public var img_height: Double
    
    
    // Initialize the class with image width and height
        public init(img_width: Double, img_height: Double) {
            self.img_width = img_width
            self.img_height = img_height
        }
    //Step 7
    public func reshapeToMatrix(array: [Decimal], rows: Int, cols: Int) -> [[Decimal]] {
        var matrix: [[Decimal]] = []
        
        for i in 0..<rows {
            let startIndex = i * cols
            let endIndex = startIndex + cols
            let row = Array(array[startIndex..<endIndex])
            matrix.append(row)
        }
        
        return matrix
    }
    
    // to 160 x 160
    public func sigmoid(_ x: Decimal) -> Decimal {
        let doubleX = NSDecimalNumber(decimal:x).doubleValue
        let result = 1.0 / (1.0 + exp(-doubleX))
        return Decimal(result)
    }

    public func sigmoidMatrix(_ matrix: [[Decimal]]) -> [[Decimal]] {
        return matrix.map { row in
            return row.map { element in
                sigmoid(element)
            }
        }
    }
    
    public func createMask(from matrix: [[Decimal]]) -> [[UInt8]] {
        let threshold: Decimal = 0.5 //!!!!!!
        let white: UInt8 = 255
        let black: UInt8 = 0

        return matrix.map { row in
            row.map { element in
                return element > threshold ? white : black
            }
        }
    }
    
    public func parseRow(row: [Decimal]) -> [Decimal] {
        // Extracting the values using array slicing
        let extractedValues = Array(row[..<4])

        // Assigning variables of type Decimal
        var xc: Decimal = 0, yc: Decimal = 0, w: Decimal = 0, h: Decimal = 0

        if extractedValues.count >= 4 {
            xc = extractedValues[0]
            yc = extractedValues[1]
            w = extractedValues[2]
            h = extractedValues[3]
        }

        let img_width: Decimal = 1170
        let img_height: Decimal = 1516

        // Example values for xc, yc, w, h (using Decimal type)
        let x1 = (xc - w/2) / 640 * img_width
        let y1 = (yc - h/2) / 640 * img_height
        let x2 = (xc + w/2) / 640 * img_width
        let y2 = (yc + h/2) / 640 * img_height
        
        
        // Finding the maximum probability value and its index
        var maxProbability: Decimal = 0
        var classId: Int = 0

        for (index, value) in row.enumerated() where index >= 4 {
            if value > maxProbability {
                maxProbability = value
                classId = index
            }
        }
        
        // Creating an array with the desired values
        let result: [Decimal] = [x1, y1, x2, y2, Decimal(classId), maxProbability]
        
        return result
    }
    
    public func get_mask(row: [Decimal], box: (Decimal, Decimal, Decimal, Decimal)) -> [[UInt8]] {
        let mask1 = Array(row[5...25604])
        let reshapedMatrix = reshapeToMatrix(array: mask1, rows: 160, cols: 160)
        let sigmoidMatrix = sigmoidMatrix(reshapedMatrix)
        
        let x1 = box.0
        let y1 = box.1
        let x2 = box.2
        let y2 = box.3
        
        let mask_x1 = max(0, min(159, Int(round((NSDecimalNumber(decimal: x1).doubleValue / NSDecimalNumber(decimal: Decimal(img_width)).doubleValue) * 160))))
        let mask_y1 = max(0, min(159, Int(round((NSDecimalNumber(decimal: y1).doubleValue / NSDecimalNumber(decimal: Decimal(img_height)).doubleValue) * 160))))
        let mask_x2 = max(0, min(159, Int(round((NSDecimalNumber(decimal: x2).doubleValue / NSDecimalNumber(decimal: Decimal(img_width)).doubleValue) * 160))))
        let mask_y2 = max(0, min(159, Int(round((NSDecimalNumber(decimal: y2).doubleValue / NSDecimalNumber(decimal: Decimal(img_height)).doubleValue) * 160))))
   
        // Perform the mask selection
      
        let binaryMask = createMask(from: sigmoidMatrix)
        print("this is the mask")
        var selectedMask = [[UInt8]]()
        for i in mask_y1..<mask_y2 - 1 {
            let row = Array(binaryMask[i][mask_x1..<mask_x2])
            selectedMask.append(row)
        }
        
        
//                let selectedMask = binaryMask[Int(mask_y1)..<Int(mask_y2)].map { Array($0[Int(mask_x1)..<Int(mask_x2)]) }
        
//                let maskImage = convertToUIImage(mask: selectedMask)
        
//                let newSize = CGSize(width: Int(round(NSDecimalNumber(decimal: x2 - x1).doubleValue)),
//                                     height: Int(round(NSDecimalNumber(decimal: y2 - y1).doubleValue)))
//                let resizedImage = resizeMask(image: maskImage!, targetSize: newSize)
//
//                imageView.image = resizedImage
//                let maskArray = imageToArray(image: resizedImage)
//                return maskArray!
        return selectedMask
    }
    // lets see this method because it needs to be of type decimal not any
    public struct ParsedRow {
        let x1: Decimal
        let y1: Decimal
        let x2: Decimal
        let y2: Decimal
        let classId: Decimal
        let maxProbability: Decimal
        let mask: [[UInt8]]
        let index: Int
    }
    public func parseRowMask(index: Int, row: [Decimal]) -> ParsedRow {
        // Extracting the values using array slicing
        let extractedValues = Array(row[..<4])

        // Assigning variables of type Decimal
        var xc: Decimal = 0, yc: Decimal = 0, w: Decimal = 0, h: Decimal = 0

        if extractedValues.count >= 4 {
            xc = extractedValues[0]
            yc = extractedValues[1]
            w = extractedValues[2]
            h = extractedValues[3]
        }

        let img_width: Decimal = 1170
        let img_height: Decimal = 1516

        // Example values for xc, yc, w, h (using Decimal type)
        let x1 = (xc - w/2) / 640 * img_width
        let y1 = (yc - h/2) / 640 * img_height
        let x2 = (xc + w/2) / 640 * img_width
        let y2 = (yc + h/2) / 640 * img_height

        // Finding the maximum probability value and its index
        var maxProbability: Decimal = 0
        var classId: Int = 0

        for (index, value) in row.enumerated() where index >= 4 {
            if value > maxProbability {
                maxProbability = value
                classId = index
            }
        }
        let box: (Decimal, Decimal, Decimal, Decimal) = (x1, y1, x2, y2)
        let mask = get_mask(row: row, box: box)
        // Creating an array with the desired values
        
        return ParsedRow(x1: x1, y1: y1, x2: x2, y2: y2, classId: Decimal(classId), maxProbability: maxProbability, mask: mask, index: index)
    }
    public func overlayMask(baseImage: UIImage, mask: UIImage, color: UIColor) -> UIImage? {
        // Create a new image context
        UIGraphicsBeginImageContextWithOptions(baseImage.size, false, baseImage.scale)
        
        // Draw the base image
        baseImage.draw(in: CGRect(origin: .zero, size: baseImage.size))

        // Set the blend mode and color for the mask
        color.set()
        
        // Calculate the position for the mask
        let maskRect = CGRect(x: (baseImage.size.width - mask.size.width) / 2,
                              y: (baseImage.size.height - mask.size.height) / 2,
                              width: mask.size.width,
                              height: mask.size.height)
        
        // Draw the mask
        mask.draw(in: maskRect, blendMode: .normal, alpha: 0.5)
        
        // Retrieve the resulting image
        let result = UIGraphicsGetImageFromCurrentImageContext()
        
        // Clean up the image context
        UIGraphicsEndImageContext()
        
        return result
    }
    public func intersection(box1: [Decimal], box2: [Decimal]) -> Decimal {
        let box1_x1 = box1[0], box1_y1 = box1[1], box1_x2 = box1[2], box1_y2 = box1[3]
        let box2_x1 = box2[0], box2_y1 = box2[1], box2_x2 = box2[2], box2_y2 = box2[3]
        
        let x1 = max(box1_x1, box2_x1)
        let y1 = max(box1_y1, box2_y1)
        let x2 = min(box1_x2, box2_x2)
        let y2 = min(box1_y2, box2_y2)
        
        let intersectionArea = (x2 - x1) * (y2 - y1)
        return intersectionArea
    }
    public func union(box1: [Decimal], box2: [Decimal]) -> Decimal {
        let box1_x1 = box1[0], box1_y1 = box1[1], box1_x2 = box1[2], box1_y2 = box1[3]
        let box2_x1 = box2[0], box2_y1 = box2[1], box2_x2 = box2[2], box2_y2 = box2[3]
        
        let box1_area = (box1_x2 - box1_x1) * (box1_y2 - box1_y1)
        let box2_area = (box2_x2 - box2_x1) * (box2_y2 - box2_y1)
        
        let intersectionArea = intersection(box1: box1, box2: box2)
        
        let unionArea = box1_area + box2_area - intersectionArea
        return unionArea
    }
    public func iou(box1: [Decimal], box2: [Decimal]) -> Decimal {
        let intersectionArea = intersection(box1: box1, box2: box2)
        let unionArea = union(box1: box1, box2: box2)
        
        let iouValue = intersectionArea / unionArea
        return iouValue
    }
    public func nonMaxSuppression(boxes: [[Decimal]], iouThreshold: Decimal) -> [[Decimal]] {
        var sortedBoxes = boxes.sorted { $0[5] > $1[5] }
        
        var result: [[Decimal]] = []

        while sortedBoxes.count > 0 {
            let currentBox = sortedBoxes[0]
            result.append(currentBox)
            
            sortedBoxes = sortedBoxes.filter {
                iou(box1: currentBox, box2: $0) < iouThreshold
            }
        }
        
        return result
    }
    public func nonMaxSuppressionMask(boxes: [ParsedRow], iouThreshold: Decimal) -> [ParsedRow] {
        var sortedBoxes = boxes.sorted { $0.maxProbability > $1.maxProbability }

        var result: [ParsedRow] = []

        while sortedBoxes.count > 0 {
            let currentBox = sortedBoxes[0]
            result.append(currentBox)

            sortedBoxes = sortedBoxes.filter {
                iou(box1: [currentBox.x1, currentBox.y1, currentBox.x2, currentBox.y2],
                    box2: [$0.x1, $0.y1, $0.x2, $0.y2]) < iouThreshold
            }
        }

        return result
    }
    
    public func imageToArray(image: UIImage) -> [[UInt8]]? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let bitsPerComponent = 8
        let bytesPerRow = width
        let totalBytes = height * bytesPerRow

        var pixelValues = [UInt8](repeating: 0, count: totalBytes)
        let colorSpace = CGColorSpaceCreateDeviceGray()

        guard let context = CGContext(data: &pixelValues,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var matrix = [[UInt8]]()
        for x in 0..<height {
            var row = [UInt8]()
            for y in 0..<width {
                let val = pixelValues[(x * width) + y]
                row.append(val)
            }
            matrix.append(row)
        }

        return matrix
    }

    public func convertToUIImage(mask: [[UInt8]]) -> UIImage? {
//                print("This is the mask", mask)
//                print("Mask", mask.count, mask[0].count)
        let width = mask[0].count
        let height = mask.count

        let rawData = mask.flatMap { $0 } // Flatten your 2D array
        let cfbuffer = CFDataCreate(nil, rawData, rawData.count)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        if let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
                                 space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider,
                                 decode: nil, shouldInterpolate: false, intent: .defaultIntent) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
    public func resizeMask(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    public func MLMultiArrayToCGImage(output: MLMultiArray) throws -> CGImage? {
        let height = output.shape[0].intValue
        let width = output.shape[1].intValue
        var bufferPointer = output.dataPointer

        let byteCount = width * height * 4
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            .union(.byteOrder32Big)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue)
            else {
            return nil
        }

        guard let buffer = context.data else { return nil }

        let pixelBuffer = buffer.bindMemory(to: UInt8.self, capacity: byteCount)

        for y in 0..<height {
            for x in 0..<width {
                let pixel = bufferPointer.assumingMemoryBound(to: Float.self)
                let offset = y * width * 4 + x * 4
                pixelBuffer[offset] = UInt8(pixel[0] * 255)     // red error
                pixelBuffer[offset+1] = UInt8(pixel[1] * 255)   // green
                pixelBuffer[offset+2] = UInt8(pixel[2] * 255)   // blue
                pixelBuffer[offset+3] = 0xFF                    // alpha
                bufferPointer = bufferPointer.advanced(by: 1)
            }
        }

        guard let cgImage = context.makeImage() else {
            return nil
        }
        return cgImage
    }
    
    public func drawRectanglesOnImage(image: UIImage, boxes: [[Decimal]]) {
        // Create a graphics context of the original image
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        // Create a graphics context for drawing rectangles
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Set rectangle properties
        let lineWidth: CGFloat = 2.0
        let strokeColor = UIColor.green.cgColor
        
        // Draw rectangles on the image
        for box in boxes {
            if box.count >= 6 {
                let x1 = CGFloat(truncating: box[0] as NSNumber)
                let y1 = CGFloat(truncating: box[1] as NSNumber)
                let x2 = CGFloat(truncating: box[2] as NSNumber)
                let y2 = CGFloat(truncating: box[3] as NSNumber)
                
                let rect = CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
                
                context.setStrokeColor(strokeColor)
                context.setLineWidth(lineWidth)
                context.addRect(rect)
                context.strokePath()
                
            }
        }
        print("Drawing")
//         Get the image with drawn rectangles
        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return
        }
        print("This is the image:", drawnImage)
        // Display the image with drawn rectangles
//        imageView.image = drawnImage
        // End the graphics context
        UIGraphicsEndImageContext()
    }
    
    
    
    
}
