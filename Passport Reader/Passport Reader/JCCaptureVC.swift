//
//  JCCaptureVC.swift
//  Passport Reader
//
//  Created by Joshua Colley on 09/05/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import UIKit
import AVKit
import Vision

class JCCaptureVC: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    
    var videoInput: AVCaptureDeviceInput!
    var videoOutput: AVCaptureVideoDataOutput!
    
    var cameraOutput = AVCapturePhotoOutput()
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    
    var cvBuffer: CVPixelBuffer?
    
    
    // MARK: - View Life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        captureButton.layer.cornerRadius = captureButton.frame.height / 2
        startLiveVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.session.startRunning()
        detectText()
    }
    
    override func viewDidLayoutSubviews() {
        videoView.layer.sublayers?[0].frame = videoView.bounds
    }
    
    
    // MARK: - Actions
    @IBAction func captureButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "readSegue", sender: self)
    }
}


// MARK: - Video Layer
extension JCCaptureVC {
    fileprivate func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.high
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        // Input
        if self.videoInput == nil {
            self.videoInput = try? AVCaptureDeviceInput(device: device)
            self.session.addInput(self.videoInput)
        }
        
        // Output
        if self.videoOutput == nil {
            self.videoOutput = AVCaptureVideoDataOutput()
            let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
            
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            self.session.addOutput(self.videoOutput)
        }
        
        // Start Capture Session
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(layer)
    }
}


// MARK: - Video Output Delegate
extension JCCaptureVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cvBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.cvBuffer = cvBuffer
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: cvBuffer,
                                                        orientation: .right,
                                                        options: requestOptions)
        try? imageRequestHandler.perform(self.requests)
    }
}


// MARK: - Prepare for Segue
extension JCCaptureVC {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? JCReadVC {
            destination.pixelBuffer = self.cvBuffer
        }
    }
}


// MARK: - Text Detection
extension JCCaptureVC {
    fileprivate func detectText() {
        let textRequests = VNDetectTextRectanglesRequest { (request, error) in
            if error == nil {
                self.textRecognitionHandler(request: request)
            }
        }
        textRequests.reportCharacterBoxes = true
        self.requests = [textRequests]
    }
    
    fileprivate func textRecognitionHandler(request: VNRequest) {
        guard let observations = request.results else { return }
        let result = observations.map({ $0 as? VNTextObservation })
        
        DispatchQueue.main.async {
            self.videoView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let word = region else { continue }
                guard let buffer = self.cvBuffer else { return }
                
                if word.characterBoxes?.count == 44 {
                    let wordBox = FrameHelper.showWord(word: word, frame: self.videoView.frame, buffer: buffer)
                    self.videoView.layer.addSublayer(wordBox)
                }
            }
        }
    }
}
