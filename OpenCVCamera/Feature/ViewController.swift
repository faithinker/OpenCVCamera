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
        $0.layer.borderWidth = 7
    }
    
    private lazy var filterButton = UIButton().then {
        $0.setTitle("filter", for: .normal)
        $0.setBackgroundColor(.blue, for: .normal)
        $0.setBackgroundColor(.red, for: .highlighted)
    }
    
    private lazy var undoButton = UIButton().then {
        let configButton = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold, scale: .large)
        
        $0.setImage(UIImage(systemName: "chevron.down", withConfiguration: configButton), for: .normal)
        $0.isHidden = true
        $0.tintColor = .black
    }
    
    private lazy var filterOption = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout().then {
        $0.itemSize = CGSize(width: 45, height: 63)
        $0.minimumInteritemSpacing = 10
    }).then {
        $0.isHidden = true
        $0.backgroundColor = .clear
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.identifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        setupPermission()
        setupCamera()
        setupPreview()
        bindData()
        //startCaptureSession()
        setupDI()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func bindData() {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.output.capturePhoto(with: AVCapturePhotoSettings(),
                                    delegate: self)
            }).disposed(by: rx.disposeBag)
        
        filterButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                UIView.animate(withDuration: 0.5) { [weak self] in
                    guard let `self` = self else { return }
                    self.button.layer.borderWidth = 10
                    self.button.transform = CGAffineTransform(scaleX: 0.5, y: 0.5).translatedBy(x: 0, y: 80)
                    self.filterButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5).translatedBy(x: 0, y: 80)
                    self.undoButton.smooth(hidden: false)
                    self.filterOption.smooth(hidden: false)
                    self.filterButton.smooth(hidden: true)
                }
            }).disposed(by: rx.disposeBag)
        
        undoButton.rx.tap
            .subscribe(onNext: {
                UIView.animate(withDuration: 0.5) { [weak self] in
                    guard let self else { return }
                    self.button.transform = .identity
                    self.filterButton.transform = .identity
                    self.filterOption.smooth(hidden: true)
                    self.undoButton.smooth(hidden: true)
                    self.filterButton.smooth(hidden: false)
                }
            }).disposed(by: rx.disposeBag)
        
        filterOption.rx.itemSelected
            .subscribe(onNext: { index in
                print("itemSelected :\(index.row)")
            }).disposed(by: rx.disposeBag)
    }
    
    private func setupLayout() {
        view.addSubviews([previewView, button, filterButton, undoButton, filterOption])
        previewView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-130)
        }
        button.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-30)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(80)
        }
        filterButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-50)
            $0.leading.equalTo(button.snp.trailing).offset(25)
            $0.width.equalTo(75)
            $0.height.equalTo(35)
        }
        undoButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-10)
            $0.leading.equalToSuperview().offset(15)
            $0.width.equalTo(50)
            $0.height.equalTo(35)
        }
        filterOption.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-60)
            $0.leading.trailing.equalToSuperview().inset(15)
            $0.height.equalTo(63)
        }
    }
    
    private func setupPermission() {
        PermissionManager.shared.checkPermissonCompleted {
            print("@@@@@")
        }
    }
    
    private func setupDI() {
        Observable.just(["원본", "회색", "밝은색"])
            .bind(to: filterOption.rx.items(cellIdentifier: FilterCell.identifier, cellType: FilterCell.self)) { row, element, cell in
                cell.configure(data: element)
            }.disposed(by: rx.disposeBag)
        
        
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
