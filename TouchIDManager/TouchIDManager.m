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

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define kBundleName [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]

@implementation TouchIDManager

#pragma mark - Keychain Methods

+ (void)getCurrentPasscodeWithSuccess:(void (^)(NSString *))success failure:(void (^)(OSStatus))failure operationPrompt:(NSString *)operationPrompt forTokenKey:(NSString *)tokenKey
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForTokenKey:tokenKey],
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

+ (void)setPasscode:(NSString *)passcode forTokenKey:(NSString *)tokenKey
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForTokenKey:tokenKey],
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // First delete previous item if it exists
        SecItemDelete((__bridge CFDictionaryRef)(query));
        
        // Then store it
        CFErrorRef error = NULL;
        SecAccessControlRef sacObject;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                        kSecAccessControlTouchIDAny, &error);
        } else {
            sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                        kSecAccessControlUserPresence, &error);
        }
        
        if(sacObject == NULL || error != NULL) {
            NSLog(@"can't create sacObject: %@", error);
            return;
        }
        
        NSDictionary *attributes = @{
                                     (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                     (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                                     (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForTokenKey:tokenKey],
                                     (__bridge id)kSecValueData: [passcode dataUsingEncoding:NSUTF8StringEncoding],
                                     (__bridge id)kSecUseNoAuthenticationUI: @YES,
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

+ (void)deletePasscodeForTokenKey:(NSString *)tokenKey
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[TouchIDManager keyTouchIDActivatedForTokenKey:tokenKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForTokenKey:tokenKey],
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SecItemDelete((__bridge CFDictionaryRef)(query));
    });
}

#pragma mark - Touch ID Methods

+ (BOOL)deviceSupportsTouchID
{
    if(![LAContext class]) {
        return false;
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // https://www.theiphonewiki.com/wiki/Models
    NSArray *deviceModelsWithTouchID = @[
                                         @"iPhone6,1",
                                         @"iPhone6,2",
                                         @"iPhone7,1",
                                         @"iPhone7,2",
                                         @"iPhone8,1",
                                         @"iPhone8,2",
                                         @"iPhone8,4",
                                         @"iPhone9,1",
                                         @"iPhone9,3",
                                         @"iPhone9,2",
                                         @"iPhone9,4",
                                         @"iPad4,8",
                                         @"iPad4,9",
                                         @"iPad5,1",
                                         @"iPad5,2",
                                         @"iPad5,3",
                                         @"iPad5,4",
                                         @"iPad6,3",
                                         @"iPad6,4",
                                         @"iPad6,7",
                                         @"iPad6,8",
                                         ];
    
    return [deviceModelsWithTouchID containsObject:deviceModel];
}

+ (BOOL)canUseTouchID
{
    return [[[LAContext alloc] init]
            canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            error:nil];
}

+ (BOOL)shouldUseTouchIDForTokenKey:(NSString *)tokenKey
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[TouchIDManager keyTouchIDActivatedForTokenKey:tokenKey]];
}

+ (void)checkIfPasscodeExistsInKeychainWithCompletion:(void (^)(BOOL))completion forTokenKey:(NSString *)tokenKey
{
    NSDictionary *query = nil;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        query = @{
                  (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                  (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                  (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForTokenKey:tokenKey],
                  (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                  (__bridge id)kSecReturnData: @NO,
                  (__bridge id)kSecUseAuthenticationUI : (__bridge id)kSecUseAuthenticationUIFail
                  };
    } else {
        query = @{
                  (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                  (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                  (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForTokenKey:tokenKey],
                  (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                  (__bridge id)kSecReturnData: @NO,
                  (__bridge id)kSecUseNoAuthenticationUI: @YES
                  };
    }
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), nil);
        BOOL keyAlreadyInKeychain = (status == errSecInteractionNotAllowed || status == errSecSuccess);
        
        if (completion) {
            completion(keyAlreadyInKeychain);
        }
    });
}

+ (BOOL)checkIfFingerIsAddedOrRemovedInTouchIDSettings
{
    __block BOOL touchIDSettingsChanged = NO;
    
    NSData *oldDomainState = [TouchIDManager savedLAPolicyDomainState];
    NSData *newDomainState = [TouchIDManager currentLAPolicyDomainState];
    
    // Check for domain state changes
    if (![oldDomainState isEqual:newDomainState]) {
        touchIDSettingsChanged = YES;
        
        [TouchIDManager setLAPolicyDomainState:newDomainState];
    }
    
    return touchIDSettingsChanged;
}

+ (void)checkIfTouchIDShouldBeUsedAndTouchIDSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forTokenKeys:(NSArray *)tokenKeys
{
    __block BOOL shouldBeUsedAndTouchIDSettingsAreChanged = NO;
    BOOL fingerIsAddedOrRemovedInTouchIDSettings = NO;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        fingerIsAddedOrRemovedInTouchIDSettings = [self checkIfFingerIsAddedOrRemovedInTouchIDSettings];
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSString *tokenKey in tokenKeys) {
        dispatch_group_enter(group);
        
        [TouchIDManager checkIfPasscodeExistsInKeychainWithCompletion:^(BOOL itemExists) {
            BOOL shouldUseTouchID = [self shouldUseTouchIDForTokenKey:tokenKey];
            
            if (completion) {
                if (shouldBeUsedAndTouchIDSettingsAreChanged == NO) {
                    shouldBeUsedAndTouchIDSettingsAreChanged = shouldUseTouchID && !itemExists && fingerIsAddedOrRemovedInTouchIDSettings;
                }
                dispatch_group_leave(group);
            }
        } forTokenKey:tokenKey];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(shouldBeUsedAndTouchIDSettingsAreChanged);
            });
        }
    });
}

+ (void)setShouldUseTouchID:(BOOL)shouldUseTouchID forTokenKey:(NSString *)tokenKey
{
    [[NSUserDefaults standardUserDefaults] setBool:shouldUseTouchID forKey:[TouchIDManager keyTouchIDActivatedForTokenKey:tokenKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)didAskToUseTouchIDForTokenKey:(NSString *)tokenKey
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[TouchIDManager keyDidAskToUseTouchIDForTokenKey:tokenKey]];
}

+ (void)setDidAskToUseTouchID:(BOOL)askToUseTouchID forTokenKey:(NSString *)tokenKey
{
    [[NSUserDefaults standardUserDefaults] setBool:askToUseTouchID forKey:[TouchIDManager keyDidAskToUseTouchIDForTokenKey:tokenKey]];
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
    return [[NSUserDefaults standardUserDefaults] objectForKey:[TouchIDManager keyUserDefaultsLAPolicyDomainState]];
}

+ (void)setLAPolicyDomainState:(NSData *)domainState
{
    [[NSUserDefaults standardUserDefaults] setObject:domainState forKey:[TouchIDManager keyUserDefaultsLAPolicyDomainState]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)resetForTokenKey:(NSString *)tokenKey
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyDidAskToUseTouchIDForTokenKey:tokenKey]];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyTouchIDActivatedForTokenKey:tokenKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [TouchIDManager deletePasscodeForTokenKey:tokenKey];
}

#pragma mark - User defaults keys help methods

+ (NSString *)keyKeychainServiceName
{
    return [NSString stringWithFormat:@"%@_KeychainService", kBundleName];
}

+ (NSString *)keyKeychainAccountNameForTokenKey:(NSString *)tokenKey
{
    NSString *kKeychainAccountName = [NSString stringWithFormat:@"%@_KeychainAccount", kBundleName];
    return [NSString stringWithFormat:@"%@_%@", kKeychainAccountName, tokenKey];
}

+ (NSString *)keyDidAskToUseTouchIDForTokenKey:(NSString *)tokenKey
{
    NSString *kUserDefaultsDidAskToUseTouchID = [NSString stringWithFormat:@"%@_UserDefaultsDidAskToUseTouchID", kBundleName];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsDidAskToUseTouchID, tokenKey];
}

+ (NSString *)keyTouchIDActivatedForTokenKey:(NSString *)tokenKey
{
    NSString *kUserDefaultsKeyTouchIDActivated = [NSString stringWithFormat:@"%@_UserDefaultsKeyTouchIDActivated", kBundleName];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsKeyTouchIDActivated, tokenKey];
}

+ (NSString *)keyUserDefaultsLAPolicyDomainState
{
    return [NSString stringWithFormat:@"%@_UserDefaultsLAPolicyDomainState", kBundleName];
}

@end
