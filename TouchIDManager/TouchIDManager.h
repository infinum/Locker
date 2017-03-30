//
//  TouchIDManager.h
//  TouchIDManager
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TouchIDManager : NSObject

+ (void)setPasscode:(NSString *)passcode forTokenKey:(NSString *)tokenKey;
+ (void)deletePasscodeForTokenKey:(NSString *)tokenKey;
+ (void)getCurrentPasscodeWithSuccess:(void(^)(NSString *passcode))success failure:(void(^)(OSStatus failureStatus))failure operationPrompt:(NSString *)operationPrompt forTokenKey:(NSString *)tokenKey;
+ (void)checkIfTouchIDShouldBeUsedAndTouchIDSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forTokenKeys:(NSArray *)tokenKeys;
+ (BOOL)deviceSupportsTouchID;
+ (BOOL)canUseTouchID;
+ (BOOL)shouldUseTouchIDForTokenKey:(NSString *)tokenKey;
+ (void)setShouldUseTouchID:(BOOL)shouldUseTouchID forTokenKey:(NSString *)tokenKey;
+ (BOOL)didAskToUseTouchIDForTokenKey:(NSString *)tokenKey;
+ (void)setDidAskToUseTouchID:(BOOL)askToUseTouchID forTokenKey:(NSString *)tokenKey;
+ (BOOL)shouldAddPasscodeToKeychainOnNextLoginForTokenKey:(NSString *)tokenKey;
+ (void)setShouldAddPasscodeToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forTokenKey:(NSString *)tokenKey;
+ (void)resetForTokenKey:(NSString *)tokenKey;

@end
