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
        SecAccessControlRef sacObject;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                        kSecAccessControlTouchIDCurrentSet, &error);
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
                                     (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
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

+ (void)deletePasscodeForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[TouchIDManager keyTouchIDActivatedForUniqueIdentifier:uniqueIdentifier]];
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

#pragma mark - Touch ID Methods

+ (BOOL)deviceSupportsTouchID
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;
    if (![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        if (error.code == -6) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)canUseTouchID
{
    return [[[LAContext alloc] init]
            canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            error:nil];
}

+ (void)checkIfPasscodeExistsInKeychainWithCompletion:(void (^)(BOOL))completion forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSDictionary *query = nil;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        query = @{
                  (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                  (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                  (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                  (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                  (__bridge id)kSecReturnData: @NO,
                  (__bridge id)kSecUseAuthenticationUI : (__bridge id)kSecUseAuthenticationUIFail
                  };
    } else {
        query = @{
                  (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                  (__bridge id)kSecAttrService: [TouchIDManager keyKeychainServiceName],
                  (__bridge id)kSecAttrAccount: [TouchIDManager keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                  (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                  (__bridge id)kSecReturnData: @NO,
                  (__bridge id)kSecUseNoAuthenticationUI: @YES
                  };
    }
    
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

+ (void)checkIfTouchIDShouldBeUsedAndTouchIDSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forUniqueIdentifiers:(NSArray *)uniqueIdentifiers
{
    __block BOOL shouldBeUsedAndTouchIDSettingsAreChanged = NO;
    BOOL fingerIsAddedOrRemovedInTouchIDSettings = NO;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        fingerIsAddedOrRemovedInTouchIDSettings = [self checkIfFingerIsAddedOrRemovedInTouchIDSettings];
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSString *uniqueIdentifier in uniqueIdentifiers) {
        dispatch_group_enter(group);
        
        [TouchIDManager checkIfPasscodeExistsInKeychainWithCompletion:^(BOOL itemExists) {
            BOOL shouldUseTouchID = [self shouldUseTouchIDForUniqueIdentifier:uniqueIdentifier];
        
            if (shouldBeUsedAndTouchIDSettingsAreChanged == NO) {
                shouldBeUsedAndTouchIDSettingsAreChanged = shouldUseTouchID && (!itemExists || fingerIsAddedOrRemovedInTouchIDSettings);
            }
            dispatch_group_leave(group);
        } forUniqueIdentifier:uniqueIdentifier];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(shouldBeUsedAndTouchIDSettingsAreChanged);
        }
    });
}

+ (BOOL)shouldUseTouchIDForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[TouchIDManager keyTouchIDActivatedForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setShouldUseTouchID:(BOOL)shouldUseTouchID forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    if (shouldUseTouchID == NO && [TouchIDManager shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]) {
        [TouchIDManager setShouldAddPasscodeToKeychainOnNextLogin:NO forUniqueIdentifier:uniqueIdentifier];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:shouldUseTouchID forKey:[TouchIDManager keyTouchIDActivatedForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)didAskToUseTouchIDForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[TouchIDManager keyDidAskToUseTouchIDForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setDidAskToUseTouchID:(BOOL)askToUseTouchID forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [[NSUserDefaults standardUserDefaults] setBool:askToUseTouchID forKey:[TouchIDManager keyDidAskToUseTouchIDForUniqueIdentifier:uniqueIdentifier]];
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
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyDidAskToUseTouchIDForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyTouchIDActivatedForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[TouchIDManager keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [TouchIDManager deletePasscodeForUniqueIdentifier:uniqueIdentifier];
}

#pragma mark - User defaults keys help methods

+ (NSString *)keyKeychainServiceName
{
    return [NSString stringWithFormat:@"%@_KeychainService", kBundleName];
}

+ (NSString *)keyKeychainAccountNameForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSString *kKeychainAccountName = [NSString stringWithFormat:@"%@_KeychainAccount", kBundleName];
    return [NSString stringWithFormat:@"%@_%@", kKeychainAccountName, uniqueIdentifier];
}

+ (NSString *)keyDidAskToUseTouchIDForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSString *kUserDefaultsDidAskToUseTouchID = [NSString stringWithFormat:@"%@_UserDefaultsDidAskToUseTouchID", kBundleName];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsDidAskToUseTouchID, uniqueIdentifier];
}

+ (NSString *)keyTouchIDActivatedForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSString *kUserDefaultsKeyTouchIDActivated = [NSString stringWithFormat:@"%@_UserDefaultsKeyTouchIDActivated", kBundleName];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsKeyTouchIDActivated, uniqueIdentifier];
}

+ (NSString *)keyShouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier {
    NSString *kUserDefaultsShouldAddPasscodeToKeychainOnNextLogin = [NSString stringWithFormat:@"%@_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin", kBundleName];
    return [NSString stringWithFormat:@"%@_%@", kUserDefaultsShouldAddPasscodeToKeychainOnNextLogin, uniqueIdentifier];
}

+ (NSString *)keyLAPolicyDomainState
{
    return [NSString stringWithFormat:@"%@_UserDefaultsLAPolicyDomainState", kBundleName];
}

@end
