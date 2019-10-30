Pod::Spec.new do |s|
  s.name         = "BiometricsManager"
  s.version      = "2.0.0"
  s.summary      = "Manager for handling Biometrics ID in Your app"
  s.description  = <<-DESC
                  Manager for handling TouchID and FaceID in Your app.
                   DESC
  s.homepage     = "https://github.com/infinum/iOS-BiometricsManager"
  s.license      = "MIT"
  s.author       = { "" => "barbara.vujicic@infinum.hr" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/infinum/iOS-BiometricsManager.git", :tag => "#{s.version}" }
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.frameworks = "UIKit", "LocalAuthentication", "Security"
end
