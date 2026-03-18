Pod::Spec.new do |s|
  s.name         = "Locker"
  s.version      = "3.1.0"
  s.summary      = "Securely lock your secrets under the watch of TouchID or FaceID keeper 🔒"
  s.description  = <<-DESC
                  Lightweight manager for saving, fetching and updating secrets (string value) in Keychain using Biometric Authentication. 
                  Includes methods for checking general changes in Biometric settings and device biometric type info (FaceID / TouchID / None).
                   DESC
  s.homepage     = "https://github.com/infinum/Locker.git"
  s.license      = "MIT"
  s.author       = {
    "Jasmin Abou Aldan" => "jasmin.aboualdan@infinum.com",
    "Siniša Abramović" => "sinisa.abramovic@infinum.com",
    "Nikola Šimunko" => "nikola.simunko@infinum.com"
  }
  s.platform     = :ios, "12.0"
  s.swift_version = "5.10"
  s.source       = { :git => "https://github.com/infinum/Locker.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/Locker/**/*.swift"
  s.exclude_files = 'Sources/Locker/Tests/'

  s.resource_bundles = { 'Locker_Locker' => ['Sources/Locker/**/*.json', 'Sources/Locker/SupportingFiles/PrivacyInfo.xcprivacy'] }
  s.frameworks = "LocalAuthentication", "Security"

  s.test_spec 'Tests' do |test_spec|
      test_spec.source_files = 'Sources/Locker/Tests/**/*.swift'
  end
end
