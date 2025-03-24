# Bergen Troubleshooting Guide

This document covers common issues and their solutions when developing or using the Bergen Markdown Viewer application.

## React Native to Native Communication Issues

### File Selection Not Updating UI

If selecting a file through the native File -> Open menu doesn't update the UI:

1. **Add Debugging Logs**: Add console.log statements to track the flow of events:

```javascript
// In your event listener
console.log('Received file menu action:', event);

// In your file handling function
console.log('handleSelectedFile called with:', filePath);
console.log('File content loaded, length:', content.length);
```

2. **Delay Native Events**: Sometimes events from native to React Native can be missed. Add a delay and send multiple events:

```objc
// Send event with a delay to ensure React Native is ready
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  [self sendEventWithName:@"fileMenuAction" body:@{
    @"action": @"fileSelected",
    @"path": filePath
  }];
  
  // Send again after a short delay as a fallback
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self sendEventWithName:@"fileMenuAction" body:@{
      @"action": @"fileSelected",
      @"path": filePath
    }];
  });
});
```

3. **Use Component State Properly**: Ensure your React component correctly handles state updates:

```javascript
// Use more specific condition to render content
{selectedFile && fileContent ? (
  <MarkdownRenderer content={fileContent} />
) : (
  <NoFileSelectedView />
)}
```

4. **Prevent Initialization Overwrites**: Make sure initialization logic doesn't overwrite user-selected content:

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

## Performance Issues

If the app becomes slow or unresponsive:

1. **Optimize File Loading**: Use async file operations and avoid loading large files synchronously
2. **Implement Pagination**: For large directories, load files in chunks
3. **Memoize Components**: Use React.memo() for pure components that don't need frequent re-rendering
4. **Debug Using Instruments**: Use Xcode's Instruments to identify performance bottlenecks

## State Persistence

If the app doesn't remember opened files or settings:

1. **Implement UserDefaults Storage**: Save recently opened files and settings
2. **Auto-save Feature**: Save state periodically during use
3. **Restore State on Launch**: Reload the last opened file when the app starts

---

If you encounter issues not covered in this guide, please report them in the project's issue tracker.