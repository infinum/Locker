//
//  TouchIDManager.h
//  TouchIDManager
//
//  Copyright © 2017 Infinum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TouchIDManager : NSObject

+ (void)setPasscode:(NSString *)passcode forTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (void)deletePasscodeForTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (void)getCurrentPasscodeWithSuccess:(void(^)(NSString *passcode))success failure:(void(^)(OSStatus failureStatus))failure operationPrompt:(NSString *)operationPrompt forTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (void)checkIfTouchIDShouldBeUsedAndTouchIDSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forTokenSerialNumbers:(NSArray *)tokenSerialNumbers;
+ (BOOL)deviceSupportsTouchID;
+ (BOOL)canUseTouchID;
+ (BOOL)shouldUseTouchIDForTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (void)setShouldUseTouchID:(BOOL)shouldUseTouchID forTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (BOOL)didAskToUseTouchIDForTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (void)setDidAskToUseTouchID:(BOOL)askToUseTouchID forTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (BOOL)shouldAddPasscodeToKeychainOnNextLoginForTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (void)setShouldAddPasscodeToKeychainOnNextLogin:(BOOL)shouldAddPasscodeToKeychainOnNextLogin forTokenSerialNumber:(NSString *)tokenSerialNumber;
+ (void)resetForTokenSerialNumber:(NSString *)tokenSerialNumber;

@end
