# Native Module Development Guide

This guide provides detailed instructions for creating new native modules to extend Bergen's functionality with platform-specific features.

## Table of Contents

- [Introduction](#introduction)
- [Native Module Architecture](#native-module-architecture)
- [Creating a Native Module for macOS](#creating-a-native-module-for-macos)
- [Exposing Native Methods to JavaScript](#exposing-native-methods-to-javascript)
- [Handling Events from Native to JavaScript](#handling-events-from-native-to-javascript)
- [TypeScript Definitions](#typescript-definitions)
- [Testing Native Modules](#testing-native-modules)
- [Debugging Tips](#debugging-tips)
- [Best Practices](#best-practices)
- [Examples](#examples)

## Introduction

Native modules bridge JavaScript and platform-native code, allowing React Native components to access platform-specific functionality that isn't available in the JavaScript runtime.

Common use cases for native modules:
- File system access
- Hardware integration (Bluetooth, USB, etc.)
- Native UI components (menus, dialogs, etc.)
- Performance-critical operations

## Native Module Architecture

In the Bergen application, native modules follow this architecture:

1. **Native Implementation**: Platform-specific code (Objective-C, Swift, Java, Kotlin)
2. **Bridge Layer**: Exposes native functionality to JavaScript
3. **JavaScript API**: TypeScript interface for React components
4. **TypeScript Definitions**: Type definitions for IDE support

## Creating a Native Module for macOS

### 1. Create the Header File

```objc
// ExampleModule.h
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExampleModule : RCTEventEmitter <RCTBridgeModule>

@end

NS_ASSUME_NONNULL_END
```

### 2. Create the Implementation File

```objc
// ExampleModule.m
#import "ExampleModule.h"

@implementation ExampleModule

RCT_EXPORT_MODULE();

// Required for RCTEventEmitter
- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onExampleEvent"];
}

// Main queue setup (for UI operations)
+ (BOOL)requiresMainQueueSetup
{
  return YES; // Return NO if not using UI operations
}

// Example method exposed to JavaScript
RCT_EXPORT_METHOD(exampleMethod:(NSString *)param
                  callback:(RCTResponseSenderBlock)callback)
{
  // Implement your native functionality here
  NSString *result = [NSString stringWithFormat:@"Received: %@", param];
  
  // Call back to JavaScript
  callback(@[[NSNull null], result]);
}

// Example method that returns a promise
RCT_EXPORT_METHOD(promiseMethod:(NSString *)param
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    NSString *result = [NSString stringWithFormat:@"Processed: %@", param];
    resolve(result);
  } @catch (NSException *exception) {
    reject(@"error", exception.reason, nil);
  }
}

// Example of sending an event to JavaScript
- (void)sendExampleEvent
{
  [self sendEventWithName:@"onExampleEvent" body:@{@"message": @"Something happened!"}];
}

@end
```

### 3. Add to the Xcode Project

1. In Xcode, right-click on the `bergen-macos` group
2. Select "Add Files to 'bergen-macos'..."
3. Select your new files
4. Ensure "Copy items if needed" is unchecked
5. Click "Add"

## Exposing Native Methods to JavaScript

Native modules can expose methods to JavaScript in several ways:

### 1. Simple Methods

```objc
// No return value
RCT_EXPORT_METHOD(simpleMethod:(NSString *)param)
{
  // Implementation
}
```

### 2. Callback Methods

```objc
// With callback
RCT_EXPORT_METHOD(callbackMethod:(NSString *)param
                  callback:(RCTResponseSenderBlock)callback)
{
  // Implementation
  callback(@[[NSNull null], @"result"]);
}
```

### 3. Promise-Based Methods

```objc
// With promises
RCT_EXPORT_METHOD(promiseMethod:(NSString *)param
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  // Implementation
  if (success) {
    resolve(@"result");
  } else {
    reject(@"error_code", @"Error message", nil);
  }
}
```

### 4. Constants

```objc
// Export constants to JavaScript
- (NSDictionary *)constantsToExport
{
  return @{
    @"DEFAULT_VALUE": @"some_value",
    @"MAX_COUNT": @100
  };
}
```

## Handling Events from Native to JavaScript

To send events from native code to JavaScript:

1. Extend `RCTEventEmitter` instead of `NSObject`
2. Implement `supportedEvents` method
3. Use `sendEventWithName:body:` to emit events

```objc
// In your native module
- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onSomeEvent", @"onAnotherEvent"];
}

// Sending an event
- (void)sendCustomEvent
{
  [self sendEventWithName:@"onSomeEvent" body:@{@"data": @"value"}];
}
```

On the JavaScript side:

```typescript
import { NativeModules, NativeEventEmitter } from 'react-native';

const { ExampleModule } = NativeModules;
const eventEmitter = new NativeEventEmitter(ExampleModule);

// Listen for events
const subscription = eventEmitter.addListener('onSomeEvent', (event) => {
  console.log('Event received:', event.data);
});

// Remember to remove the listener when no longer needed
subscription.remove();
```

## TypeScript Definitions

To ensure type safety, create TypeScript definitions for your native modules:

```typescript
// src/types/native-modules.d.ts

declare module 'react-native' {
  interface NativeModulesStatic {
    ExampleModule: {
      // Constants
      DEFAULT_VALUE: string;
      MAX_COUNT: number;
      
      // Methods
      simpleMethod(param: string): void;
      callbackMethod(param: string, callback: (error: any, result: string) => void): void;
      promiseMethod(param: string): Promise<string>;
    };
  }
}
```

## Testing Native Modules

### Unit Testing

Test native modules using XCTest for macOS/iOS:

```objc
@interface ExampleModuleTests : XCTestCase
@end

@implementation ExampleModuleTests

- (void)testExampleMethod
{
  ExampleModule *module = [[ExampleModule alloc] init];
  // Test implementation
}

@end
```

### Integration Testing

Test the JavaScript-to-native bridge using Jest:

```typescript
import { NativeModules } from 'react-native';

describe('ExampleModule', () => {
  it('should call native method correctly', async () => {
    // Mock implementation
    NativeModules.ExampleModule.promiseMethod = jest.fn().mockResolvedValue('Processed: test');
    
    // Test
    const result = await NativeModules.ExampleModule.promiseMethod('test');
    expect(result).toBe('Processed: test');
    expect(NativeModules.ExampleModule.promiseMethod).toHaveBeenCalledWith('test');
  });
});
```

## Debugging Tips

### Native Code Debugging

1. **Xcode Debugging**:
   - Set breakpoints in your Objective-C/Swift code
   - Print to console using `NSLog(@"Debug: %@", value)`
   - Use the Xcode debugger to inspect variables

2. **React Native Debugging**:
   - Use `console.log` in JavaScript to confirm method calls
   - Check for errors in the React Native red error screen
   - Verify module is correctly imported with `console.log(NativeModules.YourModule)`

### Common Issues

1. **Module Not Found**:
   - Ensure module is properly registered with `RCT_EXPORT_MODULE()`
   - Check spelling of imports and module names
   - Restart the React Native packager

2. **Method Not Called**:
   - Verify parameters match between JS and native code
   - Check for JS console errors
   - Ensure threading is handled correctly

3. **Events Not Received**:
   - Verify event name in `supportedEvents` array
   - Check event listener is properly set up in JS
   - Make sure event emitter is not garbage collected

## Best Practices

1. **Keep Modules Focused**: Each native module should have a single responsibility
2. **Error Handling**: Always handle errors and edge cases in native code
3. **Threading**: UI operations must run on the main thread
4. **Memory Management**: Avoid memory leaks, especially with event listeners
5. **Documentation**: Document all public APIs and parameters

## Examples

### File System Module

A simple module to demonstrate file operations:

```objc
// FSModule.h
#import <React/RCTBridgeModule.h>

@interface FSModule : NSObject <RCTBridgeModule>
@end

// FSModule.m
#import "FSModule.h"

@implementation FSModule

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(writeFile:(NSString *)filepath
                  content:(NSString *)content
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSError *error;
  [content writeToFile:filepath
            atomically:YES
              encoding:NSUTF8StringEncoding
                 error:&error];
  
  if (error) {
    reject(@"write_error", error.localizedDescription, error);
  } else {
    resolve(@YES);
  }
}

RCT_EXPORT_METHOD(readFile:(NSString *)filepath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSError *error;
  NSString *content = [NSString stringWithContentsOfFile:filepath
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
  
  if (error) {
    reject(@"read_error", error.localizedDescription, error);
  } else {
    resolve(content);
  }
}

@end
```

### System Info Module

A module that provides system information:

```objc
// SystemInfoModule.h
#import <React/RCTBridgeModule.h>

@interface SystemInfoModule : NSObject <RCTBridgeModule>
@end

// SystemInfoModule.m
#import "SystemInfoModule.h"
#import <SystemConfiguration/SystemConfiguration.h>

@implementation SystemInfoModule

RCT_EXPORT_MODULE();

- (NSDictionary *)constantsToExport
{
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];
  
  return @{
    @"osVersion": [processInfo operatingSystemVersionString],
    @"memorySize": @([processInfo physicalMemory]),
    @"processorCount": @([processInfo processorCount])
  };
}

RCT_EXPORT_METHOD(getHostname:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *hostname = [[NSProcessInfo processInfo] hostName];
  resolve(hostname);
}

@end
```

## Conclusion

Native modules are a powerful way to extend your React Native application with platform-specific capabilities. By following this guide, you should be able to create well-designed, maintainable native modules that integrate seamlessly with your JavaScript code.

For more details, refer to the [React Native documentation on native modules](https://reactnative.dev/docs/native-modules-intro) and platform-specific guides.