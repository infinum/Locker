//
//  LockerHelpers.h
//  Locker
//
//  Copyright © 2019 Infinum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BiometricsType.h"

NS_ASSUME_NONNULL_BEGIN

@interface LockerHelpers : NSObject

// Check device support

+ (BOOL)deviceSupportsAuthenticationWithFaceID;
+ (BOOL)canUseAuthenticationWithFaceID;
+ (BOOL)checkIfBiometricsSettingsAreChanged;
+ (BiometricsType)checkIfDeviceSupportsAuthenticationWithBiometrics;
+ (BiometricsType)checkIfCanUseAuthenticationWithBiometrics;

// LAPolicy helpers

+ (NSData *)currentLAPolicyDomainState;
+ (NSData *)savedLAPolicyDomainState;
+ (void)setLAPolicyDomainState:(NSData *)domainState;

// UserDefaults helpers

+ (NSString *)keyKeychainServiceName;
+ (NSString *)keyKeychainAccountNameForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (NSString *)keyDidAskToUseBiometricsIDForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (NSString *)keyBiometricsIDActivatedForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (NSString *)keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (NSString *)keyLAPolicyDomainState;

@end

NS_ASSUME_NONNULL_END
