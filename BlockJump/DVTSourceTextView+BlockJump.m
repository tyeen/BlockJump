//
//  Demo.m
//  BlockJump
//
//  Created by Yin Tan on 3/11/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import "DVTSourceTextView+BlockJump.h"
#import "NSObject+Swizzle.h"
#import "DVTFoundation.h"
#import "DVTKit.h"

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
    [self _bj_jumpBlockByDirection:JUMP_DIRECTION_UP];
  } else if (optKey && theEvent.keyCode == KEY_CODE_DOWN_ARROW) {
    [self _bj_jumpBlockByDirection:JUMP_DIRECTION_DOWN];
  } else {
    [self _bj_keyDown:theEvent];
  }
}

- (void)_bj_jumpBlockByDirection:(NSInteger)direction
{
  NSRange currentRange = self.selectedRange;
  DVTTextStorage *sourceStorage = self.textStorage;
  DVTSourceLandmarkItem *topLandmark = sourceStorage.topSourceLandmark;
  if (nil == topLandmark) {
    NSLog(@"%s ignore because top_landmark is null.", __FUNCTION__);
    return;

  }

  DVTSourceLandmarkItem *currLandmark = [sourceStorage sourceLandmarkAtCharacterIndex:currentRange.location];
  if (nil == currLandmark) {
    currLandmark = topLandmark;
  }

  NSLog(@"%s currentRange=%@, top_landmark=%@\n curr_landmark=[type: %d, other: %@]", __FUNCTION__,
        NSStringFromRange(currentRange), topLandmark, currLandmark.type, currLandmark);

  if (currLandmark != nil && currLandmark.children != nil) {
    NSRange targetRange;
    switch (direction) {
      case JUMP_DIRECTION_DOWN:
        targetRange = [self _bj_findJumpRangeBelowLandmark:currLandmark currentLocation:currentRange.location];
        break;

      case JUMP_DIRECTION_UP:
        targetRange = [self _bj_findJumpRangeAboveLandmark:currLandmark currentLocation:currentRange.location];
        break;

      default:
        break;
    }
    [self setSelectedRange:targetRange];
    [self scrollRangeToVisible:targetRange];
  }
}

- (NSRange)_bj_findJumpRangeBelowLandmark:(DVTSourceLandmarkItem *)currLandmark currentLocation:(NSUInteger)currLoc
{
  NSLog(@"%s curr_landmark: [type=%d, range=%@, nameRange=%@]", __FUNCTION__,
        currLandmark.type, NSStringFromRange(currLandmark.range), NSStringFromRange(currLandmark.nameRange));
  NSRange ret = currLandmark.nameRange;
  BOOL done = NO;

  if (currLandmark.type <= 3) {
    // This is a container, and the caret is not at the end of this container, which menas the current
    // position is in a "gap" inside this container. We need to locate that "gap".

    if (nil == currLandmark.children || currLandmark.children.count <= 0) {
      // An empty container.
      ret = NSMakeRange(currLandmark.range.location + currLandmark.range.length, 0);
      done = YES;
    }

    if (!done) {
      // Check if the current location is actually in current landmark's name range.
      // And if so, the target would be the first child item of this landmark.
      // But be careful for the top-level landmark, its nameRange equals to its range,
      // we should avoid that because even actually the caret is at the bottom of second last
      // child landmark of the top-level landmark, this check would be true and caused the caret
      // moving to the first landmark.
      if (NSLocationInRange(currLoc, currLandmark.nameRange)
          && currLandmark.type != 0) {
        ret = ((DVTSourceLandmarkItem *)currLandmark.children[0]).nameRange;
        done = YES;
      }
    }

    if (!done) {
      DVTSourceLandmarkItem *firstItem = currLandmark.children[0];
      if (currLoc < firstItem.range.location) {
        ret = firstItem.nameRange;
        NSLog(@"use first_item.namerange: %@", NSStringFromRange(ret));
        done = YES;
      }
    }

    if (!done) {
      DVTSourceLandmarkItem *lastItem = currLandmark.children[currLandmark.children.count - 1];
      if (currLoc >= (lastItem.range.location + lastItem.range.length)) {
        ret = NSMakeRange(currLandmark.range.location + currLandmark.range.length, 0);
        NSLog(@"use container's bottom: %@", NSStringFromRange(ret));
        done = YES;
      }
    }

    // Now we're sure that there're more than one children in the current landmark.
    // Reason: if there is only one item in this container landmark and the caret is just at a gap
    // of this container, it must be at the position above the first item or below the last one.
    // And we've just checked those situations above.

    if (!done) {
      NSUInteger loopCount = currLandmark.children.count;
      for (NSUInteger i = 0; i < loopCount; i++) {
        DVTSourceLandmarkItem *item = currLandmark.children[i];
        DVTSourceLandmarkItem *nextItem = (i + 1 >= loopCount) ? nil : currLandmark.children[i + 1];

        if (nil == nextItem) {
          // Something is wrong, this could not happen since we've checked above so carefully.
          // So for fail-safe, we just use the default value.
          done = YES;
          break;
        }

        if (currLoc > item.range.location && currLoc < nextItem.range.location) {
          ret = nextItem.nameRange;
          done = YES;
          break;
        }
      }
    }
  } else {
    // So this landmark is not a container. We'll gothrough its parent landmark to find out where we are.
    DVTSourceLandmarkItem *parentItem = currLandmark.type == 0 ? currLandmark : currLandmark.parent;
    if (nil == parentItem || parentItem.children == nil || parentItem.children.count <= 0) {
      // fail-safe check
      done = YES;
    } else {
      NSUInteger siblingCount = parentItem.children.count;
      for (NSUInteger i = 0; i < siblingCount; i++) {
        DVTSourceLandmarkItem *item = parentItem.children[i];

        if (NSLocationInRange(currLoc, item.range)) {
          if (i + 1 >= siblingCount) {
            // Reached the bottom.
            ret = NSMakeRange(item.range.location + item.range.length, 0);
            done = YES;
          } else {
            DVTSourceLandmarkItem *nextItem = parentItem.children[i + 1];
            ret = nextItem.nameRange;
            done = YES;
          }
        }

        if (done) break;
      }
    }
  }

  return ret;
}

- (NSRange)_bj_findJumpRangeAboveLandmark:(DVTSourceLandmarkItem *)currLandmark currentLocation:(NSUInteger)currLoc
{
  NSLog(@"%s curr_landmark: [type=%d, range=%@, nameRange=%@]", __FUNCTION__,
        currLandmark.type, NSStringFromRange(currLandmark.range), NSStringFromRange(currLandmark.nameRange));

  NSRange ret = currLandmark.nameRange;
  BOOL done = NO;

  if (currLandmark.type <= 3 && currLoc > (currLandmark.nameRange.location + currLandmark.nameRange.length)) {
    // This is a container. And the caret is below the nameRange of this container. So the position of the caret
    // is in a "gap" of this container. We need to locate that "gap".

    if (nil == currLandmark.children || currLandmark.children.count <= 0) {
      // An empty container.
      ret = currLandmark.nameRange;
      done = YES;
    }

    if (!done) {
      // In a gap between the top of this container and the top of the first child item?
      DVTSourceLandmarkItem *firstItem = currLandmark.children[0];
      if (currLoc <= firstItem.range.location) {
        ret = currLandmark.nameRange;
        done = YES;
      }
    }

    if (!done) {
      // In a gap between the bottom of the last child item and the bottom of this container?
      DVTSourceLandmarkItem *lastItem = currLandmark.children[currLandmark.children.count - 1];
      if (currLoc > lastItem.range.location + lastItem.range.length) {
        ret = lastItem.nameRange;
        done = YES;
      }
    }

    // Same as findJumpRangeBelow, noew we're sure there're more than one child landmarks in this container.

    if (!done) {
      NSUInteger loopCount = currLandmark.children.count;
      for (int i = 0; i < loopCount; i++) {
        DVTSourceLandmarkItem *item = currLandmark.children[i];
        DVTSourceLandmarkItem *nextItem = (i + 1 >= loopCount) ? nil : currLandmark.children[i + 1];

        if (nil == nextItem) {
          // Something is wrong. This could not happen since we've checked above so carefully.
          // For fail-safe, we just use the default value.
          done = YES;
          break;
        }

        if (currLoc >= item.range.location && currLoc <= nextItem.range.location) {
          ret = item.nameRange;
          done = YES;
          break;
        }
      }
    }
  } else {
    // This landmark is not a container, or the caret is not inside this container.
    // We'll search from this landmark's parent landmark to find the appropriate location.

    DVTSourceLandmarkItem *parentLandmark = currLandmark.type == 0 ? currLandmark : currLandmark.parent;
    // fail-safe check
    if (nil == parentLandmark || parentLandmark.children == nil || parentLandmark.children.count <= 0) {
      done = YES;
    } else {
      // Check if the caret has been at the top most child landmark's name range.
      // If so, we need to move to the parent landmark's name range.
      DVTSourceLandmarkItem *firstItem = parentLandmark.children[0];
      if (NSLocationInRange(currLoc, firstItem.nameRange)) {
        if (parentLandmark.type > 0) {
          // Should not move to anywhere when parent is top-level landmark,
          // because top-level landmark's nameRange == its range.
          // So when we got into that situation, it means the caret has been
          // reached top most of the source file.
          ret = parentLandmark.nameRange;
        }
        done = YES;
      }

      if (!done) {
        NSUInteger siblingCount = parentLandmark.children.count;
        for (NSUInteger i = 0; i < siblingCount; i++) {
          DVTSourceLandmarkItem *item = parentLandmark.children[i];
          DVTSourceLandmarkItem *nextItem = (i + 1 >= siblingCount) ? nil : parentLandmark.children[i + 1];

          if (nil == nextItem) {
            // Reached bottom.
            ret = item.nameRange;
            done = YES;
            break;
          }

          if (NSLocationInRange(currLoc, nextItem.range)) {
            ret = item.nameRange;
            done = YES;
            break;
          }
        }
      }
    }
  }

  return ret;
}

@end

#define TEXT
