//
//  Demo.m
//  BlockJump
//
//  Created by Yin Tan on 3/11/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import "DVTSourceTextView+BlockJump.h"
#import "NSObject+Swizzle.h"

#define KEY_CODE_UP_ARROW 0x7E
#define KEY_CODE_DOWN_ARROW 0x7D

@implementation DVTSourceTextView (BlockJump)

+ (void)load
{
  [self _bj_swizzleInstanceMethod:@selector(keyDown:) withNewMethod:@selector(_bj_keyDown:)];
}

- (void)_bj_keyDown:(NSEvent *)theEvent
{
  BOOL optKey = (theEvent.modifierFlags & NSAlternateKeyMask) != 0;
  if (optKey && theEvent.keyCode == KEY_CODE_UP_ARROW) {
    NSLog(@"opt-up.");
  } else if (optKey && theEvent.keyCode == KEY_CODE_DOWN_ARROW) {
    NSLog(@"opt-down");
  } else {
    [self _bj_keyDown:theEvent];
  }
}

@end
