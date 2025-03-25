import React from 'react';
import { Text, useColorScheme } from 'react-native';

// Text renderer with basic style
export const MarkdownText = ({children}: {children: React.ReactNode}) => {
  const isDarkMode = useColorScheme() === 'dark';
  
  return (
    <Text style={{
      fontSize: 16,
      marginBottom: 12,
      lineHeight: 24,
      color: isDarkMode ? '#CCCCCC' : '#24292E',
    }}>
      {children}
    </Text>
  );
};

// Strong (bold) text renderer
export const MarkdownStrong = ({children}: {children: React.ReactNode}) => {
  return <Text style={{fontWeight: 'bold'}}>{children}</Text>;
};

// Emphasis (italic) text renderer
export const MarkdownEmphasis = ({children}: {children: React.ReactNode}) => {
  return <Text style={{fontStyle: 'italic'}}>{children}</Text>;
};
