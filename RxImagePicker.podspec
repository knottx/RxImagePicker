Pod::Spec.new do |spec|

  spec.name         = "RxImagePicker"
  spec.version      = "0.0.1"
  spec.summary      = "RxImagePicker"

  spec.homepage     = "https://github.com/knottx/RxImagePicker"
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author       = { "Visarut Tippun" => "knotto.vt@gmail.com" }
  spec.source       = { :git => "https://github.com/knottx/RxImagePicker.git", :tag => "#{spec.version}" }
  
  spec.swift_version   = "5.1"
  spec.ios.deployment_target = "10.0"
  spec.source_files  = "RxImagePicker/**/*.swift"
  spec.requires_arc  = true

  spec.dependency 'RxSwift', '~> 6.0'
  spec.dependency 'RxCocoa', '~> 6.0'

end
