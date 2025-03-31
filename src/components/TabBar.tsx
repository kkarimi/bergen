import React from 'react';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View, useColorScheme } from 'react-native';
import TabItem from './TabItem';

interface TabData {
  id: string;
  filePath: string;
  fileName: string;
}

interface TabBarProps {
  tabs: TabData[];
  activeTabIndex: number;
  onTabPress: (index: number) => void;
  onCloseTab: (index: number) => void;
  onAddTab: () => void;
  isFileInfoSidebarVisible?: boolean;
}

const TabBar = ({
  tabs,
  activeTabIndex,
  onTabPress,
  onCloseTab,
  onAddTab,
  isFileInfoSidebarVisible
}: TabBarProps) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: isDarkMode ? '#1C1C1E' : '#F2F2F7',
          borderBottomColor: isDarkMode ? '#3A3A3C' : '#DDDDDD'
        }
      ]}
    >
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.scrollView}>
        {tabs.map((tab, index) => (
          <TabItem
            key={tab.id}
            title={tab.fileName}
            isActive={index === activeTabIndex}
            onPress={() => onTabPress(index)}
            onClose={() => onCloseTab(index)}
          />
        ))}
      </ScrollView>
      <TouchableOpacity
        style={[
          styles.addButton,
          {
            backgroundColor: isFileInfoSidebarVisible
              ? isDarkMode
                ? '#3A6CD9'
                : '#007AFF'
              : isDarkMode
                ? '#2C2C2E'
                : '#E5E5EA'
          }
        ]}
        onPress={onAddTab}
      >
        <Text
          style={{
            color: isFileInfoSidebarVisible ? '#FFFFFF' : isDarkMode ? '#2C9BF0' : '#007AFF',
            fontSize: 14,
            fontWeight: 'bold',
            lineHeight: 18
          }}
        >
          ℹ️
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    height: 36,
    flexDirection: 'row',
    borderBottomWidth: 1,
    alignItems: 'flex-end'
  },
  scrollView: {
    flex: 1,
    paddingLeft: 2
  },
  addButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: 8,
    marginBottom: 4
  }
});

export default TabBar;
