# Project Dependencies Guide

This document explains the key dependency files used in the Bergen project and their purpose.

## Table of Contents

- [Gemfile](#gemfile)
- [Podfile](#podfile)
- [Package.json](#packagejson)
- [Dependency Management Best Practices](#dependency-management-best-practices)

## Gemfile

The `Gemfile` is a Ruby dependency specification file used by the Bundler gem to manage Ruby dependencies. In the Bergen project, it serves the following purposes:

- Specifies the required Ruby version for consistent development environments
- Declares CocoaPods as a dependency, which is required for iOS and macOS native module integration
- Pins specific versions of gems to avoid compatibility issues

```ruby
# Sample from Bergen's Gemfile
source 'https://rubygems.org'

# You may use http://rbenv.org/ or https://rvm.io/ to install and use this version
ruby ">= 2.6.10"

# Exclude problematic versions of cocoapods and activesupport that causes build failures.
gem 'cocoapods', '>= 1.13', '!= 1.15.0', '!= 1.15.1'
gem 'activesupport', '>= 6.1.7.5', '!= 7.1.0'
```

**Why It's Important:**
- Ensures all developers use compatible Ruby gems
- Prevents build failures from incompatible CocoaPods versions
- Simplifies dependency installation with just `bundle install`

## Podfile

The `Podfile` is used by CocoaPods to manage native iOS and macOS dependencies for React Native projects. In Bergen, it:

- Defines iOS/macOS platform requirements
- Specifies React Native and third-party native modules
- Configures build settings for native code

```ruby
# Sample from Bergen's Podfile
require_relative '../node_modules/react-native-macos/scripts/react_native_pods'
require_relative '../node_modules/@react-native-community/cli-platform-ios/native_modules'

target 'bergen-macOS' do
  platform :macos, '11.0'
  
  # Manually add the dependencies instead of using use_native_modules!
  pod 'RNCClipboard', :path => '../node_modules/@react-native-clipboard/clipboard'
  pod 'RNFS', :path => '../node_modules/react-native-fs'
  pod 'react-native-webview', :path => '../node_modules/react-native-webview'

  # React Native configuration
  use_react_native!(
    :path => '../node_modules/react-native-macos',
    :hermes_enabled => false,
    :fabric_enabled => ENV['RCT_NEW_ARCH_ENABLED'] == '1',
    :app_path => "#{Pod::Config.instance.installation_root}/.."
  )
end
```

**Why It's Important:**
- Links JavaScript dependencies to their native counterparts
- Ensures native code is properly integrated into the Xcode project
- Configures important build settings for the React Native runtime

## Package.json

While most JavaScript developers are familiar with `package.json`, Bergen uses it for several specific purposes:

- Declares React Native and JavaScript dependencies
- Defines build and development scripts
- Configures development tools like Biome

Key sections include:
- `dependencies`: Runtime packages required by the application
- `devDependencies`: Development and build-time tools
- `scripts`: Automated tasks for development workflow
- `resolutions`: Overrides for dependency versioning conflicts

## Dependency Management Best Practices

### When Updating Dependencies

1. **Gemfile Dependencies**:
   - Update with `bundle update [gem_name]`
   - Test builds on all supported platforms after updates
   - Lock problematic versions with version constraints

2. **CocoaPods Dependencies**:
   - Update with `pod update [pod_name]` in the `macos` directory
   - Run `pod install` after changes to the Podfile
   - Commit the updated `Podfile.lock` to ensure version consistency

3. **JavaScript Dependencies**:
   - Update with `yarn upgrade [package_name]`
   - Test functionality after updates
   - Use resolutions in package.json for conflict resolution

### Troubleshooting Dependency Issues

- **Ruby/CocoaPods Issues**: See the [Build Troubleshooting Guide](./build-troubleshooting.md)
- **JavaScript Dependency Issues**: Clean node_modules (`rm -rf node_modules`) and reinstall
- **Native Module Issues**: Check compatibility with React Native and macOS versions

---

For more information on the Bergen project architecture, see the [Architecture Guide](./architecture.md).