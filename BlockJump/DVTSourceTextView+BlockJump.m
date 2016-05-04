//
//  DVTSourceTextView+BlockJump.m
//  BlockJump
//
//  Created by Yin Tan on 3/11/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import "DVTSourceTextView+BlockJump.h"
#import "NSObject+Swizzle.h"
#import "DVTFoundation.h"
#import "Constants.h"
#import <objc/runtime.h>

#define JUMP_DIRECTION_NONE 0
#define JUMP_DIRECTION_UP 1
#define JUMP_DIRECTION_DOWN 2

@implementation DVTSourceTextView (BlockJump)

+ (void)load
{
  [self _bj_swizzleInstanceMethod:@selector(keyDown:) withNewMethod:@selector(_bj_keyDown:)];
  [self _bj_swizzleInstanceMethod:@selector(initWithFrame:textContainer:)
                    withNewMethod:@selector(_bj_initWithFrame:textContainer:)];
  // Since ARC does not allow us to use @selector(dealloc).
  SEL selDealloc = NSSelectorFromString(@"dealloc");
  [self _bj_swizzleInstanceMethod:selDealloc withNewMethod:@selector(_bj_dealloc)];
}

#pragma mark - swizzled methods

- (id)_bj_initWithFrame:(NSRect)frame textContainer:(NSTextContainer *)textContainer
{
  id obj = [self _bj_initWithFrame:frame textContainer:textContainer];

  // Initiate shortcut setting observer.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_bj_shortcutSettingsChanged:)
                                               name:NSUserDefaultsDidChangeNotification
                                             object:[NSUserDefaults standardUserDefaults]];

  // Read settings.
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSData *prevShortcutSetting = [defaults objectForKey:kBlockJumpPreviousShortcutKey];
  NSData *nextShortcutSetting = [defaults objectForKey:kBlockJumpNextShortcutKey];
  MASShortcut *jumpPreviousShortcut = [MASShortcut shortcutWithData:prevShortcutSetting];
  MASShortcut *jumpNextShortcut = [MASShortcut shortcutWithData:nextShortcutSetting];

  [self setJumpPreviousShortcut:jumpPreviousShortcut];
  [self setJumpNextShortcut:jumpNextShortcut];

  return obj;
}

- (void)_bj_dealloc
{
  // Remove observer.
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSUserDefaultsDidChangeNotification
                                                object:[NSUserDefaults standardUserDefaults]];
  [self _bj_dealloc];
}

- (void)_bj_keyDown:(NSEvent *)theEvent
{
  NSInteger jumpDirection = [self _bj_jumpDirectionByEvent:theEvent];
  if (JUMP_DIRECTION_NONE != jumpDirection) {
    [self _bj_jumpBlockByDirection:jumpDirection];
  } else {
    [self _bj_keyDown:theEvent];
  }
}

#pragma mark - observer

- (void)_bj_shortcutSettingsChanged:(NSNotification *)noti
{
  NSData *jumpPreviousShortcutData = [noti.object dataForKey:kBlockJumpPreviousShortcutKey];
  NSData *jumpNextShortcutData = [noti.object dataForKey:kBlockJumpNextShortcutKey];
  MASShortcut *jumpPreviousShortcut = [MASShortcut shortcutWithData:jumpPreviousShortcutData];
  MASShortcut *jumpNextShortcut = [MASShortcut shortcutWithData:jumpNextShortcutData];

  [self setJumpPreviousShortcut:jumpPreviousShortcut];
  [self setJumpNextShortcut:jumpNextShortcut];
}

#pragma mark - private methods

// For unique id.
void *kJumpPreviousShortcut = &kJumpPreviousShortcut;
void *kJumpNextShortcut = &kJumpNextShortcut;

- (MASShortcut *)jumpPreviousShortcut
{
  return objc_getAssociatedObject(self, kJumpPreviousShortcut);
}

- (void)setJumpPreviousShortcut:(MASShortcut *)shortcut
{
  objc_setAssociatedObject(self, kJumpPreviousShortcut, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, kJumpPreviousShortcut, shortcut, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (MASShortcut *)jumpNextShortcut
{
  return objc_getAssociatedObject(self, kJumpNextShortcut);
}

- (void)setJumpNextShortcut:(MASShortcut *)shortcut
{
  objc_setAssociatedObject(self, kJumpNextShortcut, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, kJumpNextShortcut, shortcut, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)validShortcut:(MASShortcut *)shortcut
{
  return (shortcut != nil && shortcut.keyCode != 0 && shortcut.modifierFlags != 0);
}

/**
 * Check the key event and determine the jump direction.
 *
 * @param theEvent the key event to be checked.
 * @return the jump direction(UP or DOWN), JUMP_DIRECTION_NONE for not jumping.
 */
- (NSInteger)_bj_jumpDirectionByEvent:(NSEvent *)theEvent
{
  NSInteger ret = JUMP_DIRECTION_NONE;

  MASShortcut *jumpPrevShortcut = [self jumpPreviousShortcut];
  MASShortcut *jumpNextShortcut = [self jumpNextShortcut];

  if ([self validShortcut:jumpPrevShortcut]
      && theEvent.keyCode == jumpPrevShortcut.keyCode
      && MASShortcutClear(theEvent.modifierFlags) == jumpPrevShortcut.modifierFlags) {
    ret = JUMP_DIRECTION_UP;
  } else if ([self validShortcut:jumpNextShortcut]
             && theEvent.keyCode == jumpNextShortcut.keyCode
             && MASShortcutClear(theEvent.modifierFlags) == jumpNextShortcut.modifierFlags) {
    ret = JUMP_DIRECTION_DOWN;
  }

  return ret;
}

/**
 * Find the jump target range according to the direction and do the jump.
 *
 * @param direction jumping direction(UP or DOWN).
 */
- (void)_bj_jumpBlockByDirection:(NSInteger)direction
{
  NSRange currentRange = self.selectedRange;
  DVTTextStorage *sourceStorage = (DVTTextStorage *)self.textStorage;
  DVTSourceLandmarkItem *topLandmark = sourceStorage.topSourceLandmark;
  if (nil == topLandmark) {
    return;
  }

  DVTSourceLandmarkItem *currLandmark = [sourceStorage sourceLandmarkAtCharacterIndex:currentRange.location];
  if (nil == currLandmark) {
    currLandmark = topLandmark;
  }

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
    [self _bj_jumpTo:targetRange];
  }
}

- (void)_bj_jumpTo:(NSRange)targetRange
{
  [self setSelectedRange:targetRange];
  [self scrollRangeToVisible:targetRange];
  [self showFindIndicatorForRange:targetRange];
}

/**
 * Find the jump target range below the current landmark where the current caret location is.
 *
 * @param currLandmark the landmark where the current caret location is.
 * @param currLoc the location of the caret.
 * @return the jump target range, below the current landmark.
 *         When reached bottom, just the same value will be returned.
 */
- (NSRange)_bj_findJumpRangeBelowLandmark:(DVTSourceLandmarkItem *)currLandmark currentLocation:(NSUInteger)currLoc
{
  NSRange ret = [self _bj_jumpRangeOfLandmark:currLandmark];

  if (currLandmark.type <= 3) {
    // This is a container, and the caret is not at the end of this container, which menas the current
    // position is in a "gap" inside this container. We need to locate that "gap".
    ret = [self _bj_findJumpDownRangeInsideLandmark:currLandmark currentLocation:currLoc];
  } else {
    // This landmark is not a container. We'll gothrough its parent landmark to find out where we are.
    ret = [self _bj_findJumpDownRangeFromLandmark:currLandmark currentLocation:currLoc];
  }

  return ret;
}

/**
 * Find the jump down target range from the current landmark where the caret is.
 * Make sure that the landmark parameter is a "container" landmark(from log, type <= 3),
 * and the caret location is in a "gap" in the parameter landmark.
 *
 * @param landmark the landmark to be searched for.
 * @param currLoc the caret location.
 * @return the range of the jump target.
 */
- (NSRange)_bj_findJumpDownRangeInsideLandmark:(DVTSourceLandmarkItem *)landmark currentLocation:(NSUInteger)currLoc
{
  NSRange ret = [self _bj_jumpRangeOfLandmark:landmark];
  BOOL done = NO;

  if (nil == landmark.children || landmark.children.count <= 0) {
    // An empty container. Try to find the proper target from its parent landmark.
    DVTSourceLandmarkItem *parentLandmark = landmark.parent;
    if (parentLandmark) {
      ret = [self _bj_findJumpDownRangeInsideLandmark:parentLandmark currentLocation:currLoc];
    } else {
      ret = NSMakeRange(landmark.range.location + landmark.range.length, 0);
    }
    done = YES;
  }

  if (!done) {
    // Check if the current location is actually in current landmark's name range.
    // And if so, the target would be the first child item of this landmark.
    // But be careful for the top-level landmark, its nameRange equals to its range,
    // we should avoid that because even actually the caret is at the bottom of second last
    // child landmark of the top-level landmark, this check would be true and caused the caret
    // moving to the first landmark.
    if (NSLocationInRange(currLoc, landmark.nameRange) && landmark.type != 0) {
      ret = [self _bj_jumpRangeOfLandmark:((DVTSourceLandmarkItem *)landmark.children[0])];
      done = YES;
    }
  }

  if (!done) {
    DVTSourceLandmarkItem *firstItem = landmark.children[0];
    if (currLoc < firstItem.range.location) {
      ret = [self _bj_jumpRangeOfLandmark:firstItem];
      done = YES;
    }
  }

  if (!done) {
    DVTSourceLandmarkItem *lastItem = landmark.children[landmark.children.count - 1];
    if (currLoc >= (lastItem.range.location + lastItem.range.length)) {
      ret = NSMakeRange(landmark.range.location + landmark.range.length, 0);
      done = YES;
    }
  }

  // Now we're sure the current landmark has more than one child-landmark.
  // Reason: if there is only one item in this container landmark and the caret is just at a gap
  // of this container, it must be at the position above the first item or below the last one,
  // which we've just checked before.

  if (!done) {
    NSUInteger loopCount = landmark.children.count;
    for (NSUInteger i = 0; i < loopCount; i++) {
      DVTSourceLandmarkItem *item = landmark.children[i];
      DVTSourceLandmarkItem *nextItem = (i + 1 >= loopCount) ? nil : landmark.children[i + 1];

      if (nil == nextItem) {
        // Something is wrong, this could not happen since we've checked above so carefully.
        // For fail-safe, we just use the default value.
        done = YES;
        break;
      }

      if (currLoc >= item.range.location && currLoc < nextItem.range.location) {
        ret = [self _bj_jumpRangeOfLandmark:nextItem];
        done = YES;
        break;
      }
    }
  }

  return ret;
}

/**
 * Find the landmark below the current landmark and return its range.
 * Make sure that the landmark parameter is not a "container" landmark(from log, type > 3),
 * and the caret location is not in a "gap" between two landmarks.
 *
 * @param currLandmark the landmark to be searched for.
 * @param currLoc the caret location.
 * @return the range of the jump target.
 */
- (NSRange)_bj_findJumpDownRangeFromLandmark:(DVTSourceLandmarkItem *)currLandmark currentLocation:(NSUInteger)currLoc
{
  NSRange ret = NSMakeRange(currLoc, 0);
  BOOL done = NO;

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
          ret = [self _bj_jumpRangeOfLandmark:nextItem];
          done = YES;
        }
      }

      if (done) break;
    }
  }

  return ret;
}

/**
 * Find the jump target range above the current landmark where the current caret location is.
 *
 * @param currLandmark the landmark where the current caret location is.
 * @param currLoc the location of the caret.
 * @return the jump target range, above the current landmark.
 *         When reached bottom, just the same value will be returned.
 */
- (NSRange)_bj_findJumpRangeAboveLandmark:(DVTSourceLandmarkItem *)currLandmark currentLocation:(NSUInteger)currLoc
{
  NSRange ret = [self _bj_jumpRangeOfLandmark:currLandmark];

  if (currLandmark.type <= 3 && currLoc > (currLandmark.nameRange.location + currLandmark.nameRange.length)) {
    // The caret is in a container landmark. Let's find out where it is.
    ret = [self _bj_findJumpUpRangeInsideLandmark:currLandmark currentLocation:currLoc];
  } else {
    // This landmark is not a container, or the caret is not inside this container.
    // We'll search from this landmark's parent landmark to find the appropriate location.
    ret = [self _bj_findJumpUpRangeFromLandmark:currLandmark currentLocation:currLoc];
  }

  return ret;
}

/**
 * Find the jump up target range from the current landmark where the caret is.
 * Make sure that the landmark parameter is a "container" landmark(from log, type <= 3),
 * and the caret location is in a "gap" of the parameter landmark.
 *
 * @param landmark the landmark to be searched for.
 * @param currLoc the caret location.
 * @return the range of the jump target.
 */
- (NSRange)_bj_findJumpUpRangeInsideLandmark:(DVTSourceLandmarkItem *)landmark currentLocation:(NSUInteger)currLoc
{
  NSRange ret = [self _bj_jumpRangeOfLandmark:landmark];
  BOOL done = NO;

  if (nil == landmark.children || landmark.children.count <= 0) {
    // An empty container.
    done = YES;
  }

  if (!done) {
    // In a gap between the top of this container and the top of the first child item?
    DVTSourceLandmarkItem *firstItem = landmark.children[0];
    if (currLoc <= firstItem.range.location) {
      done = YES;
    }
  }

  if (!done) {
    // In a gap between the bottom of the last child item and the bottom of this container?
    DVTSourceLandmarkItem *lastItem = landmark.children[landmark.children.count - 1];
    if (currLoc >= lastItem.range.location + lastItem.range.length) {
      ret = [self _bj_jumpRangeOfLandmark:lastItem];
      done = YES;
    }
  }

  // Same as findJumpRangeBelow, now we're sure there're more than one child landmarks in this container.

  if (!done) {
    NSUInteger loopCount = landmark.children.count;
    for (NSUInteger i = 0; i < loopCount; i++) {
      DVTSourceLandmarkItem *item = landmark.children[i];
      DVTSourceLandmarkItem *nextItem = (i + 1 >= loopCount) ? nil : landmark.children[i + 1];

      if (nil == nextItem) {
        // Something is wrong. This should not happen since we've checked above so carefully.
        // For fail-safe, we just use the default value.
        done = YES;
        break;
      }

      if (currLoc >= item.range.location && currLoc <= nextItem.range.location) {
        ret = [self _bj_jumpRangeOfLandmark:item];
        done = YES;
        break;
      }
    }
  }

  return ret;
}

/**
 * Find the landmark above the current landmark and return its range.
 * Make sure that the landmark parameter is not a "container" landmark(from log, type > 3),
 * and the caret location is not in a "gap" between two landmarks.
 *
 * @param currLandmark the landmark to be searched for.
 * @param currLoc the caret location.
 * @return the range of the jump target.
 */
- (NSRange)_bj_findJumpUpRangeFromLandmark:(DVTSourceLandmarkItem *)currLandmark currentLocation:(NSUInteger)currLoc
{
  NSRange ret = NSMakeRange(currLoc, 0);
  BOOL done = NO;

  DVTSourceLandmarkItem *parentLandmark = currLandmark.type == 0 ? currLandmark : currLandmark.parent;
  // fail-safe check
  if (nil == parentLandmark || parentLandmark.children == nil || parentLandmark.children.count <= 0) {
    done = YES;
  } else {
    // Check if the caret has been at the top most child landmark's name range or beyond the first child landmark.
    // If so, we need to move to the parent landmark's name range.
    DVTSourceLandmarkItem *firstItem = parentLandmark.children[0];
    if (NSLocationInRange(currLoc, firstItem.nameRange) || currLoc < firstItem.nameRange.location) {
      if (parentLandmark.type > 0) {
        // Should not move to anywhere when parent is top-level landmark,
        // because top-level landmark's nameRange == its range.
        // So when we got into that situation, it means the caret has been
        // reached top most of the source file.
        ret = [self _bj_jumpRangeOfLandmark:parentLandmark];
      }
      done = YES;
    }

    if (!done) {
      NSUInteger siblingCount = parentLandmark.children.count;
      for (NSUInteger i = 0; i < siblingCount; i++) {
        DVTSourceLandmarkItem *item = parentLandmark.children[i];
        DVTSourceLandmarkItem *nextItem = (i + 1 >= siblingCount) ? nil : parentLandmark.children[i + 1];

        if (nil == nextItem || // reached bottom
            (currLoc >= item.range.location && currLoc <= nextItem.nameRange.location + nextItem.nameRange.length)) {
          // If the target is a container, we need to check inside instead of just jumping to its name range.
          if (item.type <= 3) {
            if (item.children != nil && item.children.count > 0) {
              ret = [self _bj_jumpRangeOfLandmark:((DVTSourceLandmarkItem *)item.children[item.children.count - 1])];
            } else {
              ret = [self _bj_jumpRangeOfLandmark:item];
            }
          } else {
            ret = [self _bj_jumpRangeOfLandmark:item];
          }
          done = YES;
          break;
        }
      }
    }
  }

  return ret;
}

/**
 * Get the jumping target range from the given landmark.
 */
- (NSRange)_bj_jumpRangeOfLandmark:(DVTSourceLandmarkItem *)landmark {
  // landmark's `range.location` may not equal to `nameRange.location`.
  // e.g. in Swift, the `range.location` of an empty "// MARK:" is pointing to the "M", with an empty `name` and
  // 0 length `nameRange`.
  // When that happens, we use both `range` and `nameRange` to determine the final jumping range.
  return (landmark.range.location < landmark.nameRange.location)
  ? NSMakeRange(landmark.range.location,
                (landmark.nameRange.location - landmark.range.location + landmark.nameRange.length))
  : landmark.nameRange;
}

@end
