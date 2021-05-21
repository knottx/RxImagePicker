//
//  RxImagePicker.swift
//  RxImagePicker
//
//  Created by Visarut Tippun on 19/5/21.
//

import Foundation
import Photos
import RxSwift
import RxCocoa

public enum RxImagePickerError: Error {
    case camera
    case photoLibrary
}

extension RxImagePickerError: LocalizedError {
    
    public var message: String? {
        switch self {
        case .camera:
            return Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
        case .photoLibrary:
            return Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String
        }
    }
    
}

public class RxImagePicker {
    
    public static let shared:RxImagePicker = RxImagePicker()
    
    private let bag = DisposeBag()
    
    public var cameraTitle:String = "Camera"
    public var photoLibraryTitle:String = "Photo Library"
    public var deleteTitle:String = "Delete"
    public var cancelTitle:String = "Cancel"
    public var openSettingsTitle:String = "Open Settings"
    
    public var errorCameraTitle:String = "Open Settings"
    public var errorCameraMessage:String? = nil
    public var errorPhotoLibraryTitle:String = "Open Settings"
    public var erorrPhotoLibraryMessage:String? = nil
    
    public func setButtonTitle(camera:String? = nil, photoLibrary:String? = nil, delete:String? = nil,
                               cancel:String? = nil, openSettings:String? = nil) {
        self.cameraTitle = camera ?? self.cameraTitle
        self.photoLibraryTitle = photoLibrary ?? self.photoLibraryTitle
        self.deleteTitle = delete ?? self.deleteTitle
        self.cancelTitle = cancel ?? self.cancelTitle
        self.openSettingsTitle = openSettings ?? self.openSettingsTitle
    }
    
    public func setErrorMessage(type:RxImagePickerError, title:String, message:String?) {
        switch type {
        case .camera:
            self.errorCameraTitle = title
            self.errorCameraMessage = message
        case .photoLibrary:
            self.errorPhotoLibraryTitle = title
            self.erorrPhotoLibraryMessage = message
        }
    }
    
    
    //MARK: - Check Available
    
    public func isCameraAvailable() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        default: return false
        }
    }
    
    public func isPhotoLibraryAvailable() -> Bool {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited: return true
        default: return false
        }
    }
    
    
    //MARK: - Camera
    
    public func requestCameraAccess(at viewController: UIViewController, completion: @escaping (Bool) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    completion(true)
                }else{
                    self?.alertOpenSettings(from: viewController, type: .camera) {
                        completion(false)
                    }
                }
            }
        default:
            self.alertOpenSettings(from: viewController, type: .camera) {
                completion(false)
            }
        }
    }
    
    
    //MARK: - Photo Library
    
    public func requestPhotoLibraryAccess(at viewController: UIViewController, completion: @escaping (Bool) -> ()) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                switch status {
                case .authorized, .limited:
                    completion(true)
                default:
                    self?.alertOpenSettings(from: viewController, type: .photoLibrary) {
                        completion(false)
                    }
                }
            }
        default:
            self.alertOpenSettings(from: viewController, type: .photoLibrary) {
                completion(false)
            }
        }
    }
    
    
    //MARK: - Camera and Photo Library
    
    public func requestCameraAndPhotoAccess(at viewController: UIViewController, completion: @escaping (Bool) -> ()) {
        self.requestCamera(from: viewController) {
            self.requestPhotoLibrary(from: viewController) { granted in
                completion(granted)
            }
        }
    }
    
    private func requestCamera(from viewController: UIViewController, completion: @escaping () -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion()
            }
        default:
            self.alertOpenSettings(from: viewController, type: .camera) {
                completion()
            }
        }
    }
    
    private func requestPhotoLibrary(from viewController: UIViewController, completion: @escaping (Bool) -> ()) {
        let isCameraAvailable = self.isCameraAvailable()
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                switch status {
                case .authorized, .limited:
                    completion(true)
                default:
                    if isCameraAvailable {
                        completion(true)
                    }else{
                        self?.alertOpenSettings(from: viewController, type: .photoLibrary) {
                            completion(false)
                        }
                    }
                }
            }
        default:
            self.alertOpenSettings(from: viewController, type: .photoLibrary) {
                completion(isCameraAvailable)
            }
        }
    }
    
    //MARK: - Alert Open Settings
    
    public func alertOpenSettings(from viewController: UIViewController, type:RxImagePickerError?, cancelCompletion: (() -> ())? = nil) {
        DispatchQueue.main.async { [weak self] in
            var title:String? = nil
            var message:String? = nil
            switch type {
            case .camera:
                title = self?.errorCameraTitle
                message = self?.errorCameraMessage ?? type?.message
            case .photoLibrary:
                title = self?.errorPhotoLibraryTitle
                message = self?.erorrPhotoLibraryMessage ?? type?.message
            default:
                title = self?.openSettingsTitle
            }
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancel = UIAlertAction(title: self?.cancelTitle, style: .cancel) { _ in
                cancelCompletion?()
            }
            alertController.addAction(cancel)
            
            let openSettings = UIAlertAction(title: self?.openSettingsTitle, style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            alertController.addAction(openSettings)
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: - Present ImagePicker
    
    public func presentImagePicker(from viewController: UIViewController, title:String?, message:String?,
                                   allowEditing: Bool = false, allowDelete: Bool = false,
                                   completion: @escaping ((error:Error?, didCancel: Bool, image: UIImage?)) -> ()) {
        self.requestCameraAndPhotoAccess(at: viewController) { [weak self] granted in
            if granted, let `self` = self {
                self.alertSelectSource(at: viewController, title: title, message: message, completion: completion)
            }else{
                completion((error: nil, didCancel: true, image: nil))
            }
        }
    }
    
    private func alertSelectSource(at viewController: UIViewController, title:String?, message:String?,
                                   allowEditing: Bool = false, allowDelete: Bool = false,
                                   completion: @escaping ((error:Error?, didCancel: Bool, image: UIImage?)) -> ()) {
        DispatchQueue.main.async { [weak self] in
            let isCameraAvailable = self?.isCameraAvailable() ?? false
            let isPhotoLibraryAvailable = self?.isPhotoLibraryAvailable() ?? false
            guard isCameraAvailable || isPhotoLibraryAvailable else {
                completion((error: nil, didCancel: true, image: nil))
                return
            }
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            
            if isCameraAvailable {
                let camera = UIAlertAction(title: self?.cameraTitle, style: .default) { [weak self] _ in
                    self?.presentImagePickerController(from: viewController, sourceType: .camera, allowEditing: allowEditing) { (error, image) in
                        completion((error: error, didCancel: false, image: image))
                    }
                }
                alertController.addAction(camera)
            }
            
            if isPhotoLibraryAvailable {
                let photoLibrary = UIAlertAction(title: self?.photoLibraryTitle, style: .default) { [weak self] _ in
                    self?.presentImagePickerController(from: viewController, sourceType: .photoLibrary, allowEditing: allowEditing) { (error, image) in
                        completion((error: error, didCancel: false, image: image))
                    }
                }
                alertController.addAction(photoLibrary)
            }
            
            
            if allowDelete {
                let delete = UIAlertAction(title: self?.deleteTitle, style: .destructive) { _ in
                    completion((error: nil, didCancel: false, image: nil))
                }
                alertController.addAction(delete)
            }
            
            let cancel = UIAlertAction(title: self?.cancelTitle, style: .cancel) { _ in
                completion((error: nil, didCancel: true, image: nil))
            }
            alertController.addAction(cancel)
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: - Private
    
    private func presentImagePickerController(from viewController: UIViewController, sourceType: UIImagePickerController.SourceType, allowEditing: Bool, completion: @escaping ((error:Error?, image:UIImage?)) -> Void) {
        UIImagePickerController.rx.createWithParent(viewController, animated: true) { picker in
            picker.sourceType = sourceType
            picker.allowsEditing = allowEditing
        }.flatMap { $0.rx.didFinishPickingMediaWithInfo }.take(1).subscribe { dict in
            let editedImage = dict[.editedImage] as? UIImage
            let originalImage = dict[.originalImage] as? UIImage
            completion((error: nil, image: allowEditing ? editedImage : originalImage))
        } onError: { error in
            print("🏞: [RxImagePicker] => Error: \(error.localizedDescription)")
            completion((error: error, image: nil))
        }.disposed(by: self.bag)
    }
    
}
