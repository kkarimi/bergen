import React from 'react';
import { Text, useColorScheme } from 'react-native';

// Heading renderer with different heading levels
const MarkdownHeading = ({level, children}: {level: number; children: React.ReactNode}) => {
  const isDarkMode = useColorScheme() === 'dark';
  
  const styles = {
    h1: {
      fontSize: 32,
      fontWeight: 'bold' as 'bold',
      marginBottom: 16,
      marginTop: 24,
      color: isDarkMode ? '#E6E6E6' : '#000000',
      borderBottomWidth: 1,
      borderBottomColor: isDarkMode ? '#444444' : '#EEEEEE',
      paddingBottom: 8,
    },
    h2: {
      fontSize: 24,
      fontWeight: 'bold' as 'bold',
      marginBottom: 12,
      marginTop: 20,
      color: isDarkMode ? '#E6E6E6' : '#000000',
    },
    h3: {
      fontSize: 20,
      fontWeight: 'bold' as 'bold',
      marginBottom: 8,
      marginTop: 16,
      color: isDarkMode ? '#E6E6E6' : '#000000',
    },
    h4: {
      fontSize: 18,
      fontWeight: 'bold' as 'bold',
      marginBottom: 8,
      marginTop: 16,
      color: isDarkMode ? '#E6E6E6' : '#000000',
    },
    h5: {
      fontSize: 16,
      fontWeight: 'bold' as 'bold',
      marginBottom: 8,
      marginTop: 12,
      color: isDarkMode ? '#E6E6E6' : '#000000',
    },
    h6: {
      fontSize: 14,
      fontWeight: 'bold' as 'bold',
      marginBottom: 8,
      marginTop: 12,
      color: isDarkMode ? '#E6E6E6' : '#000000',
    },
  };
  
  const headingStyle = {
    1: styles.h1,
    2: styles.h2,
    3: styles.h3,
    4: styles.h4,
    5: styles.h5,
    6: styles.h6,
  }[level] || styles.h6;
  
  return <Text style={headingStyle}>{children}</Text>;
};

export default MarkdownHeading;