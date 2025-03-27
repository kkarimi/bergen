import React from 'react';
import { StyleSheet, Text, TouchableOpacity, useColorScheme } from 'react-native';

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
      borderBottomWidth: 1,
      borderBottomColor: '#EEEEEE'
    },
    selectedFile: {
      backgroundColor: '#E5E5EA'
    },
    fileName: {
      fontSize: 14
    },
    directoryName: {
      fontWeight: 'bold'
    }
  });

  return (
    <TouchableOpacity
      style={[
        styles.fileItem,
        isSelected && styles.selectedFile,
        isSelected && { backgroundColor: isDarkMode ? '#3A3A3C' : '#E5E5EA' }
      ]}
      onPress={onPress}
    >
      <Text
        style={[
          styles.fileName,
          { color: isDarkMode ? '#FFFFFF' : '#000000' },
          isDirectory && styles.directoryName
        ]}
      >
        {isDirectory ? '📁 ' : '📄 '}
        {name}
      </Text>
    </TouchableOpacity>
  );
};

export default FileItem;
