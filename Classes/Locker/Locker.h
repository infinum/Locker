//
//  Locker.h
//  Locker
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_CLOSED_ENUM(NSInteger, BiometricsType) {
    BiometricsTypeNone = 0,
    BiometricsTypeTouchID = 1,
    BiometricsTypeFaceID = 2
};

NS_ASSUME_NONNULL_BEGIN

@interface Locker : NSObject

+ (void)setPasscode:(NSString *)passcode forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)deletePasscodeForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)getCurrentPasscodeWithSuccess:(void(^)(NSString * _Nullable passcode))success failure:(void(^)(OSStatus failureStatus))failure operationPrompt:(NSString *)operationPrompt forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)checkIfBiometricsSettingsAreChanged;
+ (BiometricsType)deviceSupportsAuthenticationWithBiometrics;
+ (BiometricsType)canUseAuthenticationWithBiometrics;
+ (BOOL)shouldUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setShouldUseAuthenticationWithBiometrics:(BOOL)shouldUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setDidAskToUseAuthenticationWithBiometrics:(BOOL)askToUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setShouldAddPasscodeToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier;

@end

NS_ASSUME_NONNULL_END
