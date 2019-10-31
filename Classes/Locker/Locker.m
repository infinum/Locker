//
//  Locker.m
//  Locker
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import "Locker.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#define kBundleIdentifier [[NSBundle mainBundle] bundleIdentifier]

@implementation Locker

#pragma mark - Keychain Methods

+ (void)getCurrentPasscodeWithSuccess:(void (^)(NSString *))success failure:(void (^)(OSStatus))failure operationPrompt:(NSString *)operationPrompt forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [BiometricsManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [BiometricsManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                            (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt: operationPrompt
                            };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess)
        {
            if (success) {
                NSData *resultData = ( __bridge_transfer NSData *)dataTypeRef;
                NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(result);
                });
            }
        } else {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(status);
                });
            }
        }
    });
}

+ (void)setPasscode:(NSString *)passcode forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [BiometricsManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [BiometricsManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // First delete previous item if it exists
        SecItemDelete((__bridge CFDictionaryRef)(query));
        
        // Then store it
        CFErrorRef error = NULL;
        SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                        kSecAccessControlTouchIDCurrentSet, &error);
        
        if(sacObject == NULL || error != NULL) {
            NSLog(@"can't create sacObject: %@", error);
            return;
        }
        
        NSDictionary *attributes = @{
                                     (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                     (__bridge id)kSecAttrService: [BiometricsManager keyKeychainServiceName],
                                     (__bridge id)kSecAttrAccount: [BiometricsManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                                     (__bridge id)kSecValueData: [passcode dataUsingEncoding:NSUTF8StringEncoding],
                                     (__bridge id)kSecUseAuthenticationUI: @NO,
                                     (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                     };
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
            
            // Store current LA policy domain state
            NSData *newDomainState = [BiometricsManager currentLAPolicyDomainState];
            [BiometricsManager setLAPolicyDomainState:newDomainState];
        });
    });
}

+ (void)deletePasscodeForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [BiometricsManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [BiometricsManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier]
                            };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SecItemDelete((__bridge CFDictionaryRef)(query));
    });
}

#pragma mark - Authentication with Biometrics methods

+ (BiometricsType)deviceSupportsAuthenticationWithBiometrics
{
    if (BiometricsManager.deviceSupportsAuthenticationWithFaceID) {
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

+ (BOOL)deviceSupportsAuthenticationWithFaceID
{
    if ([BiometricsManager canUseAuthenticationWithFaceID]) {
        return YES;
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSArray *faceIdDevices = @[@"iPhone10,3", @"iPhone10,6", @"iPhone11,2", @"iPhone11,4", @"iPhone11,6", @"iPhone11,8", @"iPhone12,1", @"iPhone12,3", @"iPhone12,5"];
    
    return [faceIdDevices containsObject:code];
}

+ (BiometricsType)canUseAuthenticationWithBiometrics
{
    BOOL canUse = [[[LAContext alloc] init]
                   canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                   error:nil];
    
    if (canUse && BiometricsManager.canUseAuthenticationWithFaceID) {
        return BiometricsTypeFaceID;
    } else if (canUse) {
        return BiometricsTypeTouchID;
    } else {
        return BiometricsTypeNone;
    }
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

    NSData *oldDomainState = [BiometricsManager savedLAPolicyDomainState];
    NSData *newDomainState = [BiometricsManager currentLAPolicyDomainState];

    // Check for domain state changes
    // For deactivated biometrics, LAContext in validation will return nil
    // storing that nil and comparing it to nil will result as `isEqual` NO
    // even data is not actually changed.
    BOOL biometricsDeactivated = (oldDomainState || newDomainState);
    BOOL biometricSettingsDidChange = ![oldDomainState isEqual:newDomainState];
    if (biometricsDeactivated && biometricSettingsDidChange) {
        biometricsSettingsChanged = YES;

        [BiometricsManager setLAPolicyDomainState:newDomainState];
    }

    return biometricsSettingsChanged;
}

+ (BOOL)shouldUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[BiometricsManager keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setShouldUseAuthenticationWithBiometrics:(BOOL)shouldUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    if (shouldUseAuthenticationWithBiometrics == NO && [BiometricsManager shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]) {
        [BiometricsManager setShouldAddPasscodeToKeychainOnNextLogin:NO forUniqueIdentifier:uniqueIdentifier];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:shouldUseAuthenticationWithBiometrics forKey:[BiometricsManager keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
}

+ (BOOL)didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[BiometricsManager keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setDidAskToUseAuthenticationWithBiometrics:(BOOL)askToUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] setBool:askToUseAuthenticationWithBiometrics forKey:[BiometricsManager keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
}

+ (BOOL)shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[BiometricsManager keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setShouldAddPasscodeToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] setBool:shouldAddPasscodeToKeychainOnNextLogin forKey:[BiometricsManager keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
}

+ (NSData *)currentLAPolicyDomainState
{
    LAContext *context = [[LAContext alloc] init];
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    return [context evaluatedPolicyDomainState];
}

+ (NSData *)savedLAPolicyDomainState
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[BiometricsManager keyLAPolicyDomainState]];
}

+ (void)setLAPolicyDomainState:(NSData *)domainState
{
    [[NSUserDefaults standardUserDefaults] setObject:domainState forKey:[BiometricsManager keyLAPolicyDomainState]];
}

+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[BiometricsManager keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[BiometricsManager keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[BiometricsManager keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
    [BiometricsManager deletePasscodeForUniqueIdentifier:uniqueIdentifier];
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
