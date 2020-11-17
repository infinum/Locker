Pod::Spec.new do |s|
  s.name         = "Locker"
  s.version      = "2.3.0"
  s.summary      = "Securely lock your secrets under the watch of TouchID or FaceID keeper 🔒"
  s.description  = <<-DESC
                  Lightweight manager for saving, fetching and updating secrets (string value) in Keychain using Biometric Authentication. 
                  Includes methods for checking general changes in Biometric settings and device biometric type info (FaceID / TouchID / None).
                   DESC
  s.homepage     = "https://github.com/infinum/Locker.git"
  s.license      = "MIT"
  s.author       = { "Barbara Vujičić" => "barbara.vujicic@infinum.com" }
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/infinum/Locker.git", :tag => "#{s.version}" }
  s.source_files  = "Locker/**/*.{h,m}"
  s.private_header_files = "Locker/Internal/**/*.h"
  s.frameworks = "UIKit", "LocalAuthentication", "Security"
end
