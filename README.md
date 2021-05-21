# RxImagePicker
RxImagePicker

## 📲 Installation

`RxImagePicker` is available on [CocoaPods](https://cocoapods.org/pods/RxImagePicker):
```ruby
pod 'RxImagePicker'
```
## 📝 How
### Code Implementation
```swift
import RxImagePicker
````
Configure a **RxImagePicker** Delegate Proxy, typically in your app's 
`application:didFinishLaunchingWithOptions: method:`
```swift
RxImagePickerDelegateProxy.register { RxImagePickerDelegateProxy(imagePicker: $0) }
```

Request access only Camera
```swift
RxImagePicker.shared.requestCameraAccess(at: self) { [weak self] granted in
    guard granted, let `self` = self else { return }
    // handle after Camera authorized.
}
```

Request access only Photo Library
```swift
RxImagePicker.shared.requestPhotoLibraryAccess(at: self) { [weak self] granted in
    guard granted, let `self` = self else { return }
    // handle after Photo Library authorized.
}
```

Request access Camera and Photo Library
```swift
RxImagePicker.shared.requestCameraAndPhotoAccess(at: self) { [weak self] granted in
    guard granted, let `self` = self else { return }
    // handle after Camera and Photo Library authorized.
}
```

Present ImagePicker (Request access Camera and Photo Library Automatically):
```swift
RxImagePicker.shared.presentImagePicker(from: self, title: <String?>, message: <String?>, allowEditing: <Bool>, allowDelete: <Bool>) { [weak self] (error, didCancel, image) in
    guard !didCancel, let `self` = self, error == nil else {
        print(error?.localizedDescription)
        // handle error
        return
    }
    // handle after get image.
    // if select "delete" image is nil.
}
```


## 📋 Requirements

* iOS 10.0+
* Xcode 12+
* Swift 5.1+
