import React from 'react';
import { Text, useColorScheme } from 'react-native';

// Inline code renderer
const InlineCode = ({value}: {value: string}) => {
  const isDarkMode = useColorScheme() === 'dark';
  
  return (
    <Text style={{
      fontFamily: 'Menlo',
      backgroundColor: isDarkMode ? '#2D2D2D' : '#F0F0F0',
      color: isDarkMode ? '#E6E6E6' : '#24292E',
      padding: 2,
      paddingHorizontal: 4,
      borderRadius: 3,
      fontSize: 14,
    }}>
      {value}
    </Text>
  );
};

export default InlineCode;