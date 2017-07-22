//
//  CamPreview.swift
//  avtest
//
//  Created by vrqq on 11/04/2017.
//  Copyright © 2017 vrqq. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraPreviewUIView : UIView {
    override static var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    var session : AVCaptureSession? {
        get {
            return cameraPreviewLayer.session
        }
        set {
            cameraPreviewLayer.session = newValue
        }
    }
}
