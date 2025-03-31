import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View, useColorScheme } from 'react-native';

interface SidebarTabProps {
  title: string;
  icon: string;
  isActive: boolean;
  onPress: () => void;
}

const SidebarTab = ({ title, icon, isActive, onPress }: SidebarTabProps) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <TouchableOpacity
      style={[
        styles.tab,
        isActive && styles.activeTab,
        {
          backgroundColor: isActive ? (isDarkMode ? '#3A3A3C' : '#E5E5EA') : 'transparent'
        }
      ]}
      onPress={onPress}
    >
      <View style={styles.tabContent}>
        <Text
          style={[
            styles.tabIcon,
            {
              color: isDarkMode
                ? isActive
                  ? '#FFFFFF'
                  : '#BBBBBB'
                : isActive
                  ? '#000000'
                  : '#666666'
            }
          ]}
        >
          {icon}
        </Text>
        <Text
          style={[
            styles.tabTitle,
            {
              color: isDarkMode
                ? isActive
                  ? '#FFFFFF'
                  : '#BBBBBB'
                : isActive
                  ? '#000000'
                  : '#666666'
            }
          ]}
        >
          {title}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  tab: {
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 6,
    marginBottom: 4,
    marginHorizontal: 4
  },
  activeTab: {},
  tabContent: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  tabIcon: {
    fontSize: 16,
    marginRight: 8
  },
  tabTitle: {
    fontSize: 13,
    fontWeight: '500'
  }
});

export default SidebarTab;
