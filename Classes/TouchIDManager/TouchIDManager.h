//
//  TouchIDManager.h
//  TouchIDManager
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TouchIDManager : NSObject

+ (void)setPasscode:(NSString *)passcode forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)deletePasscodeForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)getCurrentPasscodeWithSuccess:(void(^)(NSString *passcode))success failure:(void(^)(OSStatus failureStatus))failure operationPrompt:(NSString *)operationPrompt forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)checkIfTouchIDShouldBeUsedAndTouchIDSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forUniqueIdentifiers:(NSArray *)uniqueIdentifiers;
+ (BOOL)deviceSupportsTouchID;
+ (BOOL)canUseTouchID;
+ (BOOL)shouldUseTouchIDForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setShouldUseTouchID:(BOOL)shouldUseTouchID forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)didAskToUseTouchIDForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setDidAskToUseTouchID:(BOOL)askToUseTouchID forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)shouldAddPasscodeToKeychainOnNextLoginForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)setShouldAddPasscodeToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (void)resetForUniqueIdentifier:(NSString *)uniqueIdentifier;
+ (BOOL)canAuthenticateByFaceID;

@end
