import type React from 'react';
import { Text, View, useColorScheme } from 'react-native';

// Blockquote renderer
const MarkdownBlockquote = ({ children }: { children: React.ReactNode }) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View
      style={{
        borderLeftWidth: 4,
        borderLeftColor: isDarkMode ? '#444444' : '#DDDDDD',
        paddingLeft: 16,
        marginVertical: 12,
        backgroundColor: isDarkMode ? '#222222' : '#F6F8FA',
        padding: 12,
        borderRadius: 4
      }}
    >
      <Text
        style={{
          color: isDarkMode ? '#BBBBBB' : '#6A737D',
          fontStyle: 'italic'
        }}
      >
        {children}
      </Text>
    </View>
  );
};

export default MarkdownBlockquote;
