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

Request access only Camera
```swift
RxImagePicker.shared.requestCameraAccess(at: self) { granted in
    guard granted else { return }
    // handle after Camera authorized.
}
```

Request access only Photo Library
```swift
RxImagePicker.shared.requestPhotoLibraryAccess(at: self) { granted in
    guard granted else { return }
    // handle after Photo Library authorized.
}
```

Request access Camera and Photo Library
```swift
RxImagePicker.shared.requestCameraAndPhotoAccess(at: self) { [weak self] granted in
    guard granted else { return }
    // handle after Camera and Photo Library authorized.
}
```

Present ImagePicker (Request access Camera and Photo Library Automatically):
```swift
RxImagePicker.shared.presentImagePicker(at: self, title: <String?>, message: <String?>, allowEditing: <Bool>) { image in
    print("Has Image: \(image != nil)")
    // handle after get image.
} onCancel: {
    // handle did Cancel.
} onDelete: {
    // handle did Delete 
    // if remove onDelete will not show "Delete" button.
}
```

## 📋 Requirements

* iOS 10.0+
* Xcode 12+
* Swift 5.1+
