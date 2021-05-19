//
//  UIImagePickerController+RxCreate.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 1/10/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

func dismissViewController(_ viewController: UIViewController, animated: Bool) {
    if viewController.isBeingDismissed || viewController.isBeingPresented {
        DispatchQueue.main.async {
            dismissViewController(viewController, animated: animated)
        }

        return
    }

    if viewController.presentingViewController != nil {
        viewController.dismiss(animated: animated, completion: nil)
    }
}

public extension Reactive where Base: UIImagePickerController {
    
    static func createWithParent(_ parent: UIViewController?, animated: Bool = true, configureImagePicker: @escaping (UIImagePickerController) throws -> Void = { x in }) -> Observable<UIImagePickerController> {
        return Observable.create { [weak parent] observable in
            let imagePicker = UIImagePickerController()
            let dismissDisposable = imagePicker.rx.didCancel.bind { [weak imagePicker] _ in
                guard let `imagePicker` = imagePicker else { return }
                dismissViewController(imagePicker, animated: animated)
            }
            
            do {
                try configureImagePicker(imagePicker)
            } catch {
                observable.onError(error)
                return Disposables.create()
            }

            guard let parent = parent else {
                observable.onCompleted()
                return Disposables.create()
            }

            parent.present(imagePicker, animated: animated, completion: nil)
            observable.onNext(imagePicker)
            return Disposables.create(dismissDisposable, Disposables.create {
                dismissViewController(imagePicker, animated: animated)
            })
        }
    }
    
}
