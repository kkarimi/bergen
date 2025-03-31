#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTUtils.h>
#import <os/log.h>

// Define log categories for better organization in Console.app
extern os_log_t bergenAppLog;
extern os_log_t bergenFileLog;
extern os_log_t bergenMenuLog;

#pragma mark - NativeMenuModule Declaration

@interface NativeMenuModule : RCTEventEmitter <RCTBridgeModule, NSMenuItemValidation>
+ (instancetype)sharedInstance;
- (void)handleOpenFileMenuAction;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (void)toggleSidebar:(id)sender;
- (void)setSidebarMenuItem:(NSMenuItem *)menuItem;
- (void)updateSidebarMenuState:(BOOL)isCollapsed;
- (BOOL)isBridgeReady;

@property (nonatomic, weak) NSMenuItem *sidebarMenuItem;
@property (nonatomic, assign) BOOL isSidebarCollapsed;
@end

#pragma mark - MenuManager Implementation

@interface MenuManager : NSObject

+ (instancetype)sharedInstance;
- (void)setupApplicationMenu;
- (nullable NSMenuItem *)createMenuItemWithTitle:(NSString *)title
                                        action:(SEL)action
                                 keyEquivalent:(NSString *)keyEquivalent
                                     menuTitle:(NSString *)menuTitle;

@end

@implementation MenuManager

+ (instancetype)sharedInstance
{
  static MenuManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  
  return sharedInstance;
}

- (void)setupApplicationMenu
{
  // The main menu is already created from the storyboard
  // Dynamic menu items are now added in AppDelegate's buildMenu method
  os_log_info(bergenMenuLog, "MenuManager setupApplicationMenu - menu setup delegated to AppDelegate");
}

- (nullable NSMenuItem *)createMenuItemWithTitle:(NSString *)title
                                        action:(SEL)action
                                 keyEquivalent:(NSString *)keyEquivalent
                                     menuTitle:(NSString *)menuTitle
{
  // Find the specified menu in the main menu bar
  NSMenu *mainMenu = [NSApp mainMenu];
  NSMenuItem *menuItem = nil;
  
  for (NSMenuItem *item in [mainMenu itemArray]) {
    if ([[item title] isEqualToString:menuTitle]) {
      // Create and configure the new menu item
      menuItem = [[NSMenuItem alloc] initWithTitle:title
                                          action:action
                                   keyEquivalent:keyEquivalent];
      
      // Add the item to the submenu
      [[item submenu] addItem:menuItem];
      break;
    }
  }
  
  return menuItem;
}

@end

#pragma mark - FileManager Declaration

@interface FileManagerModule : RCTEventEmitter <RCTBridgeModule, NSOpenSavePanelDelegate>
@end

#pragma mark - NativeMenuModule Implementation

// Static shared instance for menu actions
static NativeMenuModule *sharedMenuModuleInstance = nil;

@implementation NativeMenuModule

+ (instancetype)sharedInstance
{
  // Create an instance if it doesn't exist yet
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (!sharedMenuModuleInstance) {
      sharedMenuModuleInstance = [[NativeMenuModule alloc] init];
      os_log_info(bergenMenuLog, "Created NativeMenuModule singleton instance");
    }
  });
  
  return sharedMenuModuleInstance;
}

RCT_EXPORT_MODULE();

- (instancetype)init
{
  self = [super init];
  if (self) {
    sharedMenuModuleInstance = self;
    _isSidebarCollapsed = YES; // Default state: sidebar is collapsed
  }
  return self;
}

// Initialize the RCTBridge when module is initialized by React Native
- (void)setBridge:(RCTBridge *)bridge
{
  [super setBridge:bridge];
}

- (BOOL)isBridgeReady
{
  return self.bridge != nil && [self.bridge isValid];
}

- (void)setSidebarMenuItem:(NSMenuItem *)menuItem
{
  os_log_info(bergenMenuLog, "Setting sidebar menu item reference");
  _sidebarMenuItem = menuItem;
  
  // Update the initial menu state
  [self updateSidebarMenuState:_isSidebarCollapsed];
}

- (void)updateSidebarMenuState:(BOOL)isCollapsed
{
  os_log_info(bergenMenuLog, "Updating sidebar menu state: isCollapsed=%d", isCollapsed);
  _isSidebarCollapsed = isCollapsed;
  
  // Update the menu item title based on the current state
  if (_sidebarMenuItem) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (isCollapsed) {
        [self->_sidebarMenuItem setTitle:@"Show Sidebar"];
      } else {
        [self->_sidebarMenuItem setTitle:@"Hide Sidebar"];
      }
      [self->_sidebarMenuItem setEnabled:YES];
    });
  } else {
    os_log_error(bergenMenuLog, "Sidebar menu item reference is nil");
  }
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"menuItemSelected", @"fileMenuAction", @"viewMenuAction"];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

RCT_EXPORT_METHOD(addMenuItem:(NSString *)title
                  menuName:(NSString *)menuName
                  keyEquivalent:(NSString *)keyEquivalent
                  identifier:(NSString *)identifier)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    SEL action = @selector(menuItemSelected:);
    MenuManager *menuManager = [MenuManager sharedInstance];
    
    NSMenuItem *menuItem = [menuManager createMenuItemWithTitle:title
                                                      action:action
                                               keyEquivalent:keyEquivalent
                                                   menuTitle:menuName];
    
    if (menuItem) {
      menuItem.target = self;
      menuItem.representedObject = identifier;
    }
  });
}

// Allow React Native to update the sidebar menu state
RCT_EXPORT_METHOD(updateSidebarState:(BOOL)isCollapsed)
{
  os_log_info(bergenMenuLog, "RN called updateSidebarState: %d", isCollapsed);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self updateSidebarMenuState:isCollapsed];
  });
}

- (void)menuItemSelected:(NSMenuItem *)sender
{
  NSString *identifier = sender.representedObject;
  if (identifier) {
    [self sendEventWithName:@"menuItemSelected" body:@{@"identifier": identifier}];
  }
}

// Handle File -> Open menu action
// Implement NSMenuItemValidation protocol to enable menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  // Always enable all menu items, regardless of what they are
  os_log_info(bergenMenuLog, "🔍 MENU VALIDATION: title=%{public}@, action=%{public}@, tag=%ld, enabled=%d", 
              [menuItem title], 
              NSStringFromSelector([menuItem action]),
              (long)[menuItem tag],
              [menuItem isEnabled]);
  
  // Force enable the menu item
  [menuItem setEnabled:YES];
  
  return YES;
}

- (void)toggleSidebar:(id)sender
{
  os_log_info(bergenMenuLog, "View -> Show Sidebar menu action triggered");
  
  // Toggle the current sidebar state
  _isSidebarCollapsed = !_isSidebarCollapsed;
  
  // Update the menu item directly - no need to call updateSidebarMenuState
  NSMenuItem *menuItem = (NSMenuItem *)sender;
  if (menuItem) {
    if (_isSidebarCollapsed) {
      [menuItem setTitle:@"Show Sidebar"];
    } else {
      [menuItem setTitle:@"Hide Sidebar"];
    }
    // Force enable the menu item
    [menuItem setEnabled:YES];
  } else {
    os_log_error(bergenMenuLog, "toggleSidebar: sender is not a valid NSMenuItem");
  }
  
  // Check if bridge is ready before sending events
  if (![self isBridgeReady]) {
    os_log_error(bergenMenuLog, "Cannot send event: bridge is not ready");
    return;
  }
  
  // Send an event to JavaScript to notify it to toggle the sidebar
  // Note: in this context, show=YES means sidebar visible (!isCollapsed)
  [self sendEventWithName:@"viewMenuAction" body:@{
    @"action": @"toggleSidebar",
    @"show": @(!_isSidebarCollapsed)
  }];
}

- (void)handleOpenFileMenuAction
{
  os_log_info(bergenMenuLog, "File -> Open menu action triggered");
  
  // Check if bridge is ready before sending events
  if (![self isBridgeReady]) {
    os_log_error(bergenMenuLog, "Cannot send event: bridge is not ready");
    return;
  }
  
  // Send an event to JavaScript to notify the File -> Open menu was clicked
  [self sendEventWithName:@"fileMenuAction" body:@{@"action": @"openFile"}];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"md", @"markdown"];
    panel.title = @"Open Markdown File";
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
      if (result == NSModalResponseOK) {
        NSURL *fileURL = panel.URLs.firstObject;
        if (fileURL) {
          NSString *filePath = [fileURL path];
          os_log_info(bergenFileLog, "Selected file: %{public}@", filePath);
          
          // Wait a bit to ensure React Native is ready to receive the event
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Check if bridge is ready before sending events
            if ([self isBridgeReady]) {
              // Try to send the event a few times to ensure it's received
              [self sendEventWithName:@"fileMenuAction" body:@{
                @"action": @"fileSelected",
                @"path": filePath
              }];
              
              os_log_debug(bergenFileLog, "Sent fileSelected event for path: %{public}@", filePath);
              
              // Send again after a short delay as a fallback
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self isBridgeReady]) {
                  [self sendEventWithName:@"fileMenuAction" body:@{
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
        }
      }
    }];
  });
}

@end

#pragma mark - FileManager Implementation

@implementation FileManagerModule

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"fileSelected"];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

// Initialize the RCTBridge when module is initialized by React Native
- (void)setBridge:(RCTBridge *)bridge
{
  [super setBridge:bridge];
}

RCT_EXPORT_METHOD(showOpenDialog:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"md", @"markdown"];
    panel.title = @"Open Markdown File";
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
      if (result == NSModalResponseOK) {
        NSURL *fileURL = panel.URLs.firstObject;
        if (fileURL) {
          NSString *filePath = [fileURL path];
          resolve(filePath);
        } else {
          resolve(nil);
        }
      } else {
        resolve(nil);
      }
    }];
  });
}

@end