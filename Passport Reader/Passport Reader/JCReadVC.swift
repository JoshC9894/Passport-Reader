//
//  JCReadVC.swift
//  Passport Reader
//
//  Created by Joshua Colley on 14/05/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import UIKit
import Vision
import TesseractOCR
import Lottie

class JCReadVC: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var mrzImageView: UIImageView!
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var givenNameLabel: UILabel!
    @IBOutlet weak var surnameLabel: UILabel!
    @IBOutlet weak var passportNumberLabel: UILabel!
    @IBOutlet weak var nationalityLabel: UILabel!
    @IBOutlet weak var dobLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var expiryDateLabel: UILabel!
    @IBOutlet weak var personalLabel: UILabel!
    
    var pixelBuffer: CVPixelBuffer?
    var image: UIImage!
    var requests = [VNRequest]()

    var animationView: UIView!
    var animation: LOTAnimationView!
    
    // MARK: - View Life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAnimation()
        self.animation.play { (_) in
            self.detectText()
        }
        
        if let buffer = pixelBuffer {
            self.image = UIImage(ciImage: CIImage(cvImageBuffer: buffer),
                                 scale: 1.0, orientation: .right)
        }
    }
    
    // MARK: - Helper Methods
    fileprivate func setupAnimation() {
        self.animationView = UIView(frame: self.view.frame)
        self.animationView.backgroundColor = .white
        self.view.addSubview(self.animationView)
        
        self.animation = LOTAnimationView(name: "pulse_loader")
//        self.animation.play()
        self.animation.translatesAutoresizingMaskIntoConstraints = false
        self.animationView.addSubview(self.animation)
        
        self.animation.widthAnchor.constraint(equalToConstant: 150).isActive = true
        self.animation.heightAnchor.constraint(equalToConstant: 150).isActive = true
        self.animation.centerYAnchor.constraint(equalTo: self.animationView.centerYAnchor, constant: -50).isActive = true
        self.animation.centerXAnchor.constraint(equalTo: self.animationView.centerXAnchor).isActive = true
        
    }
}


// MARK: - Text Detection
extension JCReadVC {
    fileprivate func detectText() {
        self.animation.loopAnimation = true
        self.animation.play()
        
        let textRequests = VNDetectTextRectanglesRequest(completionHandler: textRecognitionHandler)
        textRequests.reportCharacterBoxes = true
        self.requests = [textRequests]
        
        guard let pixelBuffer = self.pixelBuffer else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: .right,
                                                        options: [:])
        try? imageRequestHandler.perform(self.requests)
    }
    
    fileprivate func textRecognitionHandler(request: VNRequest, error: Error?) {
        if error == nil {
            guard let observations = request.results else { return }
            let result = observations.map({ $0 as? VNTextObservation })
            
            DispatchQueue.main.async {
                var boxes: [VNTextObservation] = []
                result.forEach({ (word) in
                    if let word = word {
                        if word.characterBoxes?.count == 44 {
                            boxes.append(word)
                        }
                    }
                })
                
                guard let croppedImage = FrameHelper.cropImage(image: self.image, boxs: boxes) else { return }
                self.mrzImageView.image = croppedImage.g8_blackAndWhite()
                let detectedText = self.ocr(image: croppedImage)
                let parsed = MRZ.init(scan: detectedText)
                
                self.typeLabel.text = parsed.documentType
                self.countryLabel.text = parsed.countryCode
                self.givenNameLabel.text = parsed.firstName
                self.surnameLabel.text = parsed.lastName
                self.passportNumberLabel.text = parsed.passportNumber
                self.nationalityLabel.text = parsed.nationality
                self.dobLabel.text = parsed.dateOfBirth?.toString() ?? ""
                self.genderLabel.text = parsed.sex
                self.expiryDateLabel.text = parsed.expirationDate?.toString() ?? ""
                self.personalLabel.text = parsed.personalNumber
                
                self.animationView.isHidden = true
                self.animation.stop()
            }
        }
    }
    
    fileprivate func ocr(image: UIImage) -> String {
        guard let tesseract = G8Tesseract(language: "eng") else { return "" }
        tesseract.engineMode = .tesseractCubeCombined
        tesseract.pageSegmentationMode = .auto
        tesseract.charWhitelist = "01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ<"
        tesseract.image = image.g8_blackAndWhite()
        tesseract.recognize()
        return tesseract.recognizedText
    }
}


// MARK: - Date String Methods
extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        return formatter.string(from: self)
    }
}
