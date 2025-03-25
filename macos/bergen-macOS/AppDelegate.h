#import <RCTAppDelegate.h>
#import <Cocoa/Cocoa.h>
#import <os/log.h>

@class MenuManager;

/**
 * AppDelegate for the macOS application.
 * Handles application lifecycle and React Native integration.
 */
@interface AppDelegate : RCTAppDelegate <NSApplicationDelegate>

/**
 * Reference to the menu manager for handling native menu operations.
 */
@property (nonatomic, strong, readonly) MenuManager *menuManager;

/**
 * Handles the File -> Open menu action.
 * This is connected to the Open menu item in the storyboard.
 */
- (IBAction)openDocument:(id)sender;

/**
 * Called when React content has appeared and is ready to handle events.
 */
- (void)applicationDidFullyLaunch:(NSNotification *)notification;

@end
