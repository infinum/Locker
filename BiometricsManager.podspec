Pod::Spec.new do |s|
  s.name         = "BiometricsManager"
  s.version      = "1.9.9"
  s.summary      = "Manager for handling Secure data with Biometric"
  s.description  = <<-DESC
                  Manager for saving, fetching and updating data in Keychain using Biometric Authentication. Supports methods for checking changes in Biometric settings. Also supports device biometric type info. 
                   DESC
  s.homepage     = "https://github.com/infinum/iOS-BiometricsManager"
  s.license      = "MIT"
  s.author       = { "" => "barbara.vujicic@infinum.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/infinum/iOS-BiometricsManager.git", :tag => "#{s.version}" }
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.frameworks = "UIKit", "LocalAuthentication", "Security"
  s.deprecated_in_favor_of = 'Locker'
end
