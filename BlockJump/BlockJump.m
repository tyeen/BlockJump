//
//  BlockJumpPlugIn.m
//  BlockJump
//
//  Created by Yin Tan on 4/6/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import "Constants.h"
#import "BlockJump.h"
#import "BJSettingsWindowController.h"
#import "MASShortcut+UserDefaults.h"

#define KEY_CODE_LEFT_SQUARE_BRACKET 0x21
#define KEY_CODE_RIGHT_SQUARE_BRACKET 0x1e

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

- (void)registerDefaultShortcut
{
  MASShortcut *defaultJumpPrevShortcut = [[MASShortcut alloc] initWithKeyCode:KEY_CODE_LEFT_SQUARE_BRACKET
                                                                modifierFlags:NSControlKeyMask];
  MASShortcut *defaultJumpNextShortcut = [[MASShortcut alloc] initWithKeyCode:KEY_CODE_RIGHT_SQUARE_BRACKET
                                                                modifierFlags:NSControlKeyMask];
  NSDictionary *defaultJumpPrevValues = @{kBlockJumpPreviousShortcutKey: defaultJumpPrevShortcut.data};
  NSDictionary *defaultJumpNextValues = @{kBlockJumpNextShortcutKey: defaultJumpNextShortcut.data};
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults registerDefaults:defaultJumpPrevValues];
  [userDefaults registerDefaults:defaultJumpNextValues];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  [self registerDefaultShortcut];
  [self addMenu];
}

- (void)addMenu
{
  NSMenuItem *naviItem = [[NSApp mainMenu] itemWithTitle:@"View"];
  if (naviItem) {
    [[naviItem submenu] addItem:[NSMenuItem separatorItem]];

    NSString *title = @"Change BlockJump Shortcut";
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
