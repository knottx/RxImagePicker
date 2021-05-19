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
    
    public var title: String {
        switch self {
        case .camera: return "error_camera_access_title"
        case .photoLibrary: return "error_photo_library_access_title"
        }
    }
    
    public var message: String {
        switch self {
        case .camera: return "error_camera_access_message"
        case .photoLibrary: return "error_photo_library_access_message"
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
    
    public func setButtonTitle(camera:String? = nil, photoLibrary:String? = nil, delete:String? = nil,
                               cancel:String? = nil, openSettings:String? = nil) {
        self.cameraTitle = camera ?? self.cameraTitle
        self.photoLibraryTitle = photoLibrary ?? self.photoLibraryTitle
        self.deleteTitle = delete ?? self.deleteTitle
        self.cancelTitle = cancel ?? self.cancelTitle
        self.openSettingsTitle = openSettings ?? self.openSettingsTitle
    }
    
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
    
    public func requestCameraAndPhotoAuthorization(from viewController: UIViewController) -> Completable {
        return self.requestCameraAuthorization(from: viewController, canSkip: true)
            .concat(self.requestPhotoLibraryAuthorization(from: viewController, canSkip: true))
    }
    
    public func requestCameraAuthorization(from viewController: UIViewController, canSkip:Bool = false) -> Completable {
        return Completable.create { [weak self] completable in
            let error = RxImagePickerError.camera
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                completable(.completed)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    completable(canSkip ? .completed : (granted ? .completed: .error(error)))
                }
            default:
                if canSkip {
                    self?.alertOpenSettings(from: viewController, title: error.title, message: error.message) {
                        completable(.completed)
                    }
                }else{
                    completable(.error(error))
                }
            }
            return Disposables.create()
        }
    }
    
    public func requestPhotoLibraryAuthorization(from viewController: UIViewController, canSkip:Bool = false) -> Completable {
        return Completable.create { [weak self] completable in
            let isCameraAvailable = self?.isCameraAvailable() ?? false
            let error = RxImagePickerError.photoLibrary
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized, .limited:
                completable(.completed)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    switch status {
                    case .authorized, .limited:
                        completable(.completed)
                    default:
                        completable((canSkip && isCameraAvailable) ? .completed : .error(error))
                    }
                }
            default:
                if canSkip, isCameraAvailable {
                    self?.alertOpenSettings(from: viewController, title: error.title, message: error.message) {
                        completable(.completed)
                    }
                }else{
                    completable(.error(error))
                }
            }
            return Disposables.create()
        }
    }
    
    public func alertOpenSettings(from viewController: UIViewController, title: String?, message: String?, cancelCompletion: (() -> ())? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancel = UIAlertAction(title: self.cancelTitle, style: .cancel) { _ in
                cancelCompletion?()
            }
            alertController.addAction(cancel)
            
            let openSettings = UIAlertAction(title: self.openSettingsTitle, style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            alertController.addAction(openSettings)
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    public func presentImagePicker(from viewController: UIViewController, allowEditing: Bool = false, allowDelete: Bool = false,
                            completion: @escaping ((didCancel: Bool, image: UIImage?)) -> Void) {
        DispatchQueue.main.async { [weak self] in
            let isCameraAvailable = self?.isCameraAvailable() ?? false
            let isPhotoLibraryAvailable = self?.isPhotoLibraryAvailable() ?? false
            guard isCameraAvailable || isPhotoLibraryAvailable else {
                completion((didCancel: true, image: nil))
                return
            }
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            if isCameraAvailable {
                let camera = UIAlertAction(title: self?.cameraTitle, style: .default) { [weak self] _ in
                    self?.presentImagePickerController(from: viewController, sourceType: .camera, allowEditing: allowEditing) { (image) in
                        completion((didCancel: false, image: image))
                    }
                }
                alertController.addAction(camera)
            }
            
            if isPhotoLibraryAvailable {
                let photoLibrary = UIAlertAction(title: self?.photoLibraryTitle, style: .default) { [weak self] _ in
                    self?.presentImagePickerController(from: viewController, sourceType: .photoLibrary, allowEditing: allowEditing) { (image) in
                        completion((didCancel: false, image: image))
                    }
                }
                alertController.addAction(photoLibrary)
            }
            
            
            if allowDelete {
                let delete = UIAlertAction(title: self?.deleteTitle, style: .destructive) { _ in
                    completion((didCancel: false, image: nil))
                }
                alertController.addAction(delete)
            }
            
            let cancel = UIAlertAction(title: self?.cancelTitle, style: .cancel) { _ in
                completion((didCancel: true, image: nil))
            }
            alertController.addAction(cancel)
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func presentImagePickerController(from viewController: UIViewController, sourceType: UIImagePickerController.SourceType, allowEditing: Bool, completion: @escaping (UIImage?) -> Void) {
        UIImagePickerController.rx.createWithParent(viewController, animated: true) { picker in
            picker.sourceType = sourceType
            picker.allowsEditing = allowEditing
        }.flatMap { $0.rx.didFinishPickingMediaWithInfo }.take(1).subscribe { dict in
            let editedImage = dict[.editedImage] as? UIImage
            let originalImage = dict[.originalImage] as? UIImage
            completion(allowEditing ? editedImage : originalImage)
        } onError: { error in
            print("🏞: [RxImagePicker] => Error: \(error.localizedDescription)")
            completion(nil)
        }.disposed(by: self.bag)
    }
    
}
