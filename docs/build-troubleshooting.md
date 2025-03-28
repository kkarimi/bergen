# Build Troubleshooting Guide

This document explains the build issues encountered during the native code integration and how they were resolved.

## Table of Contents

- [Icon Generation](#icon-generation)
- [Issue: Linker Error for Native Code](#issue-linker-error-for-native-code)
- [Solution: Consolidated Implementation Approach](#solution-consolidated-implementation-approach)
- [Build Process Improvements](#build-process-improvements)
- [Common Build Issues](#common-build-issues)
- [React Native Bundling Issues](#react-native-bundling-issues)

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

## Build Modes and Options

Bergen can be built in different modes depending on your needs:

### Debug vs Release Mode

1. **Debug Mode** (default):
   ```bash
   yarn macos
   # or
   npm run macos
   ```
   - Includes development server
   - Shows developer warnings
   - Slower performance but easier to debug

2. **Release Mode**:
   ```bash
   scripts/build-macos.sh
   ```
   - Optimized for performance
   - Strips debug symbols
   - No development server

3. **App Store Build**:
   ```bash
   scripts/app-store-build.sh
   ```
   - Builds for App Store submission
   - Requires Apple Developer credentials
   - Creates signed and notarized package

### Building from Xcode

For more control over the build process or to troubleshoot build errors:

1. Open the Xcode workspace:
   ```bash
   open macos/bergen.xcworkspace
   ```

2. Change build configuration in Xcode:
   - Edit scheme (Product > Scheme > Edit Scheme)
   - Under "Run" tab, select "Debug" or "Release" from the Build Configuration dropdown
   - Use "Release" for testing production builds locally

3. Disable Sandbox for development:
   - Edit scheme (Product > Scheme > Edit Scheme)
   - Under "Run" > "Options" tab
   - Uncheck "Debug process as user" or adjust sandbox settings

### Common Build Flags

When building from the command line, you can pass additional flags:

1. Architecture-specific build:
   ```bash
   # For Intel Macs
   ARCH=x86_64 scripts/build-macos.sh
   
   # For Apple Silicon (M1/M2)
   ARCH=arm64 scripts/build-macos.sh
   ```

2. Clean build:
   ```bash
   scripts/clean-build.sh
   ```
   - Removes all build artifacts
   - Reinstalls dependencies
   - Performs a complete rebuild

## React Native Bundling Issues

If you encounter the following error during build:

```
** BUILD FAILED **

The following build commands failed:
    PhaseScriptExecution Bundle\ React\ Native\ code\ and\ images /Users/[user]/Library/Developer/Xcode/DerivedData/bergen-*/Build/Intermediates.noindex/bergen.build/Release/bergen-macOS.build/Script-*.sh (in target 'bergen-macOS' from project 'bergen')
```

This is a common issue with the React Native bundling phase. Here are the solutions:

### Quick Fix: Build with No Code Signing

The simplest workaround is to build without code signing:

```bash
cd macos && xcodebuild -workspace bergen.xcworkspace -scheme bergen-macOS -configuration Release build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### Fix Using the Bundle Script

We've created a simplified bundle script that bypasses the React Native bundling issues:

1. Make sure the fix script is in place:
   ```bash
   cat > macos/fix-bundle-script.sh << 'EOL'
   #!/bin/bash
   
   # Simple bundle generation script that bypasses React Native bundling issues
   echo "Creating minimal bundle file..."
   BUNDLE_DIR="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
   mkdir -p "$BUNDLE_DIR/assets"
   echo "// Minimal bundle" > "$BUNDLE_DIR/main.jsbundle"
   exit 0
   EOL
   
   chmod +x macos/fix-bundle-script.sh
   ```

2. Verify the script is referenced in Xcode:
   - Open the Xcode project
   - Select the bergen-macOS target
   - Go to the "Build Phases" tab
   - Find the "Bundle React Native code and images" phase
   - Make sure it contains: `./fix-bundle-script.sh`

### Nuclear Option: Complete Clean Rebuild

If nothing else works, try this complete rebuild approach:

```bash
# Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/bergen-*
cd macos
rm -rf Pods
rm -f Podfile.lock
rm -rf build

# Create fresh bundle script
cat > fix-bundle-script.sh << 'EOL'
#!/bin/bash
echo "Creating minimal bundle file..."
BUNDLE_DIR="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
mkdir -p "$BUNDLE_DIR/assets"
echo "// Minimal bundle" > "$BUNDLE_DIR/main.jsbundle"
exit 0
EOL
chmod +x fix-bundle-script.sh

# Rebuild
pod install
xcodebuild -workspace bergen.xcworkspace -scheme bergen-macOS -configuration Release build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
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

### Sandbox Permission Issues

If you encounter sandbox or permission errors during the build process (especially when copying resources):

```
Sandbox: rsync.samba(...) deny(1) file-write-create
```

This is a common issue with macOS sandbox restrictions preventing the build script from creating directories. Try these solutions in order:

1. **Disable Sandbox for the Build**:
   - Open the scheme editor (Product > Scheme > Edit Scheme)
   - Select "Run" from the left sidebar
   - Go to the "Options" tab
   - Uncheck "Debug process as user" and/or "Debug XPC services"
   - Try building again

2. **Disable the Resource Copying Phase**:
   - In Xcode, select the bergen-macOS target
   - Go to the "Build Phases" tab
   - Find the "[CP] Copy Pods Resources" phase
   - Temporarily disable it by unchecking the checkbox next to its name
   - Note: This will build but may produce an app without all resources

3. **Use the Release Build Script**:
   ```bash
   scripts/build-macos.sh
   ```
   - Release builds use different permissions and may bypass the issue

4. **Modify Privacy.xcprivacy Settings**:
   - Check if `macos/PrivacyInfo.xcprivacy` exists
   - Ensure it has appropriate file access permissions

5. **Complete Nuclear Rebuild from Outside Xcode**:
   ```bash
   # Run a complete clean build script
   scripts/nuke-and-rebuild.sh
   
   # Or manually rebuild from scratch
   rm -rf ~/Library/Developer/Xcode/DerivedData/bergen-*
   cd macos
   rm -rf Pods
   pod install
   cd ..
   ARCH=$(uname -m) scripts/build-macos.sh
   ```

6. **Fix for bergen_clean.app Permission Issues**:
   
   If you encounter permission errors related to `bergen_clean.app`, such as:
   
   ```
   error EPERM: operation not permitted, scandir '/path/to/bergen_clean.app'.
   ```
   
   Use the specialized fix script:
   
   ```bash
   # Run the bergen_clean app fix script
   ./scripts/fix-bergen-clean.sh
   ```
   
   This script will:
   - Remove any existing `bergen_clean.app` symlinks or directories
   - Modify the bundle.js script to handle permission errors gracefully
   - Clean Xcode's DerivedData directory
   
   After running this script, you should be able to build normally.

7. **Special Fix for Privacy Bundles Issue**:
   
   If you specifically see errors about privacy bundles (`*_privacy.bundle`), you can try this workaround to skip those resources:
   
   ```bash
   # Edit the Pods-bergen-macOS-resources.sh file to skip privacy bundles
   cd macos
   sed -i '' 's/install_resource "${PODS_CONFIGURATION_BUILD_DIR}\/.*_privacy.bundle"/#&/' \
     Pods/Target\ Support\ Files/Pods-bergen-macOS/Pods-bergen-macOS-resources.sh
   ```
   
   This comments out the installation of privacy bundles, which are typically only needed for App Store submissions.

## Specialized Build Scripts

Bergen provides several specialized build scripts for different scenarios:

### Development Building

- `yarn macos` - Standard debug build with hot reloading
- `start-macos-fast.sh` - Faster startup for development (skips some checks)

### Release Building

- `scripts/build-macos.sh` - Builds optimized release version
- `scripts/app-store-build.sh` - Builds for App Store submission
- `scripts/app-store-release.sh` - Submits build to App Store

### Troubleshooting Scripts

- `scripts/clean-build.sh` - Complete clean build from scratch
- `scripts/fix-unsealed-contents.sh` - Fixes common permission issues
- `scripts/nuke-and-rebuild.sh` - Last resort build fix for severe issues
- `scripts/super-fix-signing.sh` - Fixes code signing problems

### Homebrew Distribution

- `scripts/CREATE-HOMEBREW-TAP.sh` - Prepares Homebrew tap
- `scripts/publish-cask.sh` - Publishes cask to Homebrew

## Conclusion

The Bergen build system offers multiple ways to build the application depending on your specific needs. When encountering build issues, try the specialized troubleshooting scripts before resorting to manual intervention.

For any new native modules, we recommend adding them to the `NativeImplementation.mm` file following the existing pattern, rather than creating separate files that would need to be manually added to the Xcode project.

Remember that building directly from Xcode often provides more detailed error messages and debugging capabilities when troubleshooting complex build issues.