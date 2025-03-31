import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Alert,
  NativeEventEmitter,
  NativeModules,
  SafeAreaView,
  type ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  useColorScheme
} from 'react-native';
import RNFS from 'react-native-fs';

import FileInfo from './src/components/FileInfo';
import MainContent from './src/components/MainContent';
// Import components
import Sidebar from './src/components/Sidebar';

// Import hooks
import useMarkdownHeadings from './src/hooks/useMarkdownHeadings';
import type { TabData } from './src/types';

// Get native modules
const { NativeMenuModule, FileManagerModule, GitModule } = NativeModules;

// Define global openMarkdownFile function used by MarkdownLink component
declare global {
  var openMarkdownFile: (filePath: string, content: string, newTab?: boolean) => void;
}

const App = () => {
  // Default to Documents directory for initial path
  const [currentPath, setCurrentPath] = useState(RNFS.DocumentDirectoryPath);
  const [files, setFiles] = useState<RNFS.ReadDirItem[]>([]);
  const [openTabs, setOpenTabs] = useState<TabData[]>([]);
  const [activeTabIndex, setActiveTabIndex] = useState<number>(-1);
  const [isSidebarCollapsed, setSidebarCollapsed] = useState(true);
  const [isFileInfoSidebarVisible, setFileInfoSidebarVisible] = useState(false);
  const [activeSidebarTab, setActiveSidebarTab] = useState<'files' | 'outline'>('files');
  const [selectedFileInfo, setSelectedFileInfo] = useState<RNFS.ReadDirItem | null>(null);
  const markdownScrollViewRef = useRef<ScrollView | null>(null);
  const isDarkMode = useColorScheme() === 'dark';

  // Helper function to get the currently active tab
  const getActiveTab = useCallback((): TabData | undefined => {
    if (activeTabIndex >= 0 && activeTabIndex < openTabs.length) {
      return openTabs[activeTabIndex];
    }
    return undefined;
  }, [activeTabIndex, openTabs]);

  // Get headings from the markdown content using custom hook
  const headings = useMarkdownHeadings(getActiveTab);

  // Set up native event listeners for menu actions
  useEffect(() => {
    // Initialize native event emitter
    const menuEventEmitter = new NativeEventEmitter(NativeMenuModule);

    // Listen for file menu actions
    const fileMenuSubscription = menuEventEmitter.addListener('fileMenuAction', (event) => {
      console.log('Received file menu action:', event);
      if (event.action === 'fileSelected' && event.path) {
        console.log('Will handle selected file:', event.path);
        handleSelectedFile(event.path);
      }
    });

    // Listen for view menu actions
    const viewMenuSubscription = menuEventEmitter.addListener('viewMenuAction', (event) => {
      console.log('Received view menu action:', event);
      if (event.action === 'toggleSidebar') {
        console.log('Toggling sidebar visibility to:', event.show);

        // Update UI state when menu action occurs
        const newCollapsedState = !event.show; // event.show=true means sidebar should be visible
        setSidebarCollapsed(newCollapsedState);

        // No need to call updateSidebarState here since the event came from native side
        // which already updated its own state
      }
    });

    // Clean up subscriptions
    return () => {
      fileMenuSubscription.remove();
      viewMenuSubscription.remove();
    };
  }, []);

  // Register a global file opener function that can be called from MarkdownLink
  useEffect(() => {
    // Create global handler for opening markdown files from links
    global.openMarkdownFile = (filePath: string, content: string, newTab = true) => {
      console.log('Opening markdown file from link:', filePath);

      try {
        // Extract file name from path
        const fileName = filePath.split('/').pop() || 'Untitled';

        // First check if this file is already open in a tab
        const existingTabIndex = openTabs.findIndex((tab) => tab.filePath === filePath);

        if (existingTabIndex !== -1) {
          // If it's already open, just switch to it
          console.log('File already open, switching to tab:', existingTabIndex);
          setActiveTabIndex(existingTabIndex);
          return;
        }

        // Create a new tab directly instead of calling openTab
        // This will avoid any issues with React state updates
        const newTab: TabData = {
          id: Date.now().toString(),
          filePath,
          fileName,
          content
        };

        // Important: Add the new tab without affecting other tabs
        // and make it active without closing other tabs
        setOpenTabs((current) => {
          // First add the new tab
          const updated = [...current, newTab];
          // Then set the active index to the newly added tab
          setTimeout(() => {
            setActiveTabIndex(updated.length - 1);
          }, 0);
          return updated;
        });
      } catch (error) {
        console.error('Error opening file in new tab:', error);
      }
    };

    // Clean up on unmount
    return () => {
      // Clean up global handler without using delete operator
      global.openMarkdownFile = undefined as any;
    };
  }, [openTabs]);

  // Tab management functions
  const handleTabPress = (index: number) => {
    setActiveTabIndex(index);
  };

  const closeTab = (index: number) => {
    // Create a copy of the current tabs
    const newTabs = [...openTabs];
    // Remove the tab at the specified index
    newTabs.splice(index, 1);

    // Update the active tab index if necessary
    let newActiveTabIndex = activeTabIndex;
    if (newTabs.length === 0) {
      // No more tabs open
      newActiveTabIndex = -1;
    } else if (index === activeTabIndex) {
      // The closed tab was active, select the previous tab or the first tab
      newActiveTabIndex = Math.max(0, index - 1);
    } else if (index < activeTabIndex) {
      // The closed tab was before the active tab, adjust the index
      newActiveTabIndex = activeTabIndex - 1;
    }

    setOpenTabs(newTabs);
    setActiveTabIndex(newActiveTabIndex);
  };

  const openTab = (filePath: string, fileName: string, content: string) => {
    // Check if the file is already open in a tab
    const existingTabIndex = openTabs.findIndex((tab) => tab.filePath === filePath);

    if (existingTabIndex !== -1) {
      // File is already open, just switch to that tab
      setActiveTabIndex(existingTabIndex);
      return;
    }

    // Create a new tab
    const newTab: TabData = {
      id: Date.now().toString(), // Simple unique ID
      filePath,
      fileName,
      content
    };

    // First update the tabs array (add the new tab)
    const updatedTabs = [...openTabs, newTab];

    // Then update state and make the new tab active
    setOpenTabs(updatedTabs);
    setActiveTabIndex(updatedTabs.length - 1); // Fix: use length-1 as index
  };

  const addNewTab = () => {
    // This function is called when the + button in the tab bar is clicked
    // For now, just show a file picker dialog
    openFilePicker();
  };

  // Handle file selection from native file picker
  const handleSelectedFile = async (filePath: string) => {
    console.log('handleSelectedFile called with:', filePath);

    if (!filePath.endsWith('.md') && !filePath.endsWith('.markdown')) {
      console.warn('Not a markdown file:', filePath);
      return;
    }

    try {
      // Update the current directory to the parent directory of the selected file
      const parentPath = filePath.substring(0, filePath.lastIndexOf('/'));
      console.log('Setting current path to:', parentPath);
      setCurrentPath(parentPath);

      // Load file content - decode URI component to handle special characters in the path
      console.log('Reading file content...');

      // Handle special characters in file path by properly decoding the path
      let decodedPath = filePath;
      try {
        // Only attempt to decode parts after the last / to avoid breaking the path structure
        const lastSlashIndex = filePath.lastIndexOf('/');
        if (lastSlashIndex !== -1) {
          const pathBase = filePath.substring(0, lastSlashIndex + 1);
          const fileName = filePath.substring(lastSlashIndex + 1);
          // Decode the filename part which might contain URL-encoded characters
          const decodedFileName = decodeURIComponent(fileName);
          decodedPath = pathBase + decodedFileName;
        }
      } catch (decodeError) {
        console.warn('Error decoding path, using original:', decodeError);
        // Continue with original path if decoding fails
      }

      console.log('Attempting to read file with path:', decodedPath);
      const content = await RNFS.readFile(decodedPath, 'utf8');
      console.log('File content loaded, length:', content.length);

      // Extract file name from path
      const fileName = decodedPath.split('/').pop() || 'Untitled';

      // Open the file in a new tab
      openTab(decodedPath, fileName, content);

      // Refresh file list
      console.log('Refreshing file list...');
      const dirItems = await RNFS.readDir(parentPath);
      setFiles(
        dirItems.sort((a, b) => {
          if (a.isDirectory() && !b.isDirectory()) return -1;
          if (!a.isDirectory() && b.isDirectory()) return 1;
          return a.name.localeCompare(b.name);
        })
      );
      console.log('File list updated with', dirItems.length, 'items');
    } catch (error: any) {
      console.error('Failed to load selected file:', error);
      Alert.alert('Error', `Failed to load file: ${error.message}`);
    }
  };

  // Initialize the file list
  useEffect(() => {
    // Just load the file list without auto-opening welcome.md
    const loadFileList = async () => {
      try {
        const results = await RNFS.readDir(currentPath);
        setFiles(
          results.sort((a, b) => {
            if (a.isDirectory() && !b.isDirectory()) return -1;
            if (!a.isDirectory() && b.isDirectory()) return 1;
            return a.name.localeCompare(b.name);
          })
        );
      } catch (error) {
        console.error('Failed to read directory:', error);
      }
    };

    loadFileList();
  }, [currentPath]);

  // This useEffect is redundant with the one above, removing to avoid duplicate directory reads

  // Handle heading selection from outline
  const handleHeadingPress = (position: number) => {
    // Implement scrolling to the heading position
    console.log('Scroll to position:', position);
    // If you have a ref to your markdown ScrollView component:
    if (markdownScrollViewRef.current) {
      // This is an approximation - you might need to adjust based on your component
      markdownScrollViewRef.current.scrollTo({ y: position * 0.5, animated: true });
    }
  };

  // Handle file selection from sidebar
  const handleFilePress = async (file: RNFS.ReadDirItem) => {
    // Set the selected file info regardless of type
    setSelectedFileInfo(file);

    if (file.isDirectory()) {
      setCurrentPath(file.path);
    } else if (
      file.name.toLowerCase().endsWith('.md') ||
      file.name.toLowerCase().endsWith('.markdown')
    ) {
      try {
        // Handle special characters in file path similar to handleSelectedFile
        let decodedPath = file.path;
        try {
          const lastSlashIndex = file.path.lastIndexOf('/');
          if (lastSlashIndex !== -1) {
            const pathBase = file.path.substring(0, lastSlashIndex + 1);
            const fileName = file.path.substring(lastSlashIndex + 1);
            const decodedFileName = decodeURIComponent(fileName);
            decodedPath = pathBase + decodedFileName;
          }
        } catch (decodeError) {
          console.warn('Error decoding path, using original:', decodeError);
        }

        console.log('Attempting to read file with path:', decodedPath);
        const content = await RNFS.readFile(decodedPath, 'utf8');

        // Open in a new tab
        openTab(decodedPath, file.name, content);
      } catch (error: any) {
        console.error('Failed to read file:', error);
        Alert.alert('Error', `Failed to load file: ${error.message}`);
      }
    }
  };

  // Go up one directory
  const navigateUp = () => {
    const parentPath = currentPath.split('/').slice(0, -1).join('/');
    if (parentPath) {
      setCurrentPath(parentPath);
    }
  };

  // Open file dialog to select any markdown file
  const openFilePicker = async () => {
    try {
      if (FileManagerModule) {
        // Use the native file picker
        const filePath = await FileManagerModule.showOpenDialog();
        if (filePath) {
          handleSelectedFile(filePath);
        }
      } else {
        console.warn('FileManagerModule not available. Falling back to default directory');
        // Fallback: open the user's home directory
        const homePath = `${RNFS.DocumentDirectoryPath.split('/').slice(0, 3).join('/')}/Documents`;
        if (await RNFS.exists(homePath)) {
          setCurrentPath(homePath);
          setSelectedFile(null);
          setFileContent('');
        }
      }
    } catch (error) {
      console.error('Failed to open file picker:', error);
    }
  };

  // Toggle sidebar collapsed state
  const toggleSidebar = () => {
    const newState = !isSidebarCollapsed;
    setSidebarCollapsed(newState);

    // Sync the state with native menu
    if (NativeMenuModule?.updateSidebarState) {
      NativeMenuModule.updateSidebarState(newState);
    }
  };

  // Toggle file info sidebar
  const toggleFileInfoSidebar = () => {
    setFileInfoSidebarVisible(!isFileInfoSidebarVisible);
  };

  return (
    <SafeAreaView
      style={[styles.container, { backgroundColor: isDarkMode ? '#000000' : '#FFFFFF' }]}
    >
      <View style={styles.appContainer}>
        {/* Sidebar collapse button */}
        <TouchableOpacity
          style={[styles.collapseButton, { backgroundColor: isDarkMode ? '#2C2C2E' : '#E5E5EA' }]}
          onPress={toggleSidebar}
        >
          <Text
            style={{
              color: isDarkMode ? '#2C9BF0' : '#007AFF',
              fontSize: 16,
              fontWeight: 'bold'
            }}
          >
            {isSidebarCollapsed ? '›' : '‹'}
          </Text>
        </TouchableOpacity>

        {/* Sidebar */}
        {!isSidebarCollapsed && (
          <Sidebar
            currentPath={currentPath}
            files={files}
            activeSidebarTab={activeSidebarTab}
            headings={headings}
            activeFileName={getActiveTab()?.fileName}
            setActiveSidebarTab={setActiveSidebarTab}
            navigateUp={navigateUp}
            openFilePicker={openFilePicker}
            handleFilePress={handleFilePress}
            handleHeadingPress={handleHeadingPress}
          />
        )}

        {/* Main content area */}
        <View style={[styles.contentArea, isSidebarCollapsed && styles.expandedContent]}>
          <MainContent
            openTabs={openTabs}
            activeTabIndex={activeTabIndex}
            markdownScrollViewRef={markdownScrollViewRef}
            handleTabPress={handleTabPress}
            closeTab={closeTab}
            addNewTab={toggleFileInfoSidebar}
            openFilePicker={openFilePicker}
            isFileInfoSidebarVisible={isFileInfoSidebarVisible}
          />
        </View>

        {/* File Info Sidebar */}
        {isFileInfoSidebarVisible && (
          <FileInfo file={selectedFileInfo} activeFilePath={getActiveTab()?.filePath} />
        )}
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  appContainer: {
    flex: 1,
    flexDirection: 'row'
  },
  collapseButton: {
    width: 24,
    alignItems: 'center',
    justifyContent: 'center',
    borderRightWidth: 0.5,
    borderRightColor: '#AAAAAA',
    zIndex: 10
  },
  contentArea: {
    flex: 1
  },
  expandedContent: {
    flex: 1
  }
});

export default App;
