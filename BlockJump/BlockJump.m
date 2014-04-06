//
//  BlockJumpPlugIn.m
//  BlockJump
//
//  Created by Yin Tan on 4/6/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import "BlockJump.h"
#import "BJSettingsWindowController.h"

@interface BlockJump ()

@property (nonatomic, strong) BJSettingsWindowController *settingPanel;

@end

@implementation BlockJump

+ (void)pluginDidLoad:(NSBundle *)plugin
{
  static dispatch_once_t once;
  static id instance = nil;
  dispatch_once(&once, ^{
    instance = [[self alloc] init];
  });
}

- (instancetype)init
{
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:NSApplicationDidFinishLaunchingNotification
                                               object:nil];
  }
  return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  [self addMenu];
}

- (void)addMenu
{
  NSMenuItem *naviItem = [[NSApp mainMenu] itemWithTitle:@"View"];
  if (naviItem) {
    [[naviItem submenu] addItem:[NSMenuItem separatorItem]];

    NSString *title = @"BlockJump shortcut setting";
    NSMenuItem *blockJumpSettingMenu = [[NSMenuItem alloc] initWithTitle:title
                                                                  action:@selector(showSettingPanel)
                                                           keyEquivalent:@""];
    [blockJumpSettingMenu setTarget:self];
    [[naviItem submenu] addItem:blockJumpSettingMenu];
  }
}

- (void)showSettingPanel
{
  self.settingPanel = [[BJSettingsWindowController alloc] initWithWindowNibName:@"BJSettingsWindowController"];
  [self.settingPanel showWindow:self];
}

@end
