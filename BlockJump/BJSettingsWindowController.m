//
//  BJSettingsWindowController.m
//  BlockJump
//
//  Created by Yin Tan on 4/6/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import "BJSettingsWindowController.h"
#import "MASShortcutView.h"
#import "MASShortcut+UserDefaults.h"

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

  // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
  self.previousShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;
  self.nextShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;
}

@end
