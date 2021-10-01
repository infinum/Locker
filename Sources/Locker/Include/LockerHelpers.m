//
//  LockerHelpers.m
//  Locker
//
//  Copyright © 2019 Infinum. All rights reserved.
//

#import "LockerHelpers.h"

#import "Locker.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <sys/utsname.h>

#define kBundleIdentifier [[NSBundle mainBundle] bundleIdentifier]

@interface LockerHelpers()

@property (nonatomic, strong, class, readonly) NSString *keyLAPolicyDomainState;
@property (nonatomic, assign, class, readonly) BOOL canUseAuthenticationWithFaceID;
@property (nonatomic, strong, class, readonly) NSString *deviceCode;
@property (nonatomic, assign, class, readonly) BOOL deviceSupportsAuthenticationWithFaceID;
@property (nonatomic, assign, class, readonly) BOOL isSimulator;

@end

@implementation LockerHelpers

#pragma mark - Biometrics helpers

+ (void)storeCurrentLAPolicyDomainState
{
    NSData *newDomainState = [LockerHelpers currentLAPolicyDomainState];
    [LockerHelpers setLAPolicyDomainState:newDomainState];
}

#pragma mark - User defaults keys help methods

+ (NSString *)keyKeychainAccountNameForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSString *kKeychainAccountName = [NSString stringWithFormat:@"%@_KeychainAccount", kBundleIdentifier];
    return [NSString stringWithFormat:@"%@_%@", kKeychainAccountName, uniqueIdentifier];
}

+ (NSString *)keyDidAskToUseBiometricsIDForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSString *kUserDefaultsDidAskToUseBiometricsID = [NSString stringWithFormat:@"%@_UserDefaultsDidAskToUseTouchID", kBundleIdentifier];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsDidAskToUseBiometricsID, uniqueIdentifier];
}

+ (NSString *)keyBiometricsIDActivatedForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSString *kUserDefaultsKeyBiometricsIDActivated = [NSString stringWithFormat:@"%@_UserDefaultsKeyTouchIDActivated", kBundleIdentifier];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsKeyBiometricsIDActivated, uniqueIdentifier];
}

+ (NSString *)keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier {
    NSString *kUserDefaultsShouldAddSecretToKeychainOnNextLogin = [NSString stringWithFormat:@"%@_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin", kBundleIdentifier];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsShouldAddSecretToKeychainOnNextLogin, uniqueIdentifier];
}

#pragma mark - Private methods

+ (NSData *)currentLAPolicyDomainState
{
    LAContext *context = [[LAContext alloc] init];
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    return [context evaluatedPolicyDomainState];
}

+ (NSData *)savedLAPolicyDomainState
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:LockerHelpers.keyLAPolicyDomainState];
}

+ (void)setLAPolicyDomainState:(NSData *)domainState
{
    [[NSUserDefaults standardUserDefaults] setObject:domainState forKey:LockerHelpers.keyLAPolicyDomainState];
}

#pragma mark - Getters

+ (BOOL)biometricsSettingsChanged
{
    BOOL biometricsSettingsChangedStatus = NO;

    NSData *oldDomainState = [LockerHelpers savedLAPolicyDomainState];
    NSData *newDomainState = [LockerHelpers currentLAPolicyDomainState];

    // Check for domain state changes
    // For deactivated biometrics, LAContext in validation will return nil
    // storing that nil and comparing it to nil will result as `isEqual` NO
    // even data is not actually changed.
    BOOL biometricsDeactivated = (oldDomainState || newDomainState);
    BOOL biometricSettingsDidChange = ![oldDomainState isEqual:newDomainState];
    if (biometricsDeactivated && biometricSettingsDidChange) {
        biometricsSettingsChangedStatus = YES;

        [LockerHelpers setLAPolicyDomainState:newDomainState];
    }

    return biometricsSettingsChangedStatus;
}

+ (BOOL)canUseAuthenticationWithFaceID
{
    LAContext *context = [LAContext new];
    NSError *error;

    if (@available(iOS 11.0, *)) {
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error] && [context respondsToSelector:@selector(biometryType)]) {
            if (context.biometryType == LABiometryTypeFaceID) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BiometricsType)deviceSupportsAuthenticationWithBiometrics
{
    if (LockerHelpers.deviceSupportsAuthenticationWithFaceID) {
        return BiometricsTypeFaceID;
    }

    LAContext *context = [[LAContext alloc] init];
    NSError *error;
    if (![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        // When user removes all fingers for TouchID, error code will be `notEnrolled`.
        // In that case, we want to return that device supports TouchID.
        // In case lib is used on simulator, error code will always be `notEnrolled` and only then
        // we want to return that biometrics is not supported as we don't know what simulator is used.
        if (error.code == kLAErrorBiometryNotAvailable || (error.code == kLAErrorBiometryNotEnrolled && self.isSimulator)) {
            return BiometricsTypeNone;
        }
    }

    return BiometricsTypeTouchID;
}

+ (BiometricsType)configuredBiometricsAuthentication
{
    BOOL canUse = [[[LAContext alloc] init]
                   canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                   error:nil];

    if (canUse && LockerHelpers.canUseAuthenticationWithFaceID) {
        return BiometricsTypeFaceID;
    } else if (canUse) {
        return BiometricsTypeTouchID;
    } else {
        return BiometricsTypeNone;
    }
}

+ (NSString *)keyKeychainServiceName
{
    return [NSString stringWithFormat:@"%@_KeychainService", kBundleIdentifier];
}

+ (NSString *)keyLAPolicyDomainState
{
    return [NSString stringWithFormat:@"%@_UserDefaultsLAPolicyDomainState", kBundleIdentifier];
}

+ (NSString *)deviceCode
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (BOOL)deviceSupportsAuthenticationWithFaceID
{
    if (LockerHelpers.canUseAuthenticationWithFaceID) {
        return YES;
    }

    NSArray *faceIdDevices = @[
        @"iPhone10,3", // iPhone X Global
        @"iPhone10,6", // iPhone X GSM
        @"iPhone11,2", // iPhone XS
        @"iPhone11,4", // iPhone XS Max
        @"iPhone11,6", // iPhone XS Max Global
        @"iPhone11,8", // iPhone XR
        @"iPhone12,1", // iPhone 11
        @"iPhone12,3", // iPhone 11 Pro
        @"iPhone12,5", // iPhone 11 Pro Max
        @"iPhone13,1", // iPhone 12 Mini
        @"iPhone13,2", // iPhone 12
        @"iPhone13,3", // iPhone 12 Pro
        @"iPhone13,4", // iPhone 12 Pro Max
        @"iPhone14,2", // iPhone 13 Mini
        @"iPhone14,3", // iPhone 13
        @"iPhone14,4", // iPhone 13 Pro
        @"iPhone14,5", // iPhone 13 Pro Max
        @"iPad8,1", //  iPad Pro 11 inch 3rd Gen (WiFi)
        @"iPad8,2", //  iPad Pro 11 inch 3rd Gen (1TB, WiFi)
        @"iPad8,3", //  iPad Pro 11 inch 3rd Gen (WiFi+Cellular)
        @"iPad8,4", //  iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)
        @"iPad8,5", //  iPad Pro 12.9 inch 3rd Gen (WiFi)
        @"iPad8,6", //  iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)
        @"iPad8,7", //  iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)
        @"iPad8,8", //  iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)
        @"iPad8,9", //  iPad Pro 11 inch 4th Gen (WiFi)
        @"iPad8,10", // iPad Pro 11 inch 4th Gen (WiFi+Cellular)
        @"iPad8,11", // iPad Pro 12.9 inch 4th Gen (WiFi)
        @"iPad8,12" //  iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)
    ];

    return [faceIdDevices containsObject:LockerHelpers.deviceCode];
}

+ (BOOL)isSimulator
{
    return [LockerHelpers.deviceCode isEqualToString:@"x86_64"];
}

@end