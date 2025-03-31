# File Information Panel

Bergen includes a convenient file information panel that provides detailed metadata about your files, including Git repository information. This document explains how to use this feature and the information it provides.

## Accessing the File Information Panel

The file information panel appears as a right sidebar in the application. To toggle its visibility:

1. Click the info button (ℹ️) in the top-right corner of the tab bar
2. The panel will slide in from the right side of the application
3. Click the button again to hide the panel

## Available Information

### Basic File Information

The file information panel displays the following basic metadata for the selected file:

| Field | Description |
|-------|-------------|
| Name | The file or directory name |
| Size | The file size in appropriate units (B, KB, MB, GB, TB) |
| Path | The full absolute path to the file |
| Created | The date and time when the file was created |
| Modified | The date and time when the file was last modified |
| Accessed | The date and time when the file was last accessed |
| Type | Whether the item is a File or Directory |

### Git Information

For files within Git repositories, additional metadata is displayed:

| Field | Description |
|-------|-------------|
| Repository | The name of the Git repository |
| Branch | The current Git branch |
| Status | The file's Git status (Modified, Added, Deleted, etc.) |
| Last Commit | The hash of the most recent commit affecting this file |
| Last Author | The author of the most recent commit |
| Last Date | The date of the most recent commit |
| Last Message | The commit message of the most recent commit |
| Added By | The author who first added this file to the repository |
| Added Date | The date when this file was first added to the repository |

## Updating the Displayed Information

The file information panel automatically updates its displayed metadata when:

1. You select a different file or directory in the file browser sidebar
2. The currently displayed file is modified

## Implementation Details

The file information panel is implemented using:

- The `FileInfo.tsx` component that renders the panel
- The `GitModule.mm` native module for Git information retrieval 
- The `useGitInfo.ts` custom hook to fetch Git repository details
- React state in the `App.tsx` component to track the selected file and panel visibility
- Integration with the tab bar to provide the toggle button
- File system metadata from the React Native FS library

## Benefits

The file information panel provides several benefits:

- Quick access to file metadata without using system tools
- Easy verification of file properties like creation and modification dates
- Clear indication of file sizes and types
- Git repository information without using the command line
- Ability to see who created or last modified the file
- Enhanced workflow when managing multiple files

## Future Enhancements

Planned enhancements for the file information panel include:

- File permission information
- Additional metadata for specific file types
- Ability to edit certain file properties
- Custom metadata display options

---

For more information about Bergen's features, please see the [main documentation](README.md).