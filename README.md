# **BiometricManager**

Library for handling sensitive data (`String` type) in Keychain with Biometric ID.

## Features

  * Save data in Keychain.
  * Fetch data from Keychain with Biometric ID.
  * Delete data from Keychain.
  * There are additional methods that help You with saving and fetching some additional info regarding the authentication with biometric usage.
  * Detect changes in Biometric settings.
  * Check if device has support for certain Biometric ID.

## Requirements

- iOS 9

## Usage

##### 1. Save Your data with `setPasscode: forUniqueIdentifier` method. 
For `uniqueIdentifier` pass `String` value You will later use to fetch Your data.

```objective-c
// Objective-C
[TouchIDManager setPasscode:@"passcode" forUniqueIdentifier:@"kUniqueIdentifier"];
```

##### 2. Fetch Your data with `getCurrentPasscodeWithSuccess: failure: operationPrompt: forUniqueIdentifier`. 
`operationPrompt` is `String` value which will be displayed as message on system Touch ID dialog.
You'll get Your data in `success` completion block. If, for some reason, Your data is not found in Keychain, You'll get error status in `failure` completion block.

```objective-c
// Objective-C
[TouchIDManager getCurrentPasscodeWithSuccess:^(NSString *passcode) {
    // do sth with passcode        
} failure:^(OSStatus failureStatus) {
    // handle failure
} operationPrompt:@"Touch ID description" forUniqueIdentifier:@"kUniqueIdentifier"];
```

##### 3. Delete data with `deletePasscodeForUniqueIdentifier` method.

```objective-c
// Objective-C
[TouchIDManager deletePasscodeForUniqueIdentifier:@"kUniqueIdentifier"];
```

##### 4. If You need to update Your saved data, just call `setPasscode: forUniqueIdentifier`. This method first deletes old value, if there is one, and then saves new one. 

##### 5. There are some additional methods that may help You with handling the authentication with Biometric usage.

Use `setShouldUseAuthenticationWithBiometrics: forUniqueIdentifier` method to save if Biometric ID should be used for fetching data from Keychain.
Use `shouldUseAuthenticationWithBiometricsForUniqueIdentifier` method to fetch that info.

Use `setDidAskToUseAuthenticationWithBiometrics: forUniqueIdentifier` method to save if user was asked to use Biometric ID for certain data.
Use `didAskToUseAuthenticationWithBiometricsForUniqueIdentifier` method to fetch that info.

Use `setShouldAddPasscodeToKeychainOnNextLogin: forUniqueIdentifier` method to save if data should be saved to Keychain on next user entering.
Use `shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier` method to fetch that info.

Note: This methods are here because they were used on some of our projects.
You should probably want to use the first two, `setShouldUseAuthenticationWithBiometrics: forUniqueIdentifier` and `shouldUseAuthenticationWithBiometricsForUniqueIdentifier`. Additional, You must use them if You're going to use `checkIfAuthenticationWithBiometricsShouldBeUsedAndBiometricsSettingsAreChangedWithCompletion: forUniqueIdentifiers` method.
The other ones will be useful if Your app has certain behaviour.

##### 6. You can observe changes in Biometric settings with `checkIfAuthenticationWithBiometricsShouldBeUsedAndBiometricsSettingsAreChangedWithCompletion: forUniqueIdentifiers`.
Method receives an array of unique identifiers since you'll probably want to handle this only one time in app, not for every saved data. If that's not the case, You can still pass one elemenent array.
It will return `true` in `completion` block if Biometric settings are changed since Your last saving in Keychain and there is unique identifier for which `shouldUseAuthenticationWithBiometricsForUniqueIdentifier` returns `true`.

```objective-c
// Objective-C
[TouchIDManager checkIfAuthenticationWithBiometricsShouldBeUsedAndBiometricsSettingsAreChangedWithCompletion:^(BOOL shouldBeUsedAndBiometricsSettingsAreChanged) {
    if (shouldBeUsedAndBiometricsSettingsAreChanged) {
        // handle case when settings are changed but Biometric should be used to fetch data
    }
} forUniqueIdentifiers:@[@"kUniqueIdentifier1", @"kUniqueIdentifier2"]];
```

##### 7. There are `deviceSupportsAuthenticationWithBiometrics` and `canUseAuthenticationWithBiometrics` methods which return `BiometricsType` enum (`BiometricsTypeNone`, `BiometricsTypeTouchID`, `BiometricsTypeFaceID`).
`deviceSupportsAuthenticationWithBiometrics` checks if device has support for some Biometric type.
`canUseAuthenticationWithBiometrics` checks if device has support for some Biometrics type and if that Biometric is enabled in device settings.
