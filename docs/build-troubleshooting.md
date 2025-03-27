# Build Troubleshooting Guide

This document explains the build issues encountered during the native code integration and how they were resolved.

## Table of Contents

- [Icon Generation](#icon-generation)
- [Issue: Linker Error for Native Code](#issue-linker-error-for-native-code)
- [Solution: Consolidated Implementation Approach](#solution-consolidated-implementation-approach)
- [Build Process Improvements](#build-process-improvements)
- [Common Build Issues](#common-build-issues)

## Icon Generation

If you need to update the app icons:

1. Place your source icon (PNG format, minimum 1024x1024 pixels) in the `assets/` directory
2. Run the icon generation script:
   ```bash
   ./generate-icons.sh [path_to_your_icon.png]
   ```
   If no path is provided, it will use `./assets/newicon.png` by default.
3. The script will:
   - Generate all required icon sizes for macOS
   - Place them in the correct AppIcon.appiconset directory
   - Update the README.md reference if needed

## Issue: Linker Error for Native Code

### Initial Error

When attempting to build the app after adding the native menu functionality, the following linker error occurred:

```
ld: warning: ignoring duplicate libraries: '-lc++'
ld: warning: Could not find or use auto-linked framework 'CoreAudioTypes': framework 'CoreAudioTypes' not found
Undefined symbols for architecture arm64:
  "_OBJC_CLASS_$_MenuManager", referenced from:
       in AppDelegate.o
ld: symbol(s) not found for architecture arm64
clang++: error: linker command failed with exit code 1 (use -v to see invocation)
```

### Root Cause

The build error occurred because:

1. The new Objective-C files (`MenuManager.h/m` and `NativeMenuModule.h/m`) were created but not properly added to the Xcode project.
2. The AppDelegate referenced these classes, but the linker couldn't find the compiled implementations.
3. Modifying the Xcode project file directly to add new source files is complex and error-prone.

## Solution: Consolidated Implementation Approach

To solve the build issues, we implemented a simpler approach that doesn't require modifying the Xcode project structure:

### 1. Consolidated Implementation File

We created a single file `NativeImplementation.mm` containing all the native module code:

```objc
// NativeImplementation.mm
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#pragma mark - MenuManager Implementation
@interface MenuManager : NSObject
// MenuManager interface declaration
@end

@implementation MenuManager
// MenuManager implementation
@end

#pragma mark - NativeMenuModule Implementation
@interface NativeMenuModule : RCTEventEmitter <RCTBridgeModule>
@end

@implementation NativeMenuModule
// NativeMenuModule implementation
@end
```

### 2. Direct Include in AppDelegate

Instead of relying on the build system to link separate files, we directly included the implementation file in the AppDelegate:

```objc
// AppDelegate.mm
#import "AppDelegate.h"
#import <React/RCTBundleURLProvider.h>

// Include the native implementation
#import "NativeImplementation.mm"

@interface AppDelegate ()
@property (nonatomic, strong, readwrite) MenuManager *menuManager;
@end
```

### 3. Forward Declaration in Header

In the AppDelegate header, we used a forward declaration instead of directly importing the MenuManager header:

```objc
// AppDelegate.h
#import <RCTAppDelegate.h>
#import <Cocoa/Cocoa.h>

@class MenuManager;

@interface AppDelegate : RCTAppDelegate
@property (nonatomic, strong, readonly) MenuManager *menuManager;
@end
```

## Build Process Improvements

To avoid similar issues in the future:

### Documentation Updates

We updated the documentation to reflect the consolidated implementation approach:

1. Updated `native-code-guide.md` to explain the file structure and implementation approach
2. Updated `native-module-guide.md` to recommend adding new native modules to the `NativeImplementation.mm` file

### Clean Build Process

When encountering build issues:

1. Clean the build directory:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/bergen*
   ```
   
2. Reinstall dependencies:
   ```bash
   cd macos && rm -rf Pods && pod install
   ```

3. Build the app:
   ```bash
   yarn macos
   ```

## Common Build Issues

### Menu Items Disabled or Not Working

If menu items in the native macOS menu bar appear disabled (greyed out) even though they should be enabled:

1. **Implement NSMenuItemValidation Protocol**: The target of the menu item should implement the `NSMenuItemValidation` protocol with the `validateMenuItem:` method:

```objc
@interface YourClass : NSObject <NSMenuItemValidation>
@end

@implementation YourClass
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  // Return YES to enable the menu item
  return YES;
}
@end
```

2. **Use IBAction in AppDelegate**: Create a direct connection from the storyboard to the AppDelegate:

```objc
// In AppDelegate.h
- (IBAction)openDocument:(id)sender;

// In AppDelegate.mm
- (IBAction)openDocument:(id)sender)
{
  // Handling code here
}
```

3. **Ensure Proper Target Assignment**: Make sure the target is correctly set and not being overridden:

```objc
// Set target and enable the menu item
[menuItem setTarget:targetObject];
[menuItem setAction:@selector(yourAction:)];
[menuItem setEnabled:YES];
```

4. **Debug Menu Connections**: Add logging to verify menu items and their enabled state:

```objc
NSLog(@"Menu item: %@, enabled: %d, target exists: %@", 
      [menuItem title], 
      [menuItem isEnabled],
      [menuItem target] ? @"YES" : @"NO");
```

### Locked Database

If you encounter a build error like:

```
error: unable to attach DB: error: accessing build database "/path/to/build.db": database is locked
```

This usually means there's another build process running. Solutions:

1. Stop other running build processes
2. Delete the DerivedData folder and rebuild
3. Restart Xcode and Terminal

### Missing Files

If you encounter "file not found" errors:

1. Make sure all required files are in the correct location
2. Check import statements for typos
3. Consider using the consolidated implementation approach described above

### Pods Issues

If there are issues with CocoaPods:

1. Clean and reinstall pods:
   ```bash
   cd macos
   rm -rf Pods
   pod install
   ```

2. Update pods repository:
   ```bash
   pod repo update
   ```

## Conclusion

The build issues were resolved by using a consolidated implementation approach that avoids the need to modify the Xcode project file directly. This approach is simpler and more robust, especially for adding new native functionality in the future.

For any new native modules, we recommend adding them to the `NativeImplementation.mm` file following the existing pattern, rather than creating separate files that would need to be manually added to the Xcode project.