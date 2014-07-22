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

static NSString * const kMenuItemTitle = @"Change BlockJump Shortcut";

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(menuDidChange:)
                                                 name:NSMenuDidChangeItemNotification
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

- (void)addMenuToHostMenu:(NSMenu *)hostMenu
{
  if (hostMenu) {
    [hostMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *blockJumpSettingMenu = [[NSMenuItem alloc] initWithTitle:kMenuItemTitle
                                                                  action:@selector(showSettingPanel)
                                                           keyEquivalent:@""];
    [blockJumpSettingMenu setTarget:self];
    [hostMenu addItem:blockJumpSettingMenu];
  }
}

- (void)showSettingPanel
{
  self.settingPanel = [[BJSettingsWindowController alloc] initWithWindowNibName:@"BJSettingsWindowController"];
  [self.settingPanel showWindow:self];
}


#pragma mark - Notification Observers

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  [self registerDefaultShortcut];
}

- (void)menuDidChange:(NSNotification *)nofication
{
  NSMenuItem *editorMenuItem = [[NSApp mainMenu] itemWithTitle:@"Editor"];
  if (editorMenuItem && ![editorMenuItem.submenu itemWithTitle:kMenuItemTitle]) {
    [self addMenuToHostMenu:editorMenuItem.submenu];
  }
}

@end
