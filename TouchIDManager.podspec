Pod::Spec.new do |s|
  s.name         = "TouchIDManager"
  s.version      = “0.0.2”
  s.summary      = "Manager for handling Touch ID in Your app"
  s.description  = <<-DESC
                  Manager for handling Touch ID in Your app.
                   DESC
  s.homepage     = "https://github.com/infinum/iOS-TouchIDManager"
  s.license      = "MIT"
  s.author       = { "" => "barbara.vujicic@infinum.hr" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/infinum/iOS-TouchIDManager.git", :tag => “0.0.2” }
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.frameworks = "UIKit", "LocalAuthentication", "Security"
end
