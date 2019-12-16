//
//  Locker.h
//  Locker
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BiometricsType.h"

NS_ASSUME_NONNULL_BEGIN

@interface Locker : NSObject


#pragma mark - Properties

/**
 Boolean value that indicates if biometric settings have changed
 */
@property (nonatomic, assign, class, readonly) BOOL biometricsSettingsDidChange;

/**
 Boolean value that indicates if Locker is running from the simulator

 As Simulator does not support Keychain storage, Locker run from the simulator
 will use UserDefaults storage instead.
 */
@property (nonatomic, assign, class, readonly) BOOL isRunningFromTheSimulator;

/**
 The biometrics type that the device supports (None, TouchID, FaceID).
 */
@property (nonatomic, assign, class, readonly) BiometricsType deviceSupportsAuthenticationWithBiometrics;

/**
 The biometrics type that the device supports which is enabled and configured in the device settings.
 */
@property (nonatomic, assign, class, readonly) BiometricsType configuredBiometricsAuthentication;


#pragma mark - Handle secrets (store, delete, fetch)

/**
 Used for storing value to Keychain with unique identifier.

 If Locker is run on the Simulator, the secret will not be stored securely in the keychain.
 Instead, the UserDefaults storage will be used.

 @param secret value to store to Keychain
 @param uniqueIdentifier unique key used for storing secret
 */
+ (void)setSecret:(NSString *)secret forUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(setSecret(_:for:));

/**
 Used for retrieving secret from Keychain with unique identifier.
 If operation is successfull, secret is returned. Otherwise, failure status is returned.

 @param uniqueIdentifier unique key used for fetching secret
 @param operationPrompt message showed to the user on TouchID dialog
 @param success completion block returning secret
 @param failure failure block returning failure status
 */
+ (void)retrieveCurrentSecretForUniqueIdentifier:(NSString *)uniqueIdentifier operationPrompt:(NSString *)operationPrompt success:(void(^)(NSString * _Nullable secret))success failure:(void(^)(OSStatus failureStatus))failure NS_SWIFT_NAME(retrieveCurrentSecret(for:operationPrompt:success:failure:));

/**
 Used for deleting secret from Keychain with unique identifier.

 @param uniqueIdentifier unique key used for deleting secret
 */
+ (void)deleteSecretForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(deleteSecret(for:));


#pragma mark - Additional helpers

/**
  Used for fetching whether user enabled authentication with biometrics.

 @param uniqueIdentifier used for fetching shouldUseAuthenticationWithBiometrics value
 @return used to determine whether user enabled authentication with biometrics
 */
+ (BOOL)shouldUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(shouldUseAuthenticationWithBiometrics(for:));

/**
 Used for saving whether user enabled authentication with biometrics.

 @param shouldUseAuthenticationWithBiometrics used to determine whether user enabled authentication with biometrics
 @param uniqueIdentifier used for saving shouldUseAuthenticationWithBiometrics value
 */
+ (void)setShouldUseAuthenticationWithBiometrics:(BOOL)shouldUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(setShouldUseAuthenticationWithBiometrics(_:for:));

/**
 Used for fetching whether user was asked to use authentication with biometrics.
 
 @param uniqueIdentifier used for fetching askToUseAuthenticationWithBiometrics value
 @return used to determine whether user was asked to use authentication with biometrics
 */
+ (BOOL)didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(didAskToUseAuthenticationWithBiometrics(for:));

/**
 Used for saving whether user was asked to use authentication with biometrics.
 
 @param askToUseAuthenticationWithBiometrics used to determine whether user was asked to use authentication with biometrics
 @param uniqueIdentifier used for saving askToUseAuthenticationWithBiometrics value
 */
+ (void)setDidAskToUseAuthenticationWithBiometrics:(BOOL)askToUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(setDidAskToUseAuthenticationWithBiometrics(_:for:));

/**
 Used for fetching whether secret should be stored to Keychain on next login.
 
 @param uniqueIdentifier used for fetching shouldAddPasscodeToKeychainOnNextLogin value
 @return used to determine whether secret should be stored to Keychain on next login
 */
+ (BOOL)shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(shouldAddSecretToKeychainOnNextLogin(for:));

/**
 Used for saving whether secret should be stored to Keychain on next login.
 
 @param shouldAddSecretToKeychainOnNextLogin used to determine whether secret should be stored to Keychain on next login
 @param uniqueIdentifier used for saving shouldAddPasscodeToKeychainOnNextLogin value
 */
+ (void)setShouldAddSecretToKeychainOnNextLogin:(BOOL)shouldAddSecretToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(setShouldAddSecretToKeychainOnNextLogin(_:for:));


#pragma mark - Data reset

/**
 Used for deleting all stored data for unique identifier.

 @param uniqueIdentifier unique key used for deleting all stored data
 */
+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(reset(for:));

@end

NS_ASSUME_NONNULL_END
