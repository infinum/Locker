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

@property (nonatomic, assign, class, readonly) BOOL biometricsSettingsAreChanged;
@property (nonatomic, assign, class, readonly) BiometricsType deviceSupportsAuthenticationWithBiometrics;
@property (nonatomic, assign, class, readonly) BiometricsType canUseAuthenticationWithBiometrics;

// Handle secrets (store, delete, fetch)

+ (void)setSecret:(NSString *)secret forUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(setSecret(_:for:));
+ (void)retrieveCurrentSecretForUniqueIdentifier:(NSString *)uniqueIdentifier operationPrompt:(NSString *)operationPrompt success:(void(^)(NSString * _Nullable secret))success failure:(void(^)(OSStatus failureStatus))failure NS_SWIFT_NAME(retrieveCurrentSecret(for:operationPrompt:success:failure:));
+ (void)deleteSecretForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(deleteSecret(for:));

// Additional helpers

+ (BOOL)shouldUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(shouldUseAuthenticationWithBiometrics(for:));
+ (void)setShouldUseAuthenticationWithBiometrics:(BOOL)shouldUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier;

+ (BOOL)didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(didAskToUseAuthenticationWithBiometrics(for:));
+ (void)setDidAskToUseAuthenticationWithBiometrics:(BOOL)askToUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier;

+ (BOOL)shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(shouldAddSecretToKeychainOnNextLogin(for:));
+ (void)setShouldAddSecretToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier;

// Data reset

+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier NS_SWIFT_NAME(reset(for:));

@end

NS_ASSUME_NONNULL_END
