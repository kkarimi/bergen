import type React from 'react';
import { Text, View, useColorScheme } from 'react-native';

// Table related components
export const MarkdownTable = ({ children }: { children: React.ReactNode }) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View
      style={{
        marginVertical: 16,
        borderWidth: 1,
        borderColor: isDarkMode ? '#444444' : '#DDDDDD',
        borderRadius: 4,
        overflow: 'hidden'
      }}
    >
      {children}
    </View>
  );
};

export const MarkdownTableRow = ({
  children,
  isHeader
}: { children: React.ReactNode; isHeader?: boolean }) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View
      style={{
        flexDirection: 'row',
        backgroundColor: isHeader ? (isDarkMode ? '#2D2D2D' : '#F6F8FA') : 'transparent',
        borderBottomWidth: 1,
        borderBottomColor: isDarkMode ? '#444444' : '#DDDDDD'
      }}
    >
      {children}
    </View>
  );
};

export const MarkdownTableCell = ({
  children,
  isHeader
}: { children: React.ReactNode; isHeader?: boolean }) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View
      style={{
        flex: 1,
        padding: 8,
        borderRightWidth: 1,
        borderRightColor: isDarkMode ? '#444444' : '#DDDDDD'
      }}
    >
      <Text
        style={{
          fontWeight: isHeader ? 'bold' : 'normal',
          color: isDarkMode ? '#CCCCCC' : '#24292E'
        }}
      >
        {children}
      </Text>
    </View>
  );
};
