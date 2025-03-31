import type React from 'react';
import { StyleSheet, Text, TouchableOpacity, View, useColorScheme } from 'react-native';

import TabBar from './TabBar';
import MarkdownViewer from './markdown/MarkdownViewer';

interface TabData {
  id: string;
  filePath: string;
  fileName: string;
  content: string;
}

interface MainContentProps {
  openTabs: TabData[];
  activeTabIndex: number;
  markdownScrollViewRef: React.RefObject<any>;
  handleTabPress: (index: number) => void;
  closeTab: (index: number) => void;
  addNewTab: () => void;
  openFilePicker: () => void;
  isFileInfoSidebarVisible?: boolean;
}

const MainContent = ({
  openTabs,
  activeTabIndex,
  markdownScrollViewRef,
  handleTabPress,
  closeTab,
  addNewTab,
  openFilePicker,
  isFileInfoSidebarVisible
}: MainContentProps) => {
  const isDarkMode = useColorScheme() === 'dark';

  // Helper function to get the currently active tab
  const getActiveTab = (): TabData | undefined => {
    if (activeTabIndex >= 0 && activeTabIndex < openTabs.length) {
      return openTabs[activeTabIndex];
    }
    return undefined;
  };

  return (
    <View style={styles.contentArea}>
      {/* Tab bar */}
      {openTabs.length > 0 && (
        <TabBar
          tabs={openTabs}
          activeTabIndex={activeTabIndex}
          onTabPress={handleTabPress}
          onCloseTab={closeTab}
          onAddTab={addNewTab}
          isFileInfoSidebarVisible={isFileInfoSidebarVisible}
        />
      )}

      {/* Content */}
      {getActiveTab() ? (
        <>
          <MarkdownViewer
            content={getActiveTab()?.content || ''}
            filePath={getActiveTab()?.filePath || ''}
            ref={markdownScrollViewRef}
          />
        </>
      ) : (
        <View
          style={[styles.noFileSelected, { backgroundColor: isDarkMode ? '#1C1C1E' : '#F2F2F7' }]}
        >
          <Text
            style={{
              fontSize: 16,
              color: isDarkMode ? '#8E8E93' : '#8E8E93',
              textAlign: 'center',
              marginBottom: 32
            }}
          >
            Get started by opening a markdown file
          </Text>
          <TouchableOpacity
            style={[styles.openFileButton, { backgroundColor: isDarkMode ? '#2C9BF0' : '#007AFF' }]}
            onPress={openFilePicker}
          >
            <Text
              style={{
                color: '#FFFFFF',
                fontSize: 16,
                fontWeight: 'bold'
              }}
            >
              📂 Open File
            </Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  contentArea: {
    flex: 1
  },
  noFileSelected: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20
  },
  openFileButton: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4
  }
});

export default MainContent;
