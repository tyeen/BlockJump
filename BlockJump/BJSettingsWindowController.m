//
//  BJSettingsWindowController.m
//  BlockJump
//
//  Created by Yin Tan on 4/6/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import "BJSettingsWindowController.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "Constants.h"

@interface BJSettingsWindowController ()

@property (weak) IBOutlet MASShortcutView *previousShortcutView;
@property (weak) IBOutlet MASShortcutView *nextShortcutView;

@end

@implementation BJSettingsWindowController

- (id)initWithWindow:(NSWindow *)window
{
  self = [super initWithWindow:window];
  if (self) {
    // Initialization code here.
  }
  return self;
}

- (void)windowDidLoad
{
  [super windowDidLoad];

  self.previousShortcutView.associatedUserDefaultsKey = kBlockJumpPreviousShortcutKey;
  self.nextShortcutView.associatedUserDefaultsKey = kBlockJumpNextShortcutKey;

  self.previousShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;
  self.nextShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;
}

- (void)windowWillClose:(NSNotification *)notification
{
  // Empty the UserDefaults key to stop observing.
  self.previousShortcutView.associatedUserDefaultsKey = nil;
  self.nextShortcutView.associatedUserDefaultsKey = nil;
}

@end
