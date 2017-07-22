//
//  PhotoCaptureDelegate.swift
//  avtest
//
//  Created by vrqq on 27/05/2017.
//  Copyright © 2017 vrqq. All rights reserved.
//

import AVFoundation
import Photos
class PhotoCaptureDelegate: NSObject {
    // 1 提供闭包在照相过程中的关键节点执行
    var photoCaptureBegins: (() -> ())? = .none
    var photoCaptured: (() -> ())? = .none
    var photoProj="陕北风电送出工程\n", photoDo="施工部位:", photoPlace="1286#基坑验槽"
    var photoDate="2017年2月14日", photoTime="13:14"
    fileprivate let completionHandler: (PhotoCaptureDelegate, PHAsset?) -> ()
    // 2 用于存储来自输出的数据
    fileprivate var photoData: Data? = .none
    // 3 确保完成 completion 被设置，其他闭包都是可选的
    init(completionHandler: @escaping (PhotoCaptureDelegate, PHAsset?) -> ()) {
        self.completionHandler = completionHandler
    }
    // 4 一旦所有都完成，调用 completion 闭包
    fileprivate func cleanup(asset: PHAsset? = .none) {
        completionHandler(self, asset)
    }
    // Entire process completed
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings,
                 error: Error?) {
        // 1 检查以确保一切都如预期
        guard error == nil, let photo22Data = photoData else {
            print("Error \(String(describing: error)) or no data")
            cleanup()
            return
        }
        //处理照片，转换成UIImage，resize
        //let tmpParaStyle = NSParagraphStyle()
        //tmpParaStyle.setValue(1.5, forKey: "lineHeightMultiple")
        let timetxtAttributes = [NSForegroundColorAttributeName:UIColor.orange,
                              NSFontAttributeName:UIFont.systemFont(ofSize: 28),
                              //NSStrokeWidthAttributeName:NSNumber(value: 2),
                              NSStrokeColorAttributeName:UIColor.brown,
                              NSBackgroundColorAttributeName:UIColor.clear]
        let titleAttributes = [NSForegroundColorAttributeName:UIColor.darkGray,
                              NSFontAttributeName:UIFont.systemFont(ofSize: 24),
                              NSBackgroundColorAttributeName:UIColor.clear]
        let datatimestr : String = photoDate+"　"+photoTime
        
        var myimg = UIImage(data: photo22Data)!
        UIGraphicsBeginImageContext(CGSize(width: 1600, height: 1200))
        let mycontent = UIGraphicsGetCurrentContext()!
        myimg.draw(in: CGRect(x: 0, y: 0, width: 1600, height: 1200))
        //右下角日期
        NSString(string: datatimestr).draw(at: CGPoint(x: 1120, y: 1020), withAttributes: timetxtAttributes)
        //白色背景
        let bkgRect = CGRect(x:0, y:845, width:550, height:350)
        //UIColor.white.setFill()
        //UIRectFill(bkgRect)
        mycontent.setFillColor(gray: 0.9, alpha: 0.95)
        mycontent.addRect(bkgRect)
        mycontent.setLineWidth(10.0)
        //mycontent.setStrokeColor(red: 0.098, green: 0.455, blue: 0.314, alpha: 0.75)
        mycontent.setStrokeColor(gray: 0.3, alpha: 0.85)
        mycontent.drawPath(using: .eoFillStroke)
        //说明文字
        NSString(string: "工程名称:").draw(at: CGPoint(x:30, y:900), withAttributes: titleAttributes)
        NSString(string: self.photoDo).draw(at: CGPoint(x:30, y:1020), withAttributes: titleAttributes)
        NSString(string: "日　　期:").draw(at: CGPoint(x:30, y:1095), withAttributes: titleAttributes)
        NSString(string: self.photoProj).draw(in: CGRect(x:150,y:900, width:380,height:100), withAttributes:titleAttributes)
        NSString(string: self.photoPlace).draw(in: CGRect(x:150,y:1020, width:380,height:60), withAttributes:titleAttributes)
        NSString(string: self.photoDate).draw(in: CGRect(x:150,y:1095, width:380,height:60), withAttributes:titleAttributes)
        
        myimg = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        guard let photoData = UIImageJPEGRepresentation(myimg, 1) else {
            cleanup()
            return
        }
        
        
        // 2 申请访问相册的权限，PHAsset用来表示相册中的相片和影片
        PHPhotoLibrary.requestAuthorization {
            [unowned self]
            (status) in
            // 3 鉴权失败的话，执行 completion 闭包
            guard status == .authorized  else {
            print("Need authorisation to write to the photo library")
            self.cleanup()
            return
            }
            // 4 保存照片到相册，并获取 PHAsset
            var assetIdentifier: String?
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                let placeholder = creationRequest
                    .placeholderForCreatedAsset
                creationRequest.addResource(with: .photo,
                                            data: photoData, options: .none)
                assetIdentifier = placeholder?.localIdentifier
            }, completionHandler: { (success, error) in
                if let error = error {
                    print("Error saving to the photo library: \(error)")
                }
                var asset: PHAsset? = .none
                if let assetIdentifier = assetIdentifier {
                    asset = PHAsset.fetchAssets(
                        withLocalIdentifiers: [assetIdentifier],
                        options: .none).firstObject
                }
                self.cleanup(asset: asset)
            })
        }
    }
}

extension PhotoCaptureDelegate: AVCapturePhotoCaptureDelegate {
    // Process data completed
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        guard let photoSampleBuffer = photoSampleBuffer else {
            print("Error capturing photo \(String(describing: error))")
            return
        }
        photoData = AVCapturePhotoOutput
            .jpegPhotoDataRepresentation(
                forJPEGSampleBuffer: photoSampleBuffer,
                previewPhotoSampleBuffer: previewPhotoSampleBuffer)
    }
}
