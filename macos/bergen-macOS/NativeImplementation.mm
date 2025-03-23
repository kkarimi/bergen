#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

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

#pragma mark - NativeMenuModule Implementation

@interface NativeMenuModule : RCTEventEmitter <RCTBridgeModule>
@end

@implementation NativeMenuModule

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"menuItemSelected"];
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

@end