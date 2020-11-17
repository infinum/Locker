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
@property (nonatomic, assign, class, readonly) BOOL canUseAuthenticationWithTouchID;
@property (nonatomic, strong, class, readonly) NSString *deviceCode;
@property (nonatomic, assign, class, readonly) BOOL deviceSupportsAuthenticationWithTouchID;
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

+ (BOOL)canUseAuthenticationWithTouchID
{
    LAContext *context = [LAContext new];
    NSError *error;

    if (@available(iOS 11.0, *)) {
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error] && [context respondsToSelector:@selector(biometryType)]) {
            if (context.biometryType == LABiometryTypeTouchID) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BiometricsType)deviceSupportsAuthenticationWithBiometrics
{
    if (LockerHelpers.deviceSupportsAuthenticationWithTouchID) {
        return BiometricsTypeTouchID;
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

    if (canUse && LockerHelpers.canUseAuthenticationWithTouchID) {
        return BiometricsTypeTouchID;
    } else if (canUse) {
        return BiometricsTypeFaceID;
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

+ (BOOL)deviceSupportsAuthenticationWithTouchID
{
    if (LockerHelpers.canUseAuthenticationWithTouchID) {
        return YES;
    }

    NSArray *touchIdDevices = @[@"iPhone6,1", @"iPhone6,2", @"iPhone7,2", @"iPhone7,1", @"iPhone8,1", @"iPhone8,2", @"iPhone8,4", @"iPhone9,1", @"iPhone9,3", @"iPhone9,2", @"iPhone9,4", @"iPhone10,1", @"iPhone10,4", @"iPhone10,2", @"iPhone10,5", @"iPhone12,8", @"iPad4,7", @"iPad4,8", @"iPad4,9", @"iPad5,1", @"iPad5,2", @"iPad4,1", @"iPad4,2", @"iPad4,3", @"iPad5,3", @"iPad5,4", @"iPad6,3", @"iPad6,4", @"iPad6,7", @"iPad6,8", @"iPad6,11", @"iPad6,12", @"iPad7,1", @"iPad7,2", @"iPad7,3", @"iPad7,4", @"iPad7,5", @"iPad7,6", @"iPad7,11", @"iPad7,12", @"iPad11,3", @"iPad11,4", @"iPad11,6", @"iPad11,7", @"iPad13,1", @"iPad13,2"];

    return [touchIdDevices containsObject:LockerHelpers.deviceCode];
}

+ (BOOL)isSimulator
{
    return [LockerHelpers.deviceCode isEqualToString:@"x86_64"];
}

@end
