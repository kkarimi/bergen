#import "AppDelegate.h"
#import <React/RCTBundleURLProvider.h>

// Forward declarations from NativeImplementation.mm
@class NativeMenuModule;
@class MenuManager;

// Include the native implementation
#import "NativeImplementation.mm"

// Define log categories for better organization in Console.app
os_log_t bergenAppLog;
os_log_t bergenFileLog;
os_log_t bergenMenuLog;

@interface AppDelegate ()
@property (nonatomic, strong, readwrite) MenuManager *menuManager;
@property (nonatomic, strong) NSArray<NSURL *> *pendingOpenFiles;
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
  // Initialize logging categories
  bergenAppLog = os_log_create("com.bergen.app", "app");
  bergenFileLog = os_log_create("com.bergen.app", "files");
  bergenMenuLog = os_log_create("com.bergen.app", "menu");
  
  os_log_info(bergenAppLog, "Application starting up");
  
  // Initialize the menu manager
  self.menuManager = [MenuManager sharedInstance];
  [self.menuManager setupApplicationMenu];
  
  // Set the React Native module name
  self.moduleName = @"bergen";
  
  // Set initial props for the React Native view
  // These will be passed down to the ViewController
  self.initialProps = @{};
  
  // Register for NSApplicationDelegate callbacks
  [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationWillFinishLaunching:)
                                              name:NSApplicationWillFinishLaunchingNotification
                                            object:nil];

  // Call the superclass implementation
  return [super applicationDidFinishLaunching:notification];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
  // Register as the default handler for markdown files
  NSArray *fileTypes = @[@"md", @"markdown"];
  [[NSDocumentController sharedDocumentController] setAutosavingDelay:60.0];
  
  // Register for the NSApplicationDidFinishLaunchingNotification
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidFullyLaunch:)
                                               name:@"RCTContentDidAppearNotification"
                                             object:nil];
  
  // Save any pending files for processing after React Native is fully loaded
  if (self.pendingOpenFiles.count > 0) {
    os_log_info(bergenFileLog, "Detected pending files to open later: %{public}@", self.pendingOpenFiles);
  }
}

/**
 * Called when the app is asked to open a file.
 * This is invoked when a user double-clicks a file in Finder or drags a file onto the app icon.
 *
 * @param sender The object that sent the action.
 * @param filename The path to the file to open.
 * @return YES if the file was successfully opened, NO otherwise.
 */
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
  os_log_info(bergenFileLog, "application:openFile: called with %{public}@", filename);
  
  // Always store the file path for later processing when React is ready
  if (!self.pendingOpenFiles) {
    self.pendingOpenFiles = @[[NSURL fileURLWithPath:filename]];
  } else {
    // Create a new array with the existing items plus the new one
    NSMutableArray *updatedFiles = [NSMutableArray arrayWithArray:self.pendingOpenFiles];
    [updatedFiles addObject:[NSURL fileURLWithPath:filename]];
    self.pendingOpenFiles = [updatedFiles copy];
  }
  
  // If React Native bridge is already initialized, try to open immediately
  if ([[NativeMenuModule sharedInstance] isBridgeReady]) {
    return [self openFile:filename];
  }
  
  // Return YES to indicate we'll handle this file later
  return YES;
}

/**
 * Helper method to open a file and notify the React Native code.
 *
 * @param filePath The path to the file to open.
 * @return YES if the file was successfully opened, NO otherwise.
 */
- (BOOL)openFile:(NSString *)filePath
{
  os_log_info(bergenFileLog, "Opening file: %{public}@", filePath);
  
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  // Check if the file exists
  if (![fileManager fileExistsAtPath:filePath]) {
    os_log_error(bergenFileLog, "File does not exist: %{public}@", filePath);
    return NO;
  }
  
  // Check if the file is readable
  if (![fileManager isReadableFileAtPath:filePath]) {
    os_log_error(bergenFileLog, "File is not readable: %{public}@", filePath);
    return NO;
  }
  
  // Send the file path to the React Native code
  NativeMenuModule *menuModule = [NativeMenuModule sharedInstance];
  
  // Wait a bit to ensure React Native is ready, then send the event
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    // Check if the bridge is ready before sending events
    if ([menuModule isBridgeReady]) {
      [menuModule sendEventWithName:@"fileMenuAction" body:@{
        @"action": @"fileSelected",
        @"path": filePath
      }];
      
      os_log_debug(bergenFileLog, "Sent fileSelected event for path: %{public}@", filePath);
      
      // Send again after a short delay as a fallback
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([menuModule isBridgeReady]) {
          [menuModule sendEventWithName:@"fileMenuAction" body:@{
            @"action": @"fileSelected",
            @"path": filePath
          }];
          os_log_debug(bergenFileLog, "Sent fileSelected event again (backup)");
        } else {
          os_log_error(bergenFileLog, "Cannot send backup event: bridge is not ready");
        }
      });
    } else {
      os_log_error(bergenFileLog, "Cannot send event: bridge is not ready");
    }
  });
  
  return YES;
}

/**
 * Handles the File -> Open menu action.
 * This method is called when the user selects File -> Open from the menu.
 *
 * @param sender The object that sent the action.
 */
- (IBAction)openDocument:(id)sender
{
  os_log_info(bergenMenuLog, "openDocument: called in AppDelegate");
  
  // Forward the open document action to the NativeMenuModule
  // This ensures that the React Native code will be notified
  [[NativeMenuModule sharedInstance] handleOpenFileMenuAction];
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
  // In debug builds, use the React Native development server with explicit localhost IP
  RCTBundleURLProvider *provider = [RCTBundleURLProvider sharedSettings];
  // Force localhost to 127.0.0.1 (explicit IP) for better connectivity
  [provider setJsLocation:@"127.0.0.1"];
  os_log_info(bergenAppLog, "Using Metro server at %{public}@", [provider jsLocation]);
  return [provider jsBundleURLForBundleRoot:@"index"];
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
  
  // Get the shared NativeMenuModule instance
  NativeMenuModule *menuModule = [NativeMenuModule sharedInstance];
  
  NSMenu *mainMenu = [NSApp mainMenu];
  os_log_debug(bergenMenuLog, "Main menu has %lu items", (unsigned long)[mainMenu numberOfItems]);
  
  for (NSMenuItem *item in [mainMenu itemArray]) {
    os_log_debug(bergenMenuLog, "Menu item: %{public}@", [item title]);
    
    // Handle File menu
    if ([[item title] isEqualToString:@"File"]) {
      NSMenu *fileMenu = [item submenu];
      os_log_debug(bergenMenuLog, "File menu has %lu items", (unsigned long)[fileMenu numberOfItems]);
      
      for (NSMenuItem *fileItem in [fileMenu itemArray]) {
        os_log_debug(bergenMenuLog, "File menu item: %{public}@, enabled: %d", [fileItem title], [fileItem isEnabled]);
        
        if ([[fileItem title] isEqualToString:@"Open…"] || 
            [[fileItem title] isEqualToString:@"Open"]) {
          os_log_info(bergenMenuLog, "Found Open menu item, connecting action");
          
          // Force enable the menu item and set its target and action
          [fileItem setEnabled:YES];
          [fileItem setTarget:menuModule];
          [fileItem setAction:@selector(handleOpenFileMenuAction)];
          
          // Set a tag to identify it
          [fileItem setTag:1001];
          
          os_log_debug(bergenMenuLog, "After setting: target exists: %{public}@, action: %{public}@, enabled: %d", 
                [fileItem target] ? @"YES" : @"NO",
                NSStringFromSelector([fileItem action]),
                [fileItem isEnabled]);
        }
      }
    } 
    // Handle View menu
    else if ([[item title] isEqualToString:@"View"]) {
      NSMenu *viewMenu = [item submenu];
      os_log_debug(bergenMenuLog, "View menu has %lu items", (unsigned long)[viewMenu numberOfItems]);
      
      // Add our own Show Sidebar item directly
      if ([viewMenu numberOfItems] > 0) {
        [viewMenu addItem:[NSMenuItem separatorItem]];
      }
      
      // Create and add a custom sidebar toggle menu item
      NSMenuItem *showSidebarItem = [[NSMenuItem alloc] initWithTitle:@"Show Sidebar" 
                                                        action:@selector(toggleSidebar:) 
                                                 keyEquivalent:@"S"];
      [showSidebarItem setKeyEquivalentModifierMask:(NSEventModifierFlagCommand | NSEventModifierFlagShift)];
      [showSidebarItem setTarget:menuModule];
      [showSidebarItem setEnabled:YES]; 
      [showSidebarItem setTag:1000]; 
      
      [viewMenu addItem:showSidebarItem];
      
      // Store a reference for later menu state updates
      [menuModule setSidebarMenuItem:showSidebarItem];
      
      os_log_info(bergenMenuLog, "Added Show Sidebar menu item with target: %{public}@", 
                  menuModule ? @"valid" : @"nil");
    }
  }
}

/**
 * Called when React content has appeared and is ready to handle events.
 * This notification is posted when React Native has fully loaded.
 */
- (void)applicationDidFullyLaunch:(NSNotification *)notification
{
  os_log_info(bergenAppLog, "React Native content has appeared, app is fully launched");
  
  // Handle any pending files that were passed during app launch
  if (self.pendingOpenFiles.count > 0) {
    os_log_info(bergenFileLog, "Processing %lu pending files to open", (unsigned long)self.pendingOpenFiles.count);
    NSURL *fileURL = [self.pendingOpenFiles firstObject];
    [self openFile:[fileURL path]];
    self.pendingOpenFiles = nil;
  }
}

/**
 * Clean up when the app is terminating.
 */
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
