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

AppDelegate `didFinishLaunchingWithOptions`
```swift
RxImagePickerDelegateProxy.register { RxImagePickerDelegateProxy(imagePicker: $0) }
```
## 📋 Requirements

* iOS 10.0+
* Xcode 12+
* Swift 5.1+
