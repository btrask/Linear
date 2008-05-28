#import <Cocoa/Cocoa.h>

#define PGCommonRunLoopsMode (NSString *)kCFRunLoopCommonModes

@interface NSObject (AEAdditions)

- (void)AE_postNotificationName:(NSString *)aName;
- (void)AE_postNotificationName:(NSString *)aName userInfo:(NSDictionary *)aDict;

- (void)AE_addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName;
- (void)AE_removeObserver;
- (void)AE_removeObserver:(id)observer name:(NSString *)aName;

- (void)AE_performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay; // Uses PGCommonRunLoopsMode.

@end
