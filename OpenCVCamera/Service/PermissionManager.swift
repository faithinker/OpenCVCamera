//
//  PermissionManager.swift
//  OpenCVCamera
//
//  Created by jhKim on 2022/10/21.
//

import AVFoundation
import Photos
import Foundation
import Then

enum PermissionType {
    case camera
    case photos
}

class PermissionManager {
    static let shared = PermissionManager()
    
    
    func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let `self` = self else { return }
            if granted {
                
            } else {
                self.authorizationAlert(sourceType: .camera)
            }
        }
    }
    
    func checkPermissonCompleted(completion: @escaping () -> Void) {
        let savedPhotosAlbumState = PHPhotoLibrary.authorizationStatus()

        switch savedPhotosAlbumState {
        case .notDetermined:
            authorizationPhoto { [weak self] in
            }
        case .restricted:
            break
        case .denied:
            authorizationAlert(sourceType: .photos)
            break
        case .authorized:
            authorizationPhoto { [weak self] in
            }
        default:break
        }
    }
    
    private func authorizationPhoto(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { [weak self] granted in
            DispatchQueue.main.async {
                if granted == .authorized {
                    completion()
                } else {
                    self?.authorizationAlert(sourceType: .photos)
                }
            }
        }
    }
    
    private func authorizationAlert(sourceType: PermissionType) {
        var title: String
        
        switch sourceType {
        case .camera:
            title = "미디어, 파일 권한이 필요합니다.\n 앱 정보 → 권한에서 해당권한을 체크해주세요."
        case .photos:
            title = "사진 권한이 필요합니다.\n 앱 정보 → 권한에서 해당권한을 체크해주세요."
        }
        
        var confirmAction = UIAlertAction(title: "설정하기", style: UIAlertAction.Style.cancel, handler: nil)
        
        let alert = UIAlertController(title: "알림", message: title, preferredStyle: UIAlertController.Style.alert).then {
            $0.addAction(confirmAction)
        }
        
        
        //self.present(alert, animated: false)
    }
}
