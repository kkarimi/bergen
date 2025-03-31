# Bergen Troubleshooting Guide

This document covers common issues and their solutions when developing or using the Bergen Markdown reader application.

## React Native to Native Communication Issues

### File Selection Not Updating UI

If selecting a file through the native File -> Open menu doesn't update the UI:

1. **Use Console.app for Structured Logging**: View native logs in Console.app by filtering for Bergen's subsystem:

```
subsystem:com.bergen.app category:files
```

This will show you all file-related operations logged with os_log. Check for errors or unexpected behavior in the native file handling code.

2. **Add JavaScript Debugging Logs**: Add console.log statements to track the flow of events:

```javascript
// In your event listener
console.log('Received file menu action:', event);

// In your file handling function
console.log('handleSelectedFile called with:', filePath);
console.log('File content loaded, length:', content.length);
```

3. **Delay Native Events**: Sometimes events from native to React Native can be missed. Add a delay and send multiple events:

```objc
// Send event with a delay to ensure React Native is ready
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
```

4. **Use Component State Properly**: Ensure your React component correctly handles state updates:

```javascript
// Use more specific condition to render content
{selectedFile && fileContent ? (
  <MarkdownRenderer content={fileContent} />
) : (
  <NoFileSelectedView />
)}
```

5. **Prevent Initialization Overwrites**: Make sure initialization logic doesn't overwrite user-selected content:

```javascript
// Skip initialization if content is already loaded
useEffect(() => {
  if (selectedFile && fileContent) {
    return;
  }
  
  // Initialization logic here...
}, [currentPath, selectedFile, fileContent]);
```

## Native UI Issues

### Menu Items Disabled or Not Working

If menu items in the native macOS menu bar appear disabled (greyed out):

1. **Implement NSMenuItemValidation Protocol**:

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

2. **Use IBAction in AppDelegate**:

```objc
// In AppDelegate.h
- (IBAction)openDocument:(id)sender;

// In AppDelegate.mm
- (IBAction)openDocument:(id)sender
{
  // Handle the menu action
}
```

3. **Explicitly Enable Menu Items**:

```objc
[menuItem setEnabled:YES];
[menuItem setTarget:targetObject];
[menuItem setAction:@selector(yourAction:)];
```

### Cannot Open Files from Finder

If you encounter "The document could not be opened. bergen cannot open files in the 'Markdown Text' format" when trying to open files from Finder:

1. **Check Info.plist Document Types Configuration**:
   
   The app needs proper document type declarations in the Info.plist file:

   ```xml
   <key>CFBundleDocumentTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeExtensions</key>
       <array>
         <string>md</string>
         <string>markdown</string>
       </array>
       <key>CFBundleTypeName</key>
       <string>Markdown Text</string>
       <key>CFBundleTypeRole</key>
       <string>Viewer</string>
       <key>LSHandlerRank</key>
       <string>Alternate</string>
       <key>LSItemContentTypes</key>
       <array>
         <string>net.daringfireball.markdown</string>
         <string>public.text</string>
       </array>
     </dict>
   </array>
   ```

2. **Ensure UTI Declarations**:
   
   macOS needs to know about the Markdown file type through UTI (Uniform Type Identifier) declarations:

   ```xml
   <key>UTImportedTypeDeclarations</key>
   <array>
     <dict>
       <key>UTTypeConformsTo</key>
       <array>
         <string>public.text</string>
       </array>
       <key>UTTypeDescription</key>
       <string>Markdown Text</string>
       <key>UTTypeIdentifier</key>
       <string>net.daringfireball.markdown</string>
       <key>UTTypeTagSpecification</key>
       <dict>
         <key>public.filename-extension</key>
         <array>
           <string>md</string>
           <string>markdown</string>
         </array>
         <key>public.mime-type</key>
         <array>
           <string>text/markdown</string>
         </array>
       </dict>
     </dict>
   </array>
   ```

3. **Implement Application Delegate Methods**:
   
   Ensure your AppDelegate implements these methods:

   ```objc
   // Handle files opened from Finder
   - (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
   {
     // Your implementation to handle the file
     return YES;
   }
   ```

4. **Rebuild and Reinstall**:
   
   After making these changes, completely rebuild the app and reinstall it:
   
   ```bash
   cd macos
   rm -rf Pods
   pod install
   cd ..
   ./build-macos.sh
   ```

5. **Reset macOS Launch Services**:
   
   If the problem persists, you might need to reset the Launch Services database:
   
   ```bash
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
   ```

6. **Verify Launch Services Registration**:
   
   Check if your app is registered correctly:
   
   ```bash
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep "bergen"
   ```

## Build Issues

### Build Database Locked

If you encounter a build error about a locked database:

```
error: unable to attach DB: error: accessing build database "/path/to/build.db": database is locked
```

Solutions:

1. Stop any running builds or Xcode instances
2. Delete the DerivedData folder:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/bergen*
   ```
3. Clean and reinstall pods:
   ```bash
   cd macos
   rm -rf Pods
   pod install
   ```

### No Bundle URL Present

If you see the error "No bundle URL present" when launching the app:

#### Solution 1: Use the Development Script

We've created a special development script that properly configures both Metro bundler and the app:

```bash
./run-dev.sh
```

This script:
1. Stops any existing Metro bundler
2. Cleans the build directory
3. Configures the build scripts to connect properly
4. Starts Metro bundler with the correct host
5. Builds and runs the app with the right environment variables

#### Solution 2: Start Metro Separately

If you prefer to run Metro separately:

1. Start Metro bundler in one terminal:
   ```bash
   yarn start --host 127.0.0.1
   ```

2. In another terminal, set the environment variables and run the app:
   ```bash
   RCT_NO_LAUNCH_PACKAGER=true REACT_NATIVE_PACKAGER_HOSTNAME=127.0.0.1 yarn macos
   ```

#### Solution 3: Fast Start for Existing Builds

For faster startup with existing builds:

```bash
./start-macos-fast.sh
```

## Performance Issues

If the app becomes slow or unresponsive:

1. **Use os_log for Performance Debugging**: Track performance bottlenecks in native code with os_log:

```objc
// At the start of a potentially slow operation
os_signpost_interval_begin(bergenAppLog, "file_load", "Loading file %{public}@", fileName);

// ... operation code ...

// At the end of the operation
os_signpost_interval_end(bergenAppLog, "file_load", "Loading file %{public}@", fileName);
```

Then use the Instruments app with the "os_signpost" template to visualize these events.

2. **Optimize File Loading**: Use async file operations and avoid loading large files synchronously
3. **Implement Pagination**: For large directories, load files in chunks
4. **Memoize Components**: Use React.memo() for pure components that don't need frequent re-rendering
5. **Debug Using Instruments**: Use Xcode's Instruments to identify performance bottlenecks

## State Persistence

If the app doesn't remember opened files or settings:

1. **Implement UserDefaults Storage**: Save recently opened files and settings
2. **Auto-save Feature**: Save state periodically during use
3. **Restore State on Launch**: Reload the last opened file when the app starts

---

## Debug Logging

### Using Console.app for Debugging

Bergen uses Apple's unified logging system to make debugging easier:

1. **Open Console.app** (in `/Applications/Utilities/`)
2. **Filter logs** using these filters:
   - `subsystem:com.bergen.app` - All Bergen logs
   - `category:files` - Only file operation logs
   - `category:menu` - Only menu interaction logs
   - `category:app` - Only general application logs
   - `level:error` - Show only errors
   - `level:debug` - Show detailed debug information

3. **Combine filters** for targeted debugging:
   - `subsystem:com.bergen.app category:files level:error` - Show file-related errors
   - `process:bergen category:menu` - Show menu-related logs for the Bergen process

4. **Advanced features**:
   - Use the Activity column to correlate related logs
   - Create persistent query predicates for common debug scenarios
   - Export logs for sharing with developers

For more information on structured logging, see the full documentation in the [Native Code Guide](native-code-guide.md#logging-with-os_log).

---

If you encounter issues not covered in this guide, please report them in the project's issue tracker.