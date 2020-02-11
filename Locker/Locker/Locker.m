//
//  Locker.m
//  Locker
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import "Locker.h"
#import <UIKit/UIKit.h>
#import "LockerHelpers.h"

static NSUserDefaults *currentUserDefaults;

@implementation Locker

#pragma mark - Handle secrets (store, delete, fetch)

+ (void)setSecret:(NSString *)secret forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    #if TARGET_OS_SIMULATOR
    [currentUserDefaults setObject:secret forKey:uniqueIdentifier];
    #else
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [LockerHelpers keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [LockerHelpers keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
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
                                     (__bridge id)kSecAttrService: [LockerHelpers keyKeychainServiceName],
                                     (__bridge id)kSecAttrAccount: [LockerHelpers keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
                                     (__bridge id)kSecValueData: [secret dataUsingEncoding:NSUTF8StringEncoding],
                                     (__bridge id)kSecUseAuthenticationUI: @NO,
                                     (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                     };

        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            SecItemAdd((__bridge CFDictionaryRef)attributes, nil);

            // Store current LA policy domain state
            [LockerHelpers storeCurrentLAPolicyDomainState];
        });
    });
    #endif
}

+ (void)retrieveCurrentSecretForUniqueIdentifier:(NSString *)uniqueIdentifier operationPrompt:(NSString *)operationPrompt success:(void(^)(NSString * _Nullable secret))success failure:(void(^)(OSStatus failureStatus))failure
{
    #if TARGET_OS_SIMULATOR
    NSString *simulatorSecret = [currentUserDefaults stringForKey:uniqueIdentifier];
    if (!simulatorSecret) {
        failure(errSecItemNotFound);
        return;
    }
    success(simulatorSecret);
    #else
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [LockerHelpers keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [LockerHelpers keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier],
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
    #endif
}

+ (void)deleteSecretForUniqueIdentifier:(NSString *)uniqueIdentifier
{

    #if TARGET_OS_SIMULATOR
    [currentUserDefaults removeObjectForKey:uniqueIdentifier];
    #else
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [LockerHelpers keyKeychainServiceName],
                            (__bridge id)kSecAttrAccount: [LockerHelpers keyKeychainAccountNameForUniqueIdentifier:uniqueIdentifier]
                            };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SecItemDelete((__bridge CFDictionaryRef)(query));
    });
    #endif
}

#pragma mark - Additional helpers

+ (BOOL)shouldUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [currentUserDefaults boolForKey:[LockerHelpers keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setShouldUseAuthenticationWithBiometrics:(BOOL)shouldUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    if (shouldUseAuthenticationWithBiometrics == NO && [Locker shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]) {
        [Locker setShouldAddSecretToKeychainOnNextLogin:NO forUniqueIdentifier:uniqueIdentifier];
    }
    
    [currentUserDefaults setBool:shouldUseAuthenticationWithBiometrics forKey:[LockerHelpers keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
}

+ (BOOL)didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [currentUserDefaults boolForKey:[LockerHelpers keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setDidAskToUseAuthenticationWithBiometrics:(BOOL)askToUseAuthenticationWithBiometrics forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [currentUserDefaults setBool:askToUseAuthenticationWithBiometrics forKey:[LockerHelpers keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
}

+ (BOOL)shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [currentUserDefaults boolForKey:[LockerHelpers keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
}

+ (void)setShouldAddSecretToKeychainOnNextLogin:(BOOL)shouldAddSecretToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier
{
    [currentUserDefaults setBool:shouldAddSecretToKeychainOnNextLogin forKey:[LockerHelpers keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
}

#pragma mark - Data reset

+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier;
{
    [currentUserDefaults removeObjectForKey:[LockerHelpers keyDidAskToUseBiometricsIDForUniqueIdentifier:uniqueIdentifier]];
    [currentUserDefaults removeObjectForKey:[LockerHelpers keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:uniqueIdentifier]];
    [currentUserDefaults removeObjectForKey:[LockerHelpers keyBiometricsIDActivatedForUniqueIdentifier:uniqueIdentifier]];
    [Locker deleteSecretForUniqueIdentifier:uniqueIdentifier];
}

#pragma mark - Getters -

+ (BOOL)biometricsSettingsDidChange
{
    return LockerHelpers.biometricsSettingsChanged;
}

+ (BOOL)isRunningFromTheSimulator
{
    #if TARGET_OS_SIMULATOR
    return YES;
    #else
    return NO;
    #endif
}

+ (BiometricsType)deviceSupportsAuthenticationWithBiometrics
{
    return LockerHelpers.deviceSupportsAuthenticationWithBiometrics;
}

+ (BiometricsType)configuredBiometricsAuthentication
{
    return LockerHelpers.configuredBiometricsAuthentication;
}

+ (NSUserDefaults *)userDefaults
{
    return currentUserDefaults;
}

#pragma mark - Setters -

+ (void)setUserDefaults:(NSUserDefaults *)userDefaults
{
    if (userDefaults == nil) {
        currentUserDefaults = [NSUserDefaults standardUserDefaults];
    } else {
        currentUserDefaults = userDefaults;
    }
}

@end
