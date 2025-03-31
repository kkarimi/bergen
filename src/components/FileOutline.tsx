import React from 'react';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View, useColorScheme } from 'react-native';

interface HeadingItem {
  level: number;
  text: string;
  position: number;
}

interface FileOutlineProps {
  headings: HeadingItem[];
  onHeadingPress: (position: number) => void;
}

const FileOutline = ({ headings, onHeadingPress }: FileOutlineProps) => {
  const isDarkMode = useColorScheme() === 'dark';

  if (headings.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={{ color: isDarkMode ? '#8E8E93' : '#8E8E93', textAlign: 'center' }}>
          No headings found in this file
        </Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      {headings.map((heading, index) => (
        <TouchableOpacity
          key={index}
          style={[styles.headingItem, { paddingLeft: 12 + heading.level * 12 }]}
          onPress={() => onHeadingPress(heading.position)}
        >
          <Text
            style={[
              styles.headingText,
              { color: isDarkMode ? '#FFFFFF' : '#000000' },
              heading.level === 1 && styles.heading1,
              heading.level === 2 && styles.heading2,
              heading.level === 3 && styles.heading3
            ]}
            numberOfLines={1}
            ellipsizeMode="tail"
          >
            {heading.text}
          </Text>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20
  },
  headingItem: {
    paddingVertical: 8,
    paddingRight: 12,
    borderRadius: 4,
    marginVertical: 2,
    marginHorizontal: 4
  },
  headingText: {
    fontSize: 13
  },
  heading1: {
    fontWeight: '700',
    fontSize: 15
  },
  heading2: {
    fontWeight: '600',
    fontSize: 14
  },
  heading3: {
    fontWeight: '500',
    fontSize: 13
  }
});

export default FileOutline;
