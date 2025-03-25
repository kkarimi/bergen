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
@property (nonatomic, readonly) RCTBridge *bridge;
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
  // Add dynamic menu items at runtime
  
  // Find the View menu
  NSMenu *mainMenu = [NSApp mainMenu];
  for (NSMenuItem *menuItem in [mainMenu itemArray]) {
    if ([[menuItem title] isEqualToString:@"View"]) {
      // Create a separator if the menu already has items
      NSMenu *viewMenu = [menuItem submenu];
      if ([viewMenu numberOfItems] > 0) {
        [viewMenu addItem:[NSMenuItem separatorItem]];
      }
      
      // Add the "Show Sidebar" menu item
      NSMenuItem *showSidebarItem = [[NSMenuItem alloc] initWithTitle:@"Show Sidebar" 
                                                           action:@selector(toggleSidebar:) 
                                                    keyEquivalent:@"S"];
      [showSidebarItem setKeyEquivalentModifierMask:(NSEventModifierFlagCommand | NSEventModifierFlagShift)];
      [showSidebarItem setTarget:[NativeMenuModule sharedInstance]];
      [viewMenu addItem:showSidebarItem];
      break;
    }
  }
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
  return sharedMenuModuleInstance;
}

RCT_EXPORT_MODULE();

- (instancetype)init
{
  self = [super init];
  if (self) {
    sharedMenuModuleInstance = self;
  }
  return self;
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
  // Always enable menu items that target this module
  return YES;
}

- (void)toggleSidebar:(id)sender
{
  os_log_info(bergenMenuLog, "View -> Show Sidebar menu action triggered");
  
  // Toggle the menu item title between "Show Sidebar" and "Hide Sidebar"
  NSMenuItem *menuItem = (NSMenuItem *)sender;
  BOOL isCurrentlyShowing = [[menuItem title] isEqualToString:@"Hide Sidebar"];
  
  if (isCurrentlyShowing) {
    [menuItem setTitle:@"Show Sidebar"];
  } else {
    [menuItem setTitle:@"Hide Sidebar"];
  }
  
  // Send an event to JavaScript to notify it to toggle the sidebar
  [self sendEventWithName:@"viewMenuAction" body:@{
    @"action": @"toggleSidebar",
    @"show": @(!isCurrentlyShowing)
  }];
}

- (void)handleOpenFileMenuAction
{
  os_log_info(bergenMenuLog, "File -> Open menu action triggered");
  
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
            // Try to send the event a few times to ensure it's received
            [self sendEventWithName:@"fileMenuAction" body:@{
              @"action": @"fileSelected",
              @"path": filePath
            }];
            
            os_log_debug(bergenFileLog, "Sent fileSelected event for path: %{public}@", filePath);
            
            // Send again after a short delay as a fallback
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
              [self sendEventWithName:@"fileMenuAction" body:@{
                @"action": @"fileSelected",
                @"path": filePath
              }];
              os_log_debug(bergenFileLog, "Sent fileSelected event again (backup)");
            });
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