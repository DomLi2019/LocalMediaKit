Pod::Spec.new do |s|
  s.name             = 'LocalMediaKit'
  s.version          = '1.0.0'
  s.summary          = 'A comprehensive local media management framework for iOS.'
  s.description      = <<-DESC
    LocalMediaKit provides a complete solution for managing local media resources on iOS,
    including images, videos, and Live Photos. It offers features such as:
    - Unified save/load API for all media types
    - Two-level caching (memory + disk) with LRU eviction
    - Flexible path management with customization support
    - SQLite-based metadata storage and querying
    - Live Photo assembly and disassembly
    - Thread-safe operations with optimized performance
  DESC

  s.homepage         = 'https://github.com/DomLi2019/LocalMediaKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Author' => 'productcoding@163.com' }
  s.source           = { :git => 'https://github.com/DomLi2019/LocalMediaKit.git', :tag => '1.0.0' }

  s.ios.deployment_target = '15.0'
  s.swift_version = '5.9'

  s.source_files = 'Sources/LocalMediaKit/**/*.swift'
  
  s.frameworks = 'Foundation', 'UIKit', 'Photos', 'PhotosUI', 'AVFoundation', 'ImageIO', 'CoreServices'
end

