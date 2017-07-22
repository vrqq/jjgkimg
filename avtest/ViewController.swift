//
//  ViewController.swift
//  avtest
//
//  Created by vrqq on 11/04/2017.
//  Copyright © 2017 vrqq. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


class ViewController: UIViewController {
    fileprivate let session = AVCaptureSession()
    fileprivate let sessionQueue = DispatchQueue(label: "org.vrqq.avtest.session-queue")
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate var photoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()
    fileprivate let userSetting = UserDefaults.standard
    
    @IBOutlet weak var CamUIView: CameraPreviewUIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        CamUIView.session = session
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { success in
            if !success {
                print ("[Permission Denied]Camera.\n")
                return
            }
        }
        PHPhotoLibrary.requestAuthorization() { success in
            if success != PHAuthorizationStatus.authorized {
                print ("[Permission Denied]PHPhotoLibrary=\(success)\n")
                return
            }
        }
        self.sessionQueue.resume()
        sessionQueue.async {
            [weak self] in
            self!.preCapture()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //setDefault.
        if userSetting.string(forKey: "photoProject") == nil {
            userSetting.set("xxxx线路工程", forKey: "photoProject")
        }
        if userSetting.string(forKey: "photoPlace") == nil {
            userSetting.set("0001#", forKey: "photoPlace")
        }
        if userSetting.value(forKey: "photoDate") == nil {
            userSetting.set(Date(), forKey: "photoDate")
        }
        if userSetting.value(forKey: "photoTime") == nil {
            userSetting.set(Date(), forKey: "photoTime")
        }
        userSetting.synchronize()
        //read.
        self.photoProjectRef.text = userSetting.string(forKey: "photoProject")
        self.photoDo = userSetting.bool(forKey: "photoDo")
        self.photoPlaceRef.text = userSetting.string(forKey: "photoPlace")
        self.photoDateKey = userSetting.value(forKey: "photoDate") as! Date
        self.photoTimeKey = userSetting.value(forKey: "photoTime") as! Date
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var shouldAutorotate: Bool {
        return true
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscapeRight
    }
    
    func preCapture () {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        do {
            let videoDevice = AVCaptureDevice.defaultDevice(
                withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                //self.videoDeviceInput = videoDeviceInput
                DispatchQueue.main.async {
                    self.CamUIView.cameraPreviewLayer
                        .connection.videoOrientation = .landscapeRight
                }
            } else {
                print("Couldn't add device to the session")
                return
            }
        } catch {
            print("error\(error)")
            return
        }
        if session.canAddOutput(self.photoOutput) {
            self.photoOutput.isHighResolutionCaptureEnabled = true
            session.addOutput(photoOutput);
        } else {
            print("unable to add output.")
            return
        }
        session.commitConfiguration()
    }
    func tapToChangeFucus (tap: UITapGestureRecognizer) {
        
    }
    
    @IBAction func handleTakePhotoBtb(_ sender: UIButton) {
        self.sessionQueue.async {
            if let connection=self.photoOutput.connection(withMediaType: AVMediaTypeVideo) {
                connection.videoOrientation = .landscapeRight
            }
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .off
            photoSettings.isHighResolutionPhotoEnabled = true
        
            // 1 每个 AVCapturePhotoSettings 实例创建时都会被自动分配一个 ID 标识
            let uniqueID = photoSettings.uniqueID
            // 初始化一个 PhotoCaptureDelegate 对象，传入一个 completion 闭包
            let photoCaptureDelegate = PhotoCaptureDelegate() {
                [unowned self] (photoCaptureDelegate, asset) in
                self.sessionQueue.async { [unowned self] in
                    self.photoCaptureDelegates[uniqueID] = .none
                    let myalert = UIAlertController(title:"OK", message:nil, preferredStyle:.alert)
                    self.present(myalert, animated: false, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3) {
                        myalert.dismiss(animated: true, completion: nil)
                    }
                }
            }
            //写信息
            photoCaptureDelegate.photoDo = self.btnDoRef.currentTitle!
            if self.photoPlaceRef.text != nil {
                photoCaptureDelegate.photoPlace = self.photoPlaceRef.text!
            }
            photoCaptureDelegate.photoDate = self.photoDateRef.text!
            photoCaptureDelegate.photoTime = self.photoTimeRef.text!
            if self.photoProjectRef.text != nil {
                photoCaptureDelegate.photoProj = self.photoProjectRef.text!
            }
            
            // 2 将 delegate 存入字典中
            self.photoCaptureDelegates[uniqueID] = photoCaptureDelegate
            // 3 开始拍照，并把 setting 和 delegate 传进去            
            self.photoOutput.capturePhoto(
                with: photoSettings, delegate: photoCaptureDelegate)
 
        }
        
    }
    
    private var photoDo: Bool = false {
        didSet{
            if photoDo {
                btnDoRef.setTitle("活动内容:", for: .normal)
            }else {
                btnDoRef.setTitle("施工部位:", for: .normal)
            }
        }
    }
    @IBOutlet weak var btnDoRef: UIButton!
    @IBAction func btnDoToggle(_ sender: Any) {
        photoDo = !photoDo
        userSetting.set(photoDo, forKey: "photoDo")
        userSetting.synchronize()
    }

    //工程名称
    @IBOutlet weak var photoProjectRef: UILabel!
    @IBAction func btnProjectChange(_ sender: Any) {
        let alert = PlaceAlertController(title: "Place", message: nil, preferredStyle: .alert)
        if self.photoProjectRef.text != nil {
            alert.projtext.text = self.photoProjectRef.text!
        }
        let okAction = UIAlertAction(title: "OK", style: .default) {
            (action: UIAlertAction!) -> Void in
            self.photoProjectRef.text = alert.projtext.text
            self.userSetting.set(self.photoProjectRef.text, forKey: "photoProject")
            self.userSetting.synchronize()
        }
        alert.addAction(okAction)
        self.present(alert, animated: false, completion: nil)
    }
    
    //地点
    @IBOutlet weak var photoPlaceRef: UILabel!
    @IBAction func photoPlaceChangeBtn(_ sender: Any) {
        let alert = UIAlertController(title:"Place/Activity", message:nil, preferredStyle:.alert)
        alert.addTextField {
            (textField: UITextField!) -> Void in
            textField.text = self.photoPlaceRef.text
        }
        let okAction = UIAlertAction(title: "OK", style: .default) {
            (action: UIAlertAction!) -> Void in
            let acc = (alert.textFields?.first)! as UITextField
            self.photoPlaceRef.text = acc.text
            self.userSetting.set(acc.text, forKey: "photoPlace")
            self.userSetting.synchronize()
        }
        alert.addAction(okAction)
        self.present(alert, animated: false, completion: nil)
    }
    fileprivate var photoDateKey: Date = Date(){
        didSet{
            let dformatter = DateFormatter()
            dformatter.dateFormat="yyyy年MM月dd日"
            self.photoDateRef.text = dformatter.string(from: photoDateKey)
            self.photoDateChooser.date = photoDateKey
        }
    }
    fileprivate var photoTimeKey: Date = Date() {
        didSet{
            let dformatter = DateFormatter()
            dformatter.dateFormat="HH:mm"
            self.photoTimeRef.text = dformatter.string(from: photoTimeKey)
            self.photoTimeChooser.date = photoTimeKey
        }
    }
    @IBOutlet weak var photoDateRef: UILabel!
    @IBOutlet weak var photoTimeRef: UILabel!
    
    @IBOutlet weak var datePickerView: UIStackView!
    @IBAction func photoDateBtn(_ sender: Any) {
        let color = UIColor.init(red: 214.0/255, green: 213.0/255, blue: 218.0/255, alpha: 1)
        self.photoDateChooser.backgroundColor = color
        self.photoDateChooser.alpha = 0.95
        self.photoTimeChooser.backgroundColor = color
        self.photoTimeChooser.alpha = 0.95
        self.datePickerView.isHidden = false
        
    }
    @IBOutlet weak var photoDateChooser: UIDatePicker!
    @IBOutlet weak var photoTimeChooser: UIDatePicker!
    @IBAction func datePickerCloseBtn(_ sender: Any) {
        self.photoDateKey = self.photoDateChooser.date
        self.photoTimeKey = self.photoTimeChooser.date
        self.datePickerView.isHidden = true
        userSetting.set(photoTimeKey, forKey: "photoDate")
        userSetting.set(photoTimeKey, forKey: "photoTime")
        userSetting.synchronize()
    }
}

