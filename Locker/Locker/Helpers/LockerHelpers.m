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

@implementation LockerHelpers

#pragma mark - Biometrics helpers

+ (BOOL)deviceSupportsAuthenticationWithFaceID
{
    if ([LockerHelpers canUseAuthenticationWithFaceID]) {
        return YES;
    }

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSArray *faceIdDevices = @[@"iPhone10,3", @"iPhone10,6", @"iPhone11,2", @"iPhone11,4", @"iPhone11,6", @"iPhone11,8", @"iPhone12,1", @"iPhone12,3", @"iPhone12,5"];

    return [faceIdDevices containsObject:code];
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

+ (BOOL)checkIfBiometricsSettingsAreChanged
{
    BOOL biometricsSettingsChanged = NO;

    NSData *oldDomainState = [LockerHelpers savedLAPolicyDomainState];
    NSData *newDomainState = [LockerHelpers currentLAPolicyDomainState];

    // Check for domain state changes
    // For deactivated biometrics, LAContext in validation will return nil
    // storing that nil and comparing it to nil will result as `isEqual` NO
    // even data is not actually changed.
    BOOL biometricsDeactivated = (oldDomainState || newDomainState);
    BOOL biometricSettingsDidChange = ![oldDomainState isEqual:newDomainState];
    if (biometricsDeactivated && biometricSettingsDidChange) {
        biometricsSettingsChanged = YES;

        [LockerHelpers setLAPolicyDomainState:newDomainState];
    }

    return biometricsSettingsChanged;
}

+ (BiometricsType)checkIfDeviceSupportsAuthenticationWithBiometrics
{
    if (LockerHelpers.deviceSupportsAuthenticationWithFaceID) {
        return BiometricsTypeFaceID;
    }

    LAContext *context = [[LAContext alloc] init];
    NSError *error;
    if (![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        if (error.code == kLAErrorBiometryNotAvailable) {
            return BiometricsTypeNone;
        }
    }

    return BiometricsTypeTouchID;
}

+ (BiometricsType)checkIfCanUseAuthenticationWithBiometrics
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

+ (NSData *)currentLAPolicyDomainState
{
    LAContext *context = [[LAContext alloc] init];
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    return [context evaluatedPolicyDomainState];
}

+ (NSData *)savedLAPolicyDomainState
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[LockerHelpers keyLAPolicyDomainState]];
}

+ (void)setLAPolicyDomainState:(NSData *)domainState
{
    [[NSUserDefaults standardUserDefaults] setObject:domainState forKey:[LockerHelpers keyLAPolicyDomainState]];
}

#pragma mark - User defaults keys help methods

+ (NSString *)keyKeychainServiceName
{
    return [NSString stringWithFormat:@"%@_KeychainService", kBundleIdentifier];
}

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

+ (NSString *)keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier {
    NSString *kUserDefaultsShouldAddPasscodeToKeychainOnNextLogin = [NSString stringWithFormat:@"%@_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin", kBundleIdentifier];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsShouldAddPasscodeToKeychainOnNextLogin, uniqueIdentifier];
}

+ (NSString *)keyLAPolicyDomainState
{
    return [NSString stringWithFormat:@"%@_UserDefaultsLAPolicyDomainState", kBundleIdentifier];
}

@end
