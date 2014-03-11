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

#define JUMP_DIRECTION_UP 1
#define JUMP_DIRECTION_DOWN 2

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
    [self _bj_jumpBlockByDirection:JUMP_DIRECTION_UP];
  } else if (optKey && theEvent.keyCode == KEY_CODE_DOWN_ARROW) {
    NSLog(@"opt-down");
    [self _bj_jumpBlockByDirection:JUMP_DIRECTION_DOWN];
  } else {
    [self _bj_keyDown:theEvent];
  }
}

- (void)_bj_jumpBlockByDirection:(NSInteger)direction
{
  NSRange currentRange = self.selectedRange;
  DVTSourceTextStorage *sourceStorage = self.textStorage;
  DVTSourceLandmarkItem *topLandmarkItem = sourceStorage.topSourceLandmark;
  NSLog(@"%s currentRange=%@, top_landmark=%@", __FUNCTION__, NSStringFromRange(currentRange), topLandmarkItem);
  if (topLandmarkItem != nil && topLandmarkItem.children != nil) {
    NSRange targetRange;
    switch (direction) {
      case JUMP_DIRECTION_DOWN:
        targetRange = [self _bj_findJumpRangeBelowRange:currentRange inTopLandmark:topLandmarkItem];
        break;

      case JUMP_DIRECTION_UP:
        targetRange = [self _bj_findJumpRangeAboveRange:currentRange inTopLandmark:topLandmarkItem];
        break;

      default:
        break;
    }
    [self setSelectedRange:targetRange];
    [self scrollRangeToVisible:targetRange];
  }
}

// About the parameter range, we only care about its location value to determine where the caret should go.
- (NSRange)_bj_findJumpRangeAboveRange:(NSRange)currRange inTopLandmark:(DVTSourceLandmarkItem *)topLandmark
{
  NSRange ret = currRange;

  // Current location is above the first landmark item, just make the result match the top most landmark's.
  DVTSourceLandmarkItem *firstItem = topLandmark.children[0];
  NSLog(@"%s first_landmark: [type=%d, range=%@]", __FUNCTION__, firstItem.type, NSStringFromRange(firstItem.range));
  if (firstItem.range.location >= currRange.location) {
    ret = topLandmark.nameRange;
    return ret;
  }

  // Current location is below the last landmark item, then the target is the end of the last landmark item.
  DVTSourceLandmarkItem * lastItem = topLandmark.children[topLandmark.children.count - 1];
  NSLog(@"%s last_landmark: [type=%d, range=%@]", __FUNCTION__, lastItem.type, NSStringFromRange(lastItem.range));
  if (lastItem.range.location + lastItem.range.length < currRange.location) {
    ret = NSMakeRange(lastItem.range.location + lastItem.range.length, 0);
    return ret;
  }

  // The common situation.
  NSUInteger loopCount= topLandmark.children.count;
  for (NSUInteger i = 0; i < loopCount; i++) {
    DVTSourceLandmarkItem *item = topLandmark.children[i];
    DVTSourceLandmarkItem *nextItem = (i + 1 >= loopCount) ? nil : topLandmark.children[i + 1];
    NSLog(@"%s item: [type=%d, range=%@]", __FUNCTION__, item.type, NSStringFromRange(item.range));

    if (nextItem == nil) {
      // There is no next landmark, which means we've reached bottom.
      // We need to check this last landmark(or may be the unique one) to see if it is another container,
      // like @implementation or @interface.(from my DEBUG log, I can see their type is smaller than 3...
      if (item.type > 3 || item.children == nil || item.children.count == 0) {
        ret = item.nameRange;
        break;
      } else {
        ret = [self _bj_findJumpRangeAboveRange:currRange inTopLandmark:item];
      }
    } else if (currRange.location > item.range.location && currRange.location <= nextItem.range.location) {
      ret = item.nameRange;
      break;
    }
  }


  return ret;
}

// About the parameter range, we only care about its location value to determine where the caret should go.
- (NSRange)_bj_findJumpRangeBelowRange:(NSRange)currRange inTopLandmark:(DVTSourceLandmarkItem *)topLandmark
{
  NSRange ret = currRange;

  // Current location is above the first landmark item, so the target is the first landmark item.
  DVTSourceLandmarkItem *firstItem = topLandmark.children[0];
  NSLog(@"%s first_landmark: [type=%d, range=%@]", __FUNCTION__, firstItem.type, NSStringFromRange(firstItem.range));
  if (firstItem.range.location > currRange.location) {
    ret = firstItem.nameRange;
    return ret;
  }

  // Current location is below the last landmark item, then the target is the end of the file.
  DVTSourceLandmarkItem * lastItem = topLandmark.children[topLandmark.children.count - 1];
  NSLog(@"%s last_landmark: [type=%d, range=%@]", __FUNCTION__, lastItem.type, NSStringFromRange(lastItem.range));
  if (lastItem.range.location + lastItem.range.length < currRange.location) {
    ret = NSMakeRange(topLandmark.range.location + topLandmark.range.length, 0);
    return ret;
  }

  // The common situation.
  NSInteger loopCount= topLandmark.children.count;
  for (NSInteger i = 0; i < loopCount; i++) {
    DVTSourceLandmarkItem *item = topLandmark.children[i];
    DVTSourceLandmarkItem *nextItem = (i + 1 >= loopCount) ? nil : topLandmark.children[i + 1];

    NSLog(@"%s item: [type=%d, range=%@]", __FUNCTION__, item.type, NSStringFromRange(item.range));
    if (nextItem != nil) {
      NSLog(@"%s: next_item: [type=%d, range=%@]", __FUNCTION__, nextItem.type, NSStringFromRange(nextItem.range));
    }

    if (nil == nextItem) {
      // There is no next landmark, which means we've reached bottom.
      // We need to check this last landmark(or may be the unique one) to see if it is another container,
      // like @implementation or @interface.(from my DEBUG log, I can see their type is smaller than 3...

      if (item.type > 3 || item.children == nil || item.children.count == 0) {
        ret = NSMakeRange(item.range.location + item.range.length, 0);
        break;
      } else {
        ret = [self _bj_findJumpRangeBelowRange:currRange inTopLandmark:item];
        break;
      }
    } else if (currRange.location >= item.range.location && currRange.location < nextItem.range.location) {
      // We're in a perfect situation: the current caret is just between these two landmarks.
      ret = nextItem.nameRange;
      break;
    }
  }

  return ret;
}

@end
