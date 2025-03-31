import React from 'react';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View, useColorScheme } from 'react-native';
import type RNFS from 'react-native-fs';

import FileItem from './FileItem';
import FileOutline from './FileOutline';
import SidebarTab from './SidebarTab';

interface SidebarProps {
  currentPath: string;
  files: RNFS.ReadDirItem[];
  activeSidebarTab: 'files' | 'outline';
  headings: { level: number; text: string; position: number }[];
  activeFileName?: string;
  setActiveSidebarTab: (tab: 'files' | 'outline') => void;
  navigateUp: () => void;
  openFilePicker: () => void;
  handleFilePress: (file: RNFS.ReadDirItem) => void;
  handleHeadingPress: (position: number) => void;
}

const Sidebar = ({
  currentPath,
  files,
  activeSidebarTab,
  headings,
  activeFileName,
  setActiveSidebarTab,
  navigateUp,
  openFilePicker,
  handleFilePress,
  handleHeadingPress
}: SidebarProps) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View style={[styles.sidebar, { backgroundColor: isDarkMode ? '#1C1C1E' : '#F2F2F7' }]}>
      {/* Sidebar Tabs */}
      <View style={styles.sidebarTabs}>
        <SidebarTab
          title="Files"
          icon="📁"
          isActive={activeSidebarTab === 'files'}
          onPress={() => setActiveSidebarTab('files')}
        />
        <SidebarTab
          title="Outline"
          icon="📑"
          isActive={activeSidebarTab === 'outline'}
          onPress={() => setActiveSidebarTab('outline')}
        />
      </View>

      {/* Files Tab Content */}
      {activeSidebarTab === 'files' && (
        <FilesTabContent
          currentPath={currentPath}
          files={files}
          navigateUp={navigateUp}
          openFilePicker={openFilePicker}
          handleFilePress={handleFilePress}
          isDarkMode={isDarkMode}
        />
      )}

      {/* Outline Tab Content */}
      {activeSidebarTab === 'outline' && (
        <OutlineTabContent
          activeFileName={activeFileName || 'No file open'}
          headings={headings}
          handleHeadingPress={handleHeadingPress}
          isDarkMode={isDarkMode}
        />
      )}
    </View>
  );
};

// FilesTabContent component
interface FilesTabContentProps {
  currentPath: string;
  files: RNFS.ReadDirItem[];
  navigateUp: () => void;
  openFilePicker: () => void;
  handleFilePress: (file: RNFS.ReadDirItem) => void;
  isDarkMode: boolean;
}

const FilesTabContent = ({
  currentPath,
  files,
  navigateUp,
  openFilePicker,
  handleFilePress,
  isDarkMode
}: FilesTabContentProps) => (
  <>
    <View style={styles.navigationHeader}>
      <TouchableOpacity
        style={[styles.navigationButton, { backgroundColor: isDarkMode ? '#2C2C2E' : '#E5E5EA' }]}
        onPress={navigateUp}
      >
        <Text style={{ color: isDarkMode ? '#2C9BF0' : '#007AFF' }}>↑ Up</Text>
      </TouchableOpacity>
      <Text
        style={[styles.currentPathText, { color: isDarkMode ? '#FFFFFF' : '#000000' }]}
        numberOfLines={1}
      >
        {currentPath.split('/').pop()}
      </Text>
    </View>
    <View style={styles.actionHeader}>
      <TouchableOpacity
        style={[styles.actionButton, { backgroundColor: isDarkMode ? '#2C2C2E' : '#E5E5EA' }]}
        onPress={openFilePicker}
      >
        <Text style={{ color: isDarkMode ? '#2C9BF0' : '#007AFF' }}>Open File</Text>
      </TouchableOpacity>
    </View>
    <ScrollView style={styles.fileList}>
      {files.map((file, index) => (
        <FileItem
          key={index}
          name={file.name}
          isDirectory={file.isDirectory()}
          isSelected={false}
          onPress={() => handleFilePress(file)}
        />
      ))}
      {files.length === 0 && (
        <Text style={[styles.emptyDirectoryText, { color: isDarkMode ? '#8E8E93' : '#8E8E93' }]}>
          Empty directory
        </Text>
      )}
    </ScrollView>
  </>
);

// OutlineTabContent component
interface OutlineTabContentProps {
  activeFileName: string;
  headings: { level: number; text: string; position: number }[];
  handleHeadingPress: (position: number) => void;
  isDarkMode: boolean;
}

const OutlineTabContent = ({
  activeFileName,
  headings,
  handleHeadingPress,
  isDarkMode
}: OutlineTabContentProps) => (
  <>
    <View style={styles.outlineHeader}>
      <Text style={[styles.outlineTitle, { color: isDarkMode ? '#FFFFFF' : '#000000' }]}>
        {activeFileName}
      </Text>
    </View>
    <FileOutline headings={headings} onHeadingPress={handleHeadingPress} />
  </>
);

const styles = StyleSheet.create({
  sidebar: {
    width: 250,
    borderRightWidth: 0.5,
    borderRightColor: '#AAAAAA'
  },
  sidebarTabs: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 8,
    paddingHorizontal: 4,
    borderBottomWidth: 0.5,
    borderBottomColor: '#AAAAAA'
  },
  navigationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderBottomWidth: 0.5,
    borderBottomColor: '#AAAAAA'
  },
  actionHeader: {
    padding: 10,
    borderBottomWidth: 0.5,
    borderBottomColor: '#AAAAAA'
  },
  outlineHeader: {
    padding: 10,
    borderBottomWidth: 0.5,
    borderBottomColor: '#AAAAAA'
  },
  outlineTitle: {
    fontSize: 13,
    fontWeight: '600',
    textAlign: 'center'
  },
  navigationButton: {
    paddingVertical: 5,
    paddingHorizontal: 10,
    borderRadius: 4
  },
  actionButton: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    alignItems: 'center'
  },
  currentPathText: {
    fontSize: 12,
    marginLeft: 10,
    flex: 1
  },
  fileList: {
    flex: 1
  },
  emptyDirectoryText: {
    padding: 15,
    textAlign: 'center',
    fontStyle: 'italic'
  }
});

export default Sidebar;
