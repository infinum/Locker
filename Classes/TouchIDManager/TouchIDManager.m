//
//  TouchIDManager.m
//  TouchIDManager
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import "TouchIDManager.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#define kBundleIdentifier [[NSBundle mainBundle] bundleIdentifier]

@implementation TouchIDManager

#pragma mark - Keychain Methods

+ (void)getCurrentPasscodeWithSuccess:(void (^)(NSString *))success failure:(void (^)(OSStatus))failure operationPrompt:(NSString *)operationPrompt forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
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
                            (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
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
                                     (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                                     (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                                     (__bridge id)kSecValueData: [passcode dataUsingEncoding:NSUTF8StringEncoding],
                                     (__bridge id)kSecUseAuthenticationUI: @NO,
                                     (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                     };
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
            
            // Store current LA policy domain state
            NSData *newDomainState = [TouchIDManager currentLAPolicyDomainState];
            [TouchIDManager setLAPolicyDomainState:newDomainState];
        });
    });
}

+ (void)deletePasscodeForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[TouchIDManager keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier]
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SecItemDelete((__bridge CFDictionaryRef)(query));
    });
}

#pragma mark - Authentication with Biometrics methods

+ (BiometricsType)deviceSupportsAuthenticationWithBiometrics
{
    if (TouchIDManager.deviceSupportsAuthenticationWithFaceID) {
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
    if ([TouchIDManager canUseAuthenticationWithFaceID]) {
        return YES;
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSArray *faceIdDevices = @[@"iPhone10,3", @"iPhone10,6"];
    
    return [faceIdDevices containsObject:code];
}

+ (BiometricsType)canUseAuthenticationWithBiometrics
{
    BOOL canUse = [[[LAContext alloc] init]
                   canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                   error:nil];
    
    if (canUse && TouchIDManager.canUseAuthenticationWithFaceID) {
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
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            if (context.biometryType == LABiometryTypeFaceID) {
                return YES;
            }
        }
    }
    return NO;
}

+ (void)checkIfPasscodeExistsInKeychainWithCompletion:(void (^)(BOOL))completion forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSDictionary *query = @{
                  (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                  (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                  (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                  (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                  (__bridge id)kSecReturnData: @NO,
                  (__bridge id)kSecUseAuthenticationUI : (__bridge id)kSecUseAuthenticationUIFail
                  };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), nil);
        BOOL keyAlreadyInKeychain = (status == errSecInteractionNotAllowed || status == errSecSuccess);
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(keyAlreadyInKeychain);
                }
            });
        }
    });
}

+ (BOOL)checkIfBiometricsSettingsAreChanged
{
    __block BOOL biometricsSettingsChanged = NO;
    
    NSData *oldDomainState = [TouchIDManager savedLAPolicyDomainState];
    NSData *newDomainState = [TouchIDManager currentLAPolicyDomainState];
    
    // Check for domain state changes
    if (![oldDomainState isEqual:newDomainState]) {
        biometricsSettingsChanged = YES;
        
        [TouchIDManager setLAPolicyDomainState:newDomainState];
    }
    
    return biometricsSettingsChanged;
}

+ (void)checkIfAuthenticationWithBiometricsShouldBeUsedAndBiometricsSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forUniqueIdentifiers:(NSArray *)uniqueIdentifiers
{
    __block BOOL shouldBeUsedAndBiometricsSettingsAreChanged = NO;
    BOOL biometricsSettingsAreChanged = [self checkIfBiometricsSettingsAreChanged];
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSString *uniqueIdentifier in uniqueIdentifiers) {
        dispatch_group_enter(group);
        
        [TouchIDManager checkIfPasscodeExistsInKeychainWithCompletion:^(BOOL itemExists) {
            BOOL shouldUseAuthenticationWithBiometrics = [self shouldUseAuthenticationWithBiometricsForUniqueIdentifier:uniqueIdentifier];
        
            if (shouldBeUsedAndBiometricsSettingsAreChanged == NO) {
                shouldBeUsedAndBiometricsSettingsAreChanged = shouldUseAuthenticationWithBiometrics && (!itemExists || biometricsSettingsAreChanged);
            }
            dispatch_group_leave(group);
        } forUniqueIdentifier:uniqueIdentifier];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(shouldBeUsedAndBiometricsSettingsAreChanged);
        }
    });
}

+ (BOOL)shouldUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[TouchIDManager keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setShouldUseAuthenticationWithBiometrics:(BOOL)shouldUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    if (shouldUseAuthenticationWithBiometrics == NO && [TouchIDManager shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]) {
        [TouchIDManager setShouldAddPasscodeToKeychainOnNextLogin:NO forUniqueIdentifier:uniqueIdentifier];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:shouldUseAuthenticationWithBiometrics forKey:[TouchIDManager keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[TouchIDManager keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setDidAskToUseAuthenticationWithBiometrics:(BOOL)askToUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] setBool:askToUseAuthenticationWithBiometrics forKey:[TouchIDManager keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[TouchIDManager keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setShouldAddPasscodeToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] setBool:shouldAddPasscodeToKeychainOnNextLogin forKey:[TouchIDManager keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSData *)currentLAPolicyDomainState
{
    LAContext *context = [[LAContext alloc] init];
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    return [context evaluatedPolicyDomainState];
}

+ (NSData *)savedLAPolicyDomainState
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[TouchIDManager keyLAPolicyDomainState]];
}

+ (void)setLAPolicyDomainState:(NSData *)domainState
{
    [[NSUserDefaults standardUserDefaults] setObject:domainState forKey:[TouchIDManager keyLAPolicyDomainState]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [TouchIDManager deletePasscodeForUniqueIdentifier:uniqueIdentifier];
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
