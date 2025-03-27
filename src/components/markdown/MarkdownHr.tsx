import React from 'react';
import { View, useColorScheme } from 'react-native';

// Horizontal rule renderer
const MarkdownHr = () => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View
      style={{
        height: 1,
        backgroundColor: isDarkMode ? '#444444' : '#EEEEEE',
        marginVertical: 16
      }}
    />
  );
};

export default MarkdownHr;
