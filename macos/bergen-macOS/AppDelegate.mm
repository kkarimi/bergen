#import "AppDelegate.h"
#import <React/RCTBundleURLProvider.h>

// Include the native implementation
#import "NativeImplementation.mm"

@interface AppDelegate ()
@property (nonatomic, strong, readwrite) MenuManager *menuManager;
@end

@implementation AppDelegate

/**
 * Called when the application finishes launching.
 * Sets up React Native configuration.
 *
 * @param notification The notification object.
 * @return The result of the superclass implementation.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  // Initialize the menu manager
  self.menuManager = [MenuManager sharedInstance];
  [self.menuManager setupApplicationMenu];
  
  // Set the React Native module name
  self.moduleName = @"bergen";
  
  // Set initial props for the React Native view
  // These will be passed down to the ViewController
  self.initialProps = @{};

  // Call the superclass implementation
  return [super applicationDidFinishLaunching:notification];
}

/**
 * Provides the URL for the JavaScript bundle.
 *
 * @param bridge The React Native bridge instance.
 * @return The URL to the JavaScript bundle.
 */
- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

/**
 * Returns the URL to the JavaScript bundle based on the build configuration.
 * In DEBUG mode, it uses the development server.
 * In RELEASE mode, it uses the pre-bundled file.
 *
 * @return The URL to the JavaScript bundle.
 */
- (NSURL *)bundleURL
{
#if DEBUG
  // In debug builds, use the React Native development server
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  // In release builds, use the pre-bundled JavaScript file
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

/**
 * Controls whether the `concurrentRoot` feature of React 18 is enabled.
 * This feature requires the app to be rendering on Fabric (New Architecture).
 *
 * @see: https://reactjs.org/blog/2022/03/29/react-v18.html
 * @return `true` if the `concurrentRoot` feature is enabled, `false` otherwise.
 */
- (BOOL)concurrentRootEnabled
{
#ifdef RN_FABRIC_ENABLED
  return true;
#else
  return false;
#endif
}

/**
 * Setup the application menu and ensure necessary menu items are functional.
 * This method is called automatically when the app launches.
 */
- (void)buildMenu
{
  // The standard menu items are already created from the storyboard
  // Here we're connecting the File -> Open menu item to our implementation
  
  NSMenu *mainMenu = [NSApp mainMenu];
  for (NSMenuItem *item in [mainMenu itemArray]) {
    if ([[item title] isEqualToString:@"File"]) {
      NSMenu *fileMenu = [item submenu];
      for (NSMenuItem *fileItem in [fileMenu itemArray]) {
        if ([[fileItem title] isEqualToString:@"Open…"] || 
            [[fileItem title] isEqualToString:@"Open"]) {
          fileItem.target = [NativeMenuModule sharedInstance];
          fileItem.action = @selector(handleOpenFileMenuAction);
          fileItem.enabled = YES;
        }
      }
      break;
    }
  }
}

@end
