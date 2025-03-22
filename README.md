# Bergen Markdown Viewer

A beautiful, minimal Markdown viewer for macOS built with React Native. This app allows you to navigate your file system, select markdown files, and view them with proper formatting including support for Mermaid diagrams.

## Features

- **Clean, elegant UI** that adapts to both light and dark mode
- **File system navigation** with a convenient sidebar
- **Markdown rendering** with proper formatting
- **Mermaid diagram support** for visualizing flowcharts and diagrams
- **macOS-native look and feel** designed specifically for desktop

## Getting Started

### Prerequisites

- Node.js (>= 18)
- macOS
- Xcode (latest version recommended)
- CocoaPods

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/bergen.git
   cd bergen
   ```

2. Install JavaScript dependencies
   ```bash
   npm install
   # or
   yarn install
   ```

3. Install pod dependencies
   ```bash
   cd macos && pod install
   ```

### Running the App

```bash
# Start the app
npm run macos
# or
yarn macos
```

## Usage

1. Use the sidebar to navigate through your file system
2. Click on any markdown (.md) file to preview it
3. Use the "Open File" button to navigate to a specific location
4. The app automatically renders markdown formatting and Mermaid diagrams

## Built With

- [React Native](https://reactnative.dev/) - The core framework
- [React Native macOS](https://microsoft.github.io/react-native-windows/docs/rnm-getting-started) - macOS platform support
- [React Native WebView](https://github.com/react-native-webview/react-native-webview) - For rendering markdown content
- [React Native FS](https://github.com/itinance/react-native-fs) - For file system operations
- [Mermaid](https://mermaid-js.github.io/mermaid/) - For diagram rendering

## License

This project is licensed under the MIT License

## Acknowledgments

- Inspired by various markdown editors and viewers
- macOS design guidelines