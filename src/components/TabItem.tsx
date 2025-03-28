import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View, useColorScheme } from 'react-native';

// Component to render a tab in the tab bar
const TabItem = ({
  title,
  isActive,
  onPress,
  onClose
}: {
  title: string;
  isActive: boolean;
  onPress: () => void;
  onClose: () => void;
}) => {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <TouchableOpacity
      style={[
        styles.tabItem,
        {
          backgroundColor: isActive
            ? isDarkMode
              ? '#2C2C2E'
              : '#FFFFFF'
            : isDarkMode
              ? '#1C1C1E'
              : '#F2F2F7',
          borderColor: isDarkMode ? '#3A3A3C' : '#DDDDDD'
        }
      ]}
      onPress={onPress}
    >
      <Text
        style={[
          styles.tabTitle,
          {
            color: isActive
              ? isDarkMode
                ? '#FFFFFF'
                : '#000000'
              : isDarkMode
                ? '#8E8E93'
                : '#8E8E93'
          }
        ]}
        numberOfLines={1}
        ellipsizeMode="middle"
      >
        {title}
      </Text>
      <TouchableOpacity
        style={styles.closeButton}
        onPress={onClose}
        hitSlop={{ top: 10, left: 10, bottom: 10, right: 10 }}
      >
        <Text
          style={{
            color: isDarkMode ? '#8E8E93' : '#8E8E93',
            fontSize: 14,
            fontWeight: '300'
          }}
        >
          ×
        </Text>
      </TouchableOpacity>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  tabItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    height: 28,
    marginLeft: 4,
    marginRight: 2,
    marginTop: 6,
    borderTopLeftRadius: 6,
    borderTopRightRadius: 6,
    borderWidth: 1,
    borderBottomWidth: 0,
    minWidth: 160,
    maxWidth: 280
  },
  tabTitle: {
    fontSize: 12,
    flex: 1,
    marginRight: 4
  },
  closeButton: {
    width: 16,
    height: 16,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8
  }
});

export default TabItem;
