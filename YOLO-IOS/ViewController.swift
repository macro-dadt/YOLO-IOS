//
//  ViewController.swift
//  YOLO-IOS
//
//  Created by Do Thanh Dat on 2019/02/28.
//  Copyright © 2019 DT Dat. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    
  
  
    let interfaceOrientationMap: [UIInterfaceOrientation : Int] = [
        .unknown           : 0,
        .portrait           : 0,
        .portraitUpsideDown : 180,
        .landscapeLeft      : 90,
        .landscapeRight     : 270,
        ]
    let videoOrientationMap: [AVCaptureVideoOrientation : Int] = [
        .portrait           : 0,
        .portraitUpsideDown : 180,
        .landscapeLeft      : 90,
        .landscapeRight     : 270,
        ]
    
    var classifier:YoloTinyV1Classifier!
    
    // MARK: - Views
    @IBOutlet var cameraPreviewView : UIView!
    var cgImage: CGImage!
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
 
    
    // MARK: - Camera Properties
    let session = AVCaptureSession()
    var captureDevice : AVCaptureDevice!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        classifier = YoloTinyV1Classifier()
        DispatchQueue.main.async {
            self.classifier.loadModel()
        }
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        cameraPreviewLayer?.frame = (cameraPreviewLayer?.bounds)!
        
        cameraPreviewView.layer.masksToBounds = true
        cameraPreviewView.layer.addSublayer(cameraPreviewLayer!)
       
      
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        startCameraSession()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        authorizeCamera()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        stopCameraSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.classifier.close()
        })
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // addLine(fromPoint:  CGPoint(x: view.bounds.width/2, y: 70), toPoint:  CGPoint(x: view.bounds.width/2, y: view.bounds.height), onView: view)
        resizePreviewLayer()
    }
    func resizePreviewLayer() {
        cameraPreviewLayer?.frame = cameraPreviewView.bounds
    }
    // MARK: - Permissions
    private func authorizeCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] (granted) in
            if(!granted) {
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.showCameraAlert()
                }
            } else {
                guard let strongSelf = self else { return }
                strongSelf.startCaptureSession()
            }
        }
    }
    
    // MARK: - UI helpers
    private func showCameraAlert() {
        let alert = UIAlertController(title: "Camera Access Denied", message: "Please allow the app to access your camera", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: "Authorize", style: .default) { (a: UIAlertAction) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        })
        
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Camera Handling
extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Camera Controls
    func startCaptureSession() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back).devices.first
            else { return }
        
        captureDevice = device
        beginSession()
    }
    
    func stopCameraSession() {
        session.stopRunning()
    }
    func startCameraSession() {
        session.startRunning()
    }
    
    
    
    
    // MARK: - Delegate Implementation
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        DispatchQueue.main.async {
        }
        let videoRotation = self.videoOrientationMap[connection.videoOrientation]!
        let interfaceRotation = self.interfaceOrientationMap[UIApplication.shared.statusBarOrientation]!
        let rotation = videoRotation - interfaceRotation
        let radians = (CGFloat(rotation) * .pi) / 180
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let originalImage = CIImage(cvImageBuffer: imageBuffer!)
        
        let rotationTransform = CGAffineTransform(translationX: originalImage.extent.midX, y: originalImage.extent.midY)
            .rotated(by: radians).translatedBy(x: -originalImage.extent.midX, y: -originalImage.extent.midY)
        
        let image = CIImage(cvImageBuffer: imageBuffer!).transformed(by: rotationTransform)
        let ciCtx = CIContext.init(options: nil)
        self.cgImage = ciCtx.createCGImage(image, from: image.extent)!
        
        
        
        
        let uiImage = UIImage(cgImage: ciCtx.createCGImage(image, from: image.extent)!)

        classifier.classifyImage(uiImage)
        let boxes = classifier.result()
        DispatchQueue.main.async { [weak self] in
            
            guard let strongSelf = self else { return }
            if let count = strongSelf.cameraPreviewLayer?.sublayers?.count, count > 0{
                strongSelf.cameraPreviewLayer?.sublayers?.removeLast(count - 1)
            }
            for box in boxes{
                
                
                    box.addToLayer(strongSelf.cameraPreviewLayer!)
                    let width = strongSelf.cameraPreviewLayer?.frame.width
                    let height = width! *  (uiImage.size.height/uiImage.size.width)
                    let scaleX =  width! / CGFloat(strongSelf.cgImage.width)
                    let scaleY = height / CGFloat(strongSelf.cgImage.height)
                    
                    let margin = ((strongSelf.cameraPreviewLayer?.frame.height)! - height)/2
                    //let top = (strongSelf.view.bounds.height - height) / 2
                    box.x = Float(CGFloat(box.x) * scaleX)
                    box.y = Float(CGFloat(box.y) * scaleY) + Float(margin)
                    //box.y = Float(CGFloat(box.y) * scaleY)
                    box.width = Float(CGFloat(box.width) * scaleX)
                    box.height = Float(CGFloat(box.height) * scaleY)
                    let rect = CGRect(x: CGFloat(box.x), y: CGFloat(box.y), width: CGFloat(box.width), height: CGFloat(box.height))
                    box.show(frame: rect, label: box.label, color: UIColor.red)
                
                
            }
            
            
        }
    }
    // MARK: - Session Handling
    private func beginSession() {
        var deviceInput: AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            print("Unable to create camera device input: \(error.localizedDescription)")
            return
        }
        if(session.canAddInput(deviceInput!)) {
            session.addInput(deviceInput!)
        }
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if(session.canAddOutput(videoDataOutput)) {
            session.addOutput(videoDataOutput)
        }
        session.startRunning()
    }
}




