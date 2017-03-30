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
+ (BOOL)deviceSupportsTouchID;
+ (BOOL)canUseTouchID;
+ (BOOL)shouldUseTouchIDForTokenKey:(NSString *)tokenKey;
+ (void)setShouldUseTouchID:(BOOL)shouldUseTouchID forTokenKey:(NSString *)tokenKey;
+ (void)checkIfTouchIDShouldBeUsedAndTouchIDSettingsAreChangedWithCompletion:(void (^)(BOOL))completion forTokenKeys:(NSArray *)tokenKeys;
+ (BOOL)didAskToUseTouchIDForTokenKey:(NSString *)tokenKey;
+ (void)setDidAskToUseTouchID:(BOOL)askToUseTouchID forTokenKey:(NSString *)tokenKey;
+ (void)resetForTokenKey:(NSString *)tokenKey;

@end
