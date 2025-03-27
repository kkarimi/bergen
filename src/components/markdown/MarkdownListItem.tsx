import type React from 'react';
import { Text, View, useColorScheme } from 'react-native';

// List item renderer
const MarkdownListItem = ({
  children,
  ordered,
  index
}: { children: React.ReactNode; ordered?: boolean; index?: number }) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View
      style={{
        flexDirection: 'row',
        marginVertical: 4,
        paddingLeft: 8
      }}
    >
      <Text
        style={{
          color: isDarkMode ? '#CCCCCC' : '#24292E',
          marginRight: 8,
          width: 16
        }}
      >
        {ordered ? `${index || 1}.` : '•'}
      </Text>
      <View style={{ flex: 1 }}>
        <Text
          style={{
            color: isDarkMode ? '#CCCCCC' : '#24292E',
            fontSize: 16,
            lineHeight: 24
          }}
        >
          {children}
        </Text>
      </View>
    </View>
  );
};

export default MarkdownListItem;
