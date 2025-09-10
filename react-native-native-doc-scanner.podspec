require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-native-doc-scanner"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  High-performance cross-platform document scanner with native bridge architecture and TurboModule compatibility.
                  
                  Features:
                  - iOS VisionKit document camera integration
                  - Android Google ML Kit document scanner
                  - Automatic architecture detection (TurboModule vs Legacy Bridge)  
                  - Cross-platform consistent API
                  - PDF generation from scanned documents
                  - Multi-page scanning support
                  - TypeScript support with full type definitions
                   DESC
  s.homepage     = "https://github.com/username/react-native-native-doc-scanner"
  s.license      = "MIT"
  s.authors      = { "Your Name" => "your.email@example.com" }
  s.platforms    = { :ios => "15.1" }
  s.source       = { :git => "https://github.com/username/react-native-native-doc-scanner.git", :tag => "#{s.version}" }

  s.source_files = "ios/NativeDocScanner/**/*.{h,c,m,swift}"
  s.requires_arc = true
  s.swift_version = "5.0"

  # iOS Frameworks
  s.frameworks = "UIKit", "VisionKit", "PDFKit"

  # React Native dependency
  s.dependency "React-Core"

  # New Architecture support (when available)
  s.compiler_flags = '-DRCT_NEW_ARCH_ENABLED=1' if ENV['RCT_NEW_ARCH_ENABLED'] == '1'

  # TurboModules support configuration
  if ENV['RCT_NEW_ARCH_ENABLED'] == '1' then
    s.compiler_flags = '-DRCT_NEW_ARCH_ENABLED=1'
    s.pod_target_xcconfig = {
      "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\"",
      "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
    }
    s.dependency "React-Codegen"
    s.dependency "RCT-Folly"
    s.dependency "RCTRequired"
    s.dependency "RCTTypeSafety"
    s.dependency "ReactCommon/turbomodule/core"
  end
end