# Bergen Native Code Guide

This document provides an overview of the native macOS code in the Bergen React Native project. It explains the architecture, dependencies, and design decisions to help developers understand and extend the native functionality.

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Key Components](#key-components)
  - [AppDelegate](#appdelegate)
  - [Menu System](#menu-system)
  - [Native Modules](#native-modules)
- [Adding New Native Functionality](#adding-new-native-functionality)
- [Building and Debugging](#building-and-debugging)
- [Common Issues](#common-issues)

## Overview

The Bergen app uses React Native for macOS (RN macOS) to provide a cross-platform experience while leveraging native capabilities when needed. The native code is written in Objective-C/Objective-C++ and follows Apple's Cocoa framework patterns.

The architecture is designed to:
- Separate concerns between the UI (React Native) and platform-specific features
- Provide clean interfaces between JavaScript and native code
- Enable easy extension with new native functionality
- Follow macOS app development best practices

## Directory Structure

The main native code is located in the `/macos` directory:

```
/macos
├── Podfile                     # CocoaPods dependency management
├── bergen-macos/               # Main application code
│   ├── AppDelegate.h           # App initialization and lifecycle
│   ├── AppDelegate.mm          # Implementation of app delegate
│   ├── main.m                  # App entry point
│   ├── NativeImplementation.mm # Combined native module implementations
│   ├── Info.plist              # App configuration
│   ├── bergen.entitlements     # App permissions
│   └── Base.lproj/             # Storyboards and UI resources
│       └── Main.storyboard     # Main UI layout including menus
├── bergen.xcodeproj/           # Xcode project configuration
└── bergen.xcworkspace/         # Xcode workspace
```

> **Note on Implementation Approach**: To avoid Xcode project file modifications and simplify the build process, the MenuManager and NativeMenuModule implementations are combined in the single `NativeImplementation.mm` file, which is directly imported by the AppDelegate.

## Key Components

### AppDelegate

The `AppDelegate` class is the entry point for the macOS application and handles:

- Application lifecycle events (launch, terminate, etc.)
- React Native bridge setup
- Menu system initialization
- Window management

The `AppDelegate` extends `RCTAppDelegate` from React Native, which provides most of the React Native integration automatically.

Key methods:
- `applicationDidFinishLaunching:` - Sets up the app when it launches
- `sourceURLForBridge:` - Provides the URL for the JavaScript bundle
- `bundleURL` - Returns the URL based on debug/release mode
- `concurrentRootEnabled` - Controls React 18 concurrent features
- `buildMenu` - Sets up the application menu and wires up menu item actions

### Menu System

The native menu system consists of:

1. **Main.storyboard** - Contains the default menu structure including:
   - Application menu (bergen)
   - File menu
   - Edit menu
   - View menu
   - Window menu
   - Help menu

2. **MenuManager** - Singleton class that manages menus programmatically

3. **NativeMenuModule** - Handles menu actions and bridges to React Native

The menu includes important functionality:
- File -> Open (⌘O): Opens a native file picker dialog to select markdown files
- File -> Quit (⌘Q): Quits the application
- Application menu -> Quit bergen (⌘Q): Alternative quit option

### Native Modules

The application implements several native modules to bridge between React Native and macOS:

#### MenuManager

The `MenuManager` class provides a programmatic interface to the menu system:

```objc
// Get the shared instance
MenuManager *menuManager = [MenuManager sharedInstance];

// Add a menu item to a specific menu
[menuManager createMenuItemWithTitle:@"Custom Action" 
                             action:@selector(customAction:) 
                      keyEquivalent:@"c" 
                          menuTitle:@"File"];
```

This design separates menu management from the AppDelegate, making it easier to maintain and extend.

The project includes the following native modules:

#### NativeMenuModule

Allows JavaScript code to interact with the native menu system:

- Exposes methods to add/modify menu items
- Sends events to JavaScript when menu items are selected
- Handles File -> Open menu action via native file picker
- Maintains a shared instance for access from AppDelegate
- Runs on the main thread for UI operations

Example JavaScript usage:
```javascript
import { NativeModules, NativeEventEmitter } from 'react-native';

const { NativeMenuModule } = NativeModules;
const menuEmitter = new NativeEventEmitter(NativeMenuModule);

// Add a menu item
NativeMenuModule.addMenuItem('Custom Action', 'File', 'c', 'custom_action');

// Listen for menu selections
menuEmitter.addListener('menuItemSelected', (event) => {
  if (event.identifier === 'custom_action') {
    // Handle the menu action
  }
});
```

#### FileManagerModule

Provides native file picker functionality:

- Exposes a `showOpenDialog` method that returns a Promise with the selected file path
- Configures the dialog to filter for markdown files only
- Runs on the main thread for UI operations

Example JavaScript usage:
```javascript
import { NativeModules } from 'react-native';

const { FileManagerModule } = NativeModules;

async function openMarkdownFile() {
  try {
    const filePath = await FileManagerModule.showOpenDialog();
    if (filePath) {
      // Handle the selected file
      console.log('Selected file:', filePath);
    }
  } catch (error) {
    console.error('Failed to open file dialog:', error);
  }
}
```

## Adding New Native Functionality

To add new native functionality to the app:

1. **Determine the appropriate pattern**:
   - **Native Module**: For features that need to be called from JavaScript
   - **Native UI Component**: For custom UI elements
   - **App Extension**: For system-level integration

2. **Create the necessary files**:
   - Header (.h) and implementation (.m/.mm) files
   - Add to the Xcode project

3. **Bridge to React Native** (if needed):
   - Create a native module class extending `RCTEventEmitter` and implementing `RCTBridgeModule`
   - Export methods using `RCT_EXPORT_METHOD`
   - Send events using `sendEventWithName:body:`

4. **Update documentation** in this guide

### Example: Adding System Notifications

```objc
// NotificationManager.h
@interface NotificationManager : NSObject
+ (instancetype)sharedInstance;
- (void)showNotification:(NSString *)title body:(NSString *)body;
@end

// NotificationModule.h
@interface NotificationModule : RCTEventEmitter <RCTBridgeModule>
@end

// NotificationModule.m
RCT_EXPORT_METHOD(showNotification:(NSString *)title body:(NSString *)body)
{
  [[NotificationManager sharedInstance] showNotification:title body:body];
}
```

## Building and Debugging

### Building
Build the macOS app using:

```bash
# Install dependencies
yarn install

# Run for development
yarn macos

# Build for production
./build-macos.sh
```

### Debugging Native Code

1. **Xcode Debugging**:
   - Open `macos/bergen.xcworkspace` in Xcode
   - Set breakpoints in native code
   - Run the app from Xcode

2. **Logging**:
   - Use `NSLog(@"message")` for simple logging
   - For React Native bridge logging, use `RCTLogInfo(@"message")`

3. **Common Debug Tools**:
   - Xcode's Debug Navigator
   - Console.app for system logs
   - Instruments for performance analysis

## Common Issues

### React Native Module Not Found

If JavaScript cannot find your native module:

1. Check the module is properly registered with `RCT_EXPORT_MODULE()`
2. Restart the Metro bundler and app
3. Verify the module name matches between native and JS code

### Menu Items Not Appearing

If custom menu items don't appear:

1. Verify the menu title exactly matches the existing menu (case-sensitive)
2. Check that code is running on the main thread
3. Inspect the menu structure using the Menu Editor in Xcode

### Build Failures

Common build issues:

1. **Missing dependencies**: Run `pod install` in the `macos` directory
2. **Linking errors**: Ensure all native code is included in the Xcode project
3. **React Native version mismatch**: Check compatibility with the RN macOS version

## Future Considerations

As the project evolves, consider:

1. **Mac Catalyst** support for shared iOS/macOS code
2. **SwiftUI** integration for modern UI components
3. **Apple Silicon** optimizations
4. **Sandboxing** for Mac App Store distribution

---

This documentation will be updated as the native codebase evolves. Contributions to this guide are welcome.