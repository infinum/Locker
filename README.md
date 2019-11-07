# **Locker 🔒** 

![Bitrise](https://img.shields.io/bitrise/eb8928b119a9df30?token=753GPSmElQJ1aRfplKYJLw) ![GitHub](https://img.shields.io/github/license/infinum/Locker) ![Cocoapods](https://img.shields.io/cocoapods/v/Locker) ![Cocoapods platforms](https://img.shields.io/cocoapods/p/Locker) 

Lightweight library for handling sensitive data (`String` type) in Keychain using iOS Biometric features.

## Features

  * Save data in Keychain.
  * Fetch data from Keychain with Biometric ID.
  * Delete data from Keychain.
  * There are additional methods that help you with saving and fetching some additional info regarding the authentication with biometric usage.
  * Detect changes in Biometric settings.
  * Check if device has support for certain Biometric ID.

## Requirements

- iOS 9.0 +

## Installation

The easiest way to use Locker in your project is by using the CocoaPods package manager.


#### CocoaPods

See installation instructions for [CocoaPods](http://cocoapods.org) if not already installed

To integrate the library into your Xcode project specify the pod dependency to your `Podfile`:

```ruby
platform :ios, '9.0'
use_frameworks!

pod 'Locker'
```

run pod install

```bash
pod install
```

## Usage

##### 1. Save Your data with `setSecret: forUniqueIdentifier:` method. 
For `uniqueIdentifier` pass `String` value You will later use to fetch Your data.

```objective-c
// Objective-C
[Locker setSecret:@"passcode" forUniqueIdentifier:@"kUniqueIdentifier"];
```

```swift
// Swift
Locker.setSecret("passcode", for: "kUniqueIdentifier")
```

 ##### 2. Fetch Your data with `retrieveCurrentSecretForUniqueIdentifier: operationPrompt: success: failure:`. 
`operationPrompt` is `String` value which will be displayed as message on system Touch ID dialog.
You'll get Your data in `success` completion block. If, for some reason, Your data is not found in Keychain, You'll get error status in `failure` completion block.

```objective-c
// Objective-C
[Locker retrieveCurrentSecretForUniqueIdentifier:@"kUniqueIdentifier" operationPrompt:@"Touch ID description" success:^(NSString *secret) {
    // do sth with secret        
} failure:^(OSStatus failureStatus) {
    // handle failure
}];
```

```swift
// Swift
Locker.retrieveCurrentSecret(for: "kUniqueIdentifier", operationPrompt: "Touch ID description", success: { (secret) in
    // do sth with secret
}, failure: { (failureStatus) in
    // handle failure
})
```

##### 3. Delete data with `deleteSecretForUniqueIdentifier:` method.

```objective-c
// Objective-C
[Locker deleteSecretForUniqueIdentifier:@"kUniqueIdentifier"];
```

```swift
// Swift
Locker.deleteSecret(for: "kUniqueIdentifier")
```

##### 4. If You need to update Your saved data, just call `setSecret: forUniqueIdentifier:`. This method first deletes old value, if there is one, and then saves new one. 

##### 5. There are some additional methods that may help You with handling the authentication with Biometric usage.

Use `setShouldUseAuthenticationWithBiometrics: forUniqueIdentifier:` method to save if Biometric ID should be used for fetching data from Keychain.
Use `shouldUseAuthenticationWithBiometricsForUniqueIdentifier:` method to fetch that info.

Use `setDidAskToUseAuthenticationWithBiometrics: forUniqueIdentifier:` method to save if user was asked to use Biometric ID for certain data.
Use `didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:` method to fetch that info.

Use `setShouldAddSecretToKeychainOnNextLogin: forUniqueIdentifier:` method to save if data should be saved to Keychain on next user entering.
Use `shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:` method to fetch that info.

Note: This methods are here because they were used on some of our projects.
You should probably want to use the first two, `setShouldUseAuthenticationWithBiometrics: forUniqueIdentifier` and `shouldUseAuthenticationWithBiometricsForUniqueIdentifier`.
The other ones will be useful if Your app has certain behaviour.

##### 6. You can check for Biometrics settings changes with `biometricsSettingsAreChanged`.
It will return `true` if Biometric settings are changed since Your last calling this method or last saving in Keychain.

```objective-c
// Objective-C
BOOL biometrySettingsChanged = Locker.biometricsSettingsAreChanged;
BOOL usingBiometry = [Locker shouldUseAuthenticationWithBiometricsForUniqueIdentifier:@"kUniqueIdentifier"];
if (biometrySettingsChanged && usingBiometry) {
    // handle case when settings are changed and biometry should be used
}
```

```swift
// Swift
let biometrySettingsChanged = Locker.biometricsSettingsAreChanged
let usingBiometry = Locker.shouldUseAuthenticationWithBiometrics(for: "kUniqueIdentifier")
if biometrySettingsChanged && usingBiometry {
// handle case when settings are changed and biometry should be used
}
```

##### 7. There are `deviceSupportsAuthenticationWithBiometrics` and `canUseAuthenticationWithBiometrics` methods which return `BiometricsType` enum (`BiometricsTypeNone`, `BiometricsTypeTouchID`, `BiometricsTypeFaceID`).
`deviceSupportsAuthenticationWithBiometrics` checks if device has support for some Biometric type.
`canUseAuthenticationWithBiometrics` checks if device has support for some Biometrics type and if that Biometric is enabled in device settings.

## Contributing

Feedback and code contributions are very much welcome. Just make a pull request with a short description of your changes. By making contributions to this project you give permission for your code to be used under the same [license](https://github.com/infinum/Locker/blob/feature/rename-and-swift-support/LICENSE).

