# Bergen Architecture Guide

This document outlines the high-level architecture of the Bergen application, including React Native, native components, and overall design decisions.

## Table of Contents

- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Application Structure](#application-structure)
- [Key Design Decisions](#key-design-decisions)
- [Cross-Platform Strategy](#cross-platform-strategy)
- [Testing Strategy](#testing-strategy)
- [Future Roadmap](#future-roadmap)

## Overview

Bergen is a cross-platform application , supporting iOS, Android, and macOS. The application follows a component-based architecture with a clear separation between UI, business logic, and platform-specific functionality.

## Technology Stack

### Core Technologies

- **React Native**: Primary framework for cross-platform UI development
- **TypeScript**: For type-safe JavaScript development
- **React Navigation**: For screen navigation
- **Native Modules**: For platform-specific functionality

### Platform-Specific Technologies

- **macOS**: Cocoa framework, Objective-C/C++
- **iOS**: UIKit, Objective-C/Swift (future)
- **Android**: Kotlin/Java (future)

### Development Tools

- **Yarn**: Package management
- **Metro**: JavaScript bundling
- **ESLint**: Code linting
- **Jest**: Unit and integration testing
- **Xcode**: macOS/iOS development
- **Android Studio**: Android development (future)

## Application Structure

The application follows a modular structure:

```
/
├── App.tsx                # Main application component
├── index.js               # Entry point
├── __tests__/             # Test files
├── assets/                # Static assets like images
├── components/            # Reusable UI components
├── screens/               # Screen components
├── hooks/                 # Custom React hooks
├── utils/                 # Utility functions
├── services/              # API and service integrations
├── navigation/            # Navigation configuration
├── ios/                   # iOS-specific native code
├── android/               # Android-specific native code
├── macos/                 # macOS-specific native code
└── docs/                  # Documentation
```

## Key Design Decisions

### 1. Cross-Platform First

The application is designed with cross-platform compatibility as a primary goal. Where possible, code is shared across platforms, with platform-specific implementations only when necessary.

### 2. Native Integration

While most functionality is implemented in JavaScript using React Native, the application leverages native capabilities through native modules when:

- Performance is critical
- Platform-specific features are required (e.g., menu systems, notifications)
- Deep OS integration is needed

### 3. Component Structure

UI components follow these principles:

- **Atomic Design**: Building complex interfaces from simple, reusable components
- **Separation of Concerns**: Components are focused on presentation, with business logic in hooks and services
- **Platform-Specific Variations**: When needed, components can render differently on different platforms

### 4. State Management

The application uses:

- **React Context API**: For global state that doesn't change frequently
- **React Query/SWR**: For remote data fetching (future)
- **Local Component State**: For UI-specific state

## Cross-Platform Strategy

### Shared Code

Most of the application logic and UI is shared across platforms, including:

- Business logic
- UI components
- Navigation
- Data fetching and state management

### Platform-Specific Code

Platform-specific code is isolated to:

- Native modules
- Platform-specific UI adjustments
- Platform services (menu, notifications, etc.)

### Platform Detection

The application uses React Native's `Platform` API to conditionally render different components or behaviors based on the platform.

## Testing Strategy

The testing approach includes:

### Unit Tests

- **Component Tests**: For UI components
- **Hook Tests**: For custom hooks
- **Utility Tests**: For helper functions

### Integration Tests

- **Screen Tests**: Testing full screens with mocked dependencies
- **Navigation Tests**: Testing navigation flows

### End-to-End Tests

- **User Flow Tests**: Testing complete user journeys (future)

## Future Roadmap

### Short-term Goals

- Complete the macOS implementation
- Add more native integrations for macOS
- Implement comprehensive test coverage

### Medium-term Goals

- Enhance iOS support
- Begin Android implementation
- Create a unified design system

### Long-term Vision

- Full desktop and mobile support
- Advanced native integrations on all platforms
- Offline support
- Cloud synchronization

## Development Guidelines

### Code Style

- Follow TypeScript best practices
- Use functional components with hooks
- Write meaningful comments for complex logic
- Each component should have a clear single responsibility

### Native Code

- Follow platform-specific best practices (Swift for iOS, Kotlin for Android)
- Document all native modules comprehensively
- Provide TypeScript typings for native modules

### Documentation

- Document all major components and modules
- Keep architecture documentation updated with changes
- Provide examples for common use cases

---

This document will be updated as the architecture evolves. Contributions to this guide are welcome.