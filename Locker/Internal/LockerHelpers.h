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

@property (nonatomic, assign, class, readonly) BOOL biometricsSettingsChanged;
@property (nonatomic, assign, class, readonly) BiometricsType deviceSupportsAuthenticationWithBiometrics;
@property (nonatomic, assign, class, readonly) BiometricsType configuredBiometricsAuthentication;

// LAPolicy helpers
+ (void)storeCurrentLAPolicyDomainState;

// UserDefaults helpers

@property (nonatomic, strong, class, readonly) NSString *keyKeychainServiceName;
+ (NSString *)keyKeychainAccountNameForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (NSString *)keyDidAskToUseBiometricsIDForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (NSString *)keyBiometricsIDActivatedForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (NSString *)keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier;

@end

NS_ASSUME_NONNULL_END
