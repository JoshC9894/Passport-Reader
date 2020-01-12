//
//  VisionHelper.swift
//  Third Eye
//
//  Created by Joshua Colley on 14/04/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//
//  VNTextObservation is a collection of VNRectangleObservations
//

import Foundation
import UIKit
import Vision

class FrameHelper {
    
    // MARK: - Frame Drawing Methods
    static func showWord(word: VNTextObservation, frame: CGRect, buffer: CVPixelBuffer) -> CALayer {
        guard let boxes = word.characterBoxes else { return CALayer() }
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX { maxX = char.bottomLeft.x }
            if char.bottomRight.x > minX { minX = char.bottomRight.x }
            if char.bottomRight.y < maxY { maxY = char.bottomRight.y }
            if char.topRight.y > minY { minY = char.topRight.y }
        }
        
        let xCord = maxX * frame.size.width
        let yCord = (1 - minY) * frame.size.height
        let width = (minX - maxX) * frame.size.width
        let height = (minY - maxY) * frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.5
        outline.borderColor = UIColor.red.cgColor
        
        return outline
    }
    
    static func showLetter(letter: VNRectangleObservation, frame: CGRect) -> CALayer {
        let xCord = letter.topLeft.x * frame.size.width
        let yCord = (1 - letter.topLeft.y) * frame.size.height
        let width = (letter.topRight.x - letter.bottomLeft.x) * frame.size.width
        let height = (letter.topLeft.y - letter.bottomLeft.y) * frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        return outline
    }
    
    static  func cropImage(image: UIImage , boxs: [VNTextObservation]) -> UIImage? {
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        boxs.forEach { (box) in
            guard let boxes = box.characterBoxes else { return }
            
            for char in boxes {
                if char.bottomLeft.x < maxX { maxX = char.bottomLeft.x }
                if char.bottomRight.x > minX { minX = char.bottomRight.x }
                if char.bottomRight.y < maxY { maxY = char.bottomRight.y }
                if char.topRight.y > minY { minY = char.topRight.y }
            }
        }
        
        let x = maxX * image.size.width - 10
        let y = (1 - minY) * image.size.height - 10
        let width = (minX - maxX) * image.size.width + 20
        let height = (minY - maxY) * image.size.height + 20
        
        let frame = CGRect(x: x, y: y, width: width, height: height)

        
        let context = CIContext()
        if let ciImage = image.ciImage {
            let image = context.createCGImage(ciImage.oriented(.right), from: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size))
            guard let cropped = image?.cropping(to: frame) else { return nil }
            return UIImage(cgImage: cropped)
        }
        return nil
    }
}

