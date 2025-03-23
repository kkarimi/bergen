#import <RCTAppDelegate.h>
#import <Cocoa/Cocoa.h>

@class MenuManager;

/**
 * AppDelegate for the macOS application.
 * Handles application lifecycle and React Native integration.
 */
@interface AppDelegate : RCTAppDelegate

/**
 * Reference to the menu manager for handling native menu operations.
 */
@property (nonatomic, strong, readonly) MenuManager *menuManager;

@end
