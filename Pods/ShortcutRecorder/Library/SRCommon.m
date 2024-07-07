//
//  Copyright 2006 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <objc/runtime.h>

#import "SRCommon.h"


SRKeyCodeString const SRKeyCodeStringTabRight = @"⇥";
SRKeyCodeString const SRKeyCodeStringTabLeft = @"⇤";
SRKeyCodeString const SRKeyCodeStringReturn = @"⌅";
SRKeyCodeString const SRKeyCodeStringReturnR2L = @"↩";
SRKeyCodeString const SRKeyCodeStringDeleteLeft = @"⌫";
SRKeyCodeString const SRKeyCodeStringDeleteRight = @"⌦";
SRKeyCodeString const SRKeyCodeStringPadClear = @"⌧";
SRKeyCodeString const SRKeyCodeStringLeftArrow = @"←";
SRKeyCodeString const SRKeyCodeStringRightArrow = @"→";
SRKeyCodeString const SRKeyCodeStringUpArrow = @"↑";
SRKeyCodeString const SRKeyCodeStringDownArrow = @"↓";
SRKeyCodeString const SRKeyCodeStringPageDown = @"⇟";
SRKeyCodeString const SRKeyCodeStringPageUp = @"⇞";
SRKeyCodeString const SRKeyCodeStringNorthwestArrow = @"↖";
SRKeyCodeString const SRKeyCodeStringSoutheastArrow = @"↘";
SRKeyCodeString const SRKeyCodeStringEscape = @"⎋";
SRKeyCodeString const SRKeyCodeStringSpace = @" ";
SRKeyCodeString const SRKeyCodeStringHelp = @"?⃝";
SRKeyCodeString const SRKeyCodeStringJISUnderscore = @"＿";
SRKeyCodeString const SRKeyCodeStringJISComma = @"、";
SRKeyCodeString const SRKeyCodeStringJISYen = @"¥";

SRModifierFlagString const SRModifierFlagStringCommand = @"⌘";
SRModifierFlagString const SRModifierFlagStringOption = @"⌥";
SRModifierFlagString const SRModifierFlagStringShift = @"⇧";
SRModifierFlagString const SRModifierFlagStringControl = @"⌃";
SRModifierFlagString const SRModifierFlagStringFunction1 = @"f";
SRModifierFlagString const SRModifierFlagStringFunction2 = @"n";


NSBundle *SRBundle()
{
    static dispatch_once_t onceToken;
    static NSBundle *Bundle = nil;
    dispatch_once(&onceToken, ^{
        Bundle = [NSBundle bundleWithIdentifier:@"com.kulakov.ShortcutRecorder"];
    });

    if (Bundle)
        return Bundle;
    else
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Unable to find bundle with resources."
                                     userInfo:nil];
    }
}


NSString *SRLoc(NSString *aKey)
{
    return NSLocalizedStringFromTableInBundle(aKey, @"ShortcutRecorder", SRBundle(), nil);
}


NSImage *SRImage(NSString *anImageName)
{
    return [SRBundle() imageForResource:anImageName];
}


@implementation NSObject (SRCommon)

- (BOOL)SR_isEqual:(nullable NSObject *)anObject usingSelector:(SEL)aSelector ofCommonAncestor:(Class)anAncestor
{
    typedef BOOL (*IsEqualTo)(id, SEL, id);

    if (anObject == self)
        return YES;
    else if (!anObject)
        return NO;
    else if ([self isKindOfClass:anObject.class])
        return ((IsEqualTo)[self methodForSelector:aSelector])(self, aSelector, anObject);
    else if ([anObject isKindOfClass:self.class])
        return ((IsEqualTo)[anObject methodForSelector:aSelector])(anObject, aSelector, self);
    else if ([anObject isKindOfClass:anAncestor])
    {
        NSAssert([self isKindOfClass:anAncestor], @"Receiver must be an instance of the specified ancestor.");
        IsEqualTo selfImp = (IsEqualTo)[self methodForSelector:aSelector];
        IsEqualTo objectImp = (IsEqualTo)[anObject methodForSelector:aSelector];

        if (selfImp == objectImp)
            return selfImp(self, aSelector, anObject);
    }

    return NO;
}

@end


static UInt32 cached_inHotKeyModifiers = 0;


OSStatus interposed_RegisterEventHotKey(
    UInt32 inHotKeyCode,
    UInt32 inHotKeyModifiers,
    EventHotKeyID inHotKeyID,
    EventTargetRef inTarget,
    OptionBits inOptions,
    EventHotKeyRef * outRef
) {
    cached_inHotKeyModifiers = inHotKeyModifiers;
    return RegisterEventHotKey(inHotKeyCode, inHotKeyModifiers, inHotKeyID, inTarget, inOptions, outRef);
}


CGError interposed_CGSSetHotKeyWithExclusion(int cid, void* uid, UInt16 keyEquivalent, UInt16 keyCode, UInt64 keyModifiers, int exclusion) {
    if (cached_inHotKeyModifiers != 0) {
        keyModifiers = SRCarbonToCocoaFlags(cached_inHotKeyModifiers);
        cached_inHotKeyModifiers = 0;
    }
    return CGSSetHotKeyWithExclusion(cid, uid, keyEquivalent, keyCode, keyModifiers, exclusion);
}


DYLD_INTERPOSE(interposed_RegisterEventHotKey, RegisterEventHotKey)
DYLD_INTERPOSE(interposed_CGSSetHotKeyWithExclusion, CGSSetHotKeyWithExclusion)
