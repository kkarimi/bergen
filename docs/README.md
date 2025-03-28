# Bergen Documentation

This directory contains comprehensive documentation for the Bergen app.

## Available Documentation

### Architecture and Design

- [**Architecture Guide**](./architecture.md) - Overview of the application architecture, technology stack, and design decisions
- [**Native Code Guide**](./native-code-guide.md) - Explanation of native code organization, components, and design patterns

### Development Guides

- [**Native Module Guide**](./native-module-guide.md) - Step-by-step instructions for creating native modules
- [**Build Troubleshooting Guide**](./build-troubleshooting.md) - Solutions for common build issues
  - [Build Modes and Options](./build-troubleshooting.md#build-modes-and-options) - Different ways to build the app
  - [Specialized Build Scripts](./build-troubleshooting.md#specialized-build-scripts) - Available build scripts for different scenarios
  - [Sandbox Permission Issues](./build-troubleshooting.md#sandbox-permission-issues) - Fixing common permission errors
- [**Troubleshooting Guide**](./troubleshooting.md) - Solutions for common development and runtime issues

### Distribution and Signing

- [**Signing Instructions**](./signing-instructions.md) - Guide for code signing and notarizing Bergen for distribution
- [**Homebrew Distribution**](./homebrew-distribution.md) - Guide for distributing Bergen via Homebrew
- [**App Store Info**](./app-store-info.md) - Important information for App Store distribution
- [**App Store Submission**](./app-store-submission.md) - Complete guide for submitting Bergen to the Mac App Store

## Getting Started

New to the project? Here's what to read first:

1. Start with the [**Architecture Guide**](./architecture.md) for a high-level overview
2. Read the [**Native Code Guide**](./native-code-guide.md) to understand the native implementation
3. For adding new native features, follow the [**Native Module Guide**](./native-module-guide.md)
4. If you encounter build issues, consult the [**Build Troubleshooting Guide**](./build-troubleshooting.md)
5. For general development and runtime issues, see the [**Troubleshooting Guide**](./troubleshooting.md)

## Contributing to Documentation

When adding new features or making significant changes to the codebase, please update the relevant documentation files. If creating new subsystems or patterns, consider adding a new dedicated guide.

Documentation should:
- Be clear and concise
- Include code examples where appropriate
- Explain both "how" and "why"
- Be updated when the code changes

## Building the Documentation

The documentation is written in Markdown and can be viewed directly on GitHub or using any Markdown reader.

---

If you have questions about the project that aren't addressed in the documentation, please open an issue or contact the project maintainers.