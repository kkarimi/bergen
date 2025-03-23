#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTUtils.h>

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
  // This method can be extended to add dynamic menu items at runtime
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

@interface NativeMenuModule : RCTEventEmitter <RCTBridgeModule>
+ (instancetype)sharedInstance;
- (void)handleOpenFileMenuAction;
@end

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
  return @[@"menuItemSelected", @"fileMenuAction"];
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
- (void)handleOpenFileMenuAction
{
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
          [self sendEventWithName:@"fileMenuAction" body:@{
            @"action": @"fileSelected",
            @"path": filePath
          }];
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