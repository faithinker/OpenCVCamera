//
//  ViewController.swift
//  OpenCVCamera
//
//  Created by jhKim on 2022/10/20.
//

import UIKit
import AVFoundation
import Photos
//import AVFAudio
import SnapKit
import Then
import RxSwift
import RxCocoa
import NSObject_Rx


class ViewController: UIViewController {

    private lazy var previewView = UIImageView().then {
        $0.layer.insertSublayer(previewLayer, at: 0)
    }
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.session).then {
        $0.videoGravity = .resizeAspectFill
        $0.connection?.videoOrientation = .portrait
    }
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private lazy var session = AVCaptureSession().then {
        $0.sessionPreset = .photo //AVCaptureSession.Preset.iFrame1280x720
    }
    
    private lazy var output = AVCapturePhotoOutput()
    
    // MARK: - View
    
    private lazy var button = UIButton().then {
        $0.layer.cornerRadius = 40
        $0.layer.borderColor = UIColor.systemBlue.cgColor
        $0.layer.borderWidth = 5
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        setupPermission()
        setupCamera()
        setupPreview()
        bindData()
        //startCaptureSession()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func bindData() {
        var photoSettings = AVCapturePhotoSettings()
        
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.output.capturePhoto(with: AVCapturePhotoSettings(),
                                    delegate: self)
                
                
//                self.output.availablePhotoCodecTypes.contains(.hevc) { in
//                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
//                }
            }).disposed(by: rx.disposeBag)
    }
    
    private func setupLayout() {
        view.addSubviews([previewView, button])
        previewView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-130)
        }
        button.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-30)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(80)
        }
    }
    
    private func setupPermission() {
        PermissionManager.shared.checkPermissonCompleted {
            print("@@@@@")
        }
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input), session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
            }
        } catch {
            print("input Error : \(error.localizedDescription)")
        }
        self.session.startRunning()
    }
    
    private func setupPreview() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.previewLayer.frame = self.previewView.bounds
        }
    }
    
    private func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
}


extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
        
        DispatchQueue.main.async {
            self.previewView.layer.opacity = 0.7
            UIView.animate(withDuration: 0.25) {
                self.previewView.layer.opacity = 1
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        
        //session.stopRunning()
        
        let image = UIImage(data: data)!
        
//        let imageView = UIImageView(image: image).then {
//            $0.contentMode = .scaleAspectFill
//            $0.frame = previewView.bounds
//        }
//
//        view.addSubview(imageView)
        
        
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}
