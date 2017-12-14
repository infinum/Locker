//
//  TouchIDManager.h
//  TouchIDManager
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TouchIDManager : NSObject

+ (void)setPasscode:(NSString *)passcode forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)deletePasscodeForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)getCurrentPasscodeWithSuccess:(void(^)(NSString *passcode))success failure:(void(^)(OSStatus failureStatus))failure operationPrompt:(NSString *)operationPrompt forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)checkIfAuthenticationWithBiometricsShouldBeUsedAndBiometricsSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forUniqueIdentifiers:(NSArray *)uniqueIdentifiers;
+ (BOOL)deviceSupportsAuthenticationWithBiometrics;
+ (BOOL)deviceSupportsAuthenticationWithFaceID;
+ (BOOL)canUseAuthenticationWithBiometrics;
+ (BOOL)canUseAuthenticationWithFaceID;
+ (BOOL)shouldUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setShouldUseAuthenticationWithBiometrics:(BOOL)shouldUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setDidAskToUseAuthenticationWithBiometrics:(BOOL)askToUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setShouldAddPasscodeToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier;

@end
