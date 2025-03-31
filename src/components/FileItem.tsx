import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View, useColorScheme } from 'react-native';

// Component to render file item in sidebar
const FileItem = ({
  name,
  isDirectory,
  isSelected,
  onPress
}: {
  name: string;
  isDirectory: boolean;
  isSelected: boolean;
  onPress: () => void;
}) => {
  const isDarkMode = useColorScheme() === 'dark';

  const styles = StyleSheet.create({
    fileItem: {
      padding: 10,
      borderRadius: 6,
      marginVertical: 2,
      marginHorizontal: 4,
      flexDirection: 'row',
      alignItems: 'center'
    },
    selectedFile: {
      backgroundColor: isDarkMode ? 'rgba(58, 108, 217, 0.5)' : 'rgba(0, 122, 255, 0.1)'
    },
    fileName: {
      fontSize: 13,
      flex: 1
    },
    directoryName: {
      fontWeight: '600'
    },
    fileIcon: {
      marginRight: 8,
      fontSize: 16
    }
  });

  return (
    <TouchableOpacity
      style={[
        styles.fileItem,
        isSelected && styles.selectedFile,
        !isSelected && { backgroundColor: isDarkMode ? 'transparent' : 'transparent' }
      ]}
      onPress={onPress}
    >
      <Text style={[styles.fileIcon, { color: isDarkMode ? '#CCCCCC' : '#666666' }]}>
        {isDirectory ? '📁' : '📄'}
      </Text>
      <Text
        style={[
          styles.fileName,
          { color: isDarkMode ? '#FFFFFF' : '#000000' },
          isDirectory && styles.directoryName
        ]}
        numberOfLines={1}
        ellipsizeMode="middle"
      >
        {name}
      </Text>
    </TouchableOpacity>
  );
};

export default FileItem;
