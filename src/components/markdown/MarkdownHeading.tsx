import React, { useState } from 'react';
import {
  Animated,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
  useColorScheme
} from 'react-native';

// Top Arrow component that appears on hover
const ScrollToTopArrow = ({
  onPress,
  isDarkMode
}: {
  onPress: () => void;
  isDarkMode: boolean;
}) => {
  const opacity = useState(new Animated.Value(0))[0];

  React.useEffect(() => {
    Animated.timing(opacity, {
      toValue: 1,
      duration: 150,
      useNativeDriver: true
    }).start();

    return () => {
      Animated.timing(opacity, {
        toValue: 0,
        duration: 100,
        useNativeDriver: true
      }).start();
    };
  }, [opacity]);

  return (
    <Animated.View
      style={[
        styles.arrowContainer,
        {
          opacity,
          backgroundColor: isDarkMode ? 'rgba(60, 60, 70, 0.85)' : 'rgba(230, 235, 240, 0.9)'
        }
      ]}
    >
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [styles.arrowButton, { opacity: pressed ? 0.7 : 1 }]}
        accessibilityLabel="Scroll to top"
        accessibilityRole="button"
      >
        <Text
          style={{
            color: isDarkMode ? '#FFFFFF' : '#000000',
            fontSize: 12,
            fontWeight: '600'
          }}
        >
          ↑
        </Text>
      </Pressable>
    </Animated.View>
  );
};

// Heading renderer with different heading levels
const MarkdownHeading = ({
  level,
  children,
  id,
  scrollToTop
}: {
  level: number;
  children: React.ReactNode;
  id?: string;
  scrollToTop?: () => void;
}) => {
  const isDarkMode = useColorScheme() === 'dark';
  const [isHovering, setIsHovering] = useState(false);

  const styles = {
    h1: {
      fontSize: 32,
      fontWeight: 'bold' as const,
      marginBottom: 16,
      marginTop: 24,
      color: isDarkMode ? '#E6E6E6' : '#000000',
      borderBottomWidth: 1,
      borderBottomColor: isDarkMode ? '#444444' : '#EEEEEE',
      paddingBottom: 8
    },
    h2: {
      fontSize: 24,
      fontWeight: 'bold' as const,
      marginBottom: 12,
      marginTop: 20,
      color: isDarkMode ? '#E6E6E6' : '#000000'
    },
    h3: {
      fontSize: 20,
      fontWeight: 'bold' as const,
      marginBottom: 8,
      marginTop: 16,
      color: isDarkMode ? '#E6E6E6' : '#000000'
    },
    h4: {
      fontSize: 18,
      fontWeight: 'bold' as const,
      marginBottom: 8,
      marginTop: 16,
      color: isDarkMode ? '#E6E6E6' : '#000000'
    },
    h5: {
      fontSize: 16,
      fontWeight: 'bold' as const,
      marginBottom: 8,
      marginTop: 12,
      color: isDarkMode ? '#E6E6E6' : '#000000'
    },
    h6: {
      fontSize: 14,
      fontWeight: 'bold' as const,
      marginBottom: 8,
      marginTop: 12,
      color: isDarkMode ? '#E6E6E6' : '#000000'
    }
  };

  const baseStyle = {
    flex: 1
  };

  const headingStyle = {
    1: { ...styles.h1, ...baseStyle },
    2: { ...styles.h2, ...baseStyle },
    3: { ...styles.h3, ...baseStyle },
    4: { ...styles.h4, ...baseStyle },
    5: { ...styles.h5, ...baseStyle },
    6: { ...styles.h6, ...baseStyle }
  }[level] || { ...styles.h6, ...baseStyle };

  // Handle hover events - only on web/desktop platforms
  const hoverProps =
    Platform.OS === 'web' || Platform.OS === 'macos'
      ? {
          onMouseEnter: () => setIsHovering(true),
          onMouseLeave: () => setIsHovering(false)
        }
      : {};

  return (
    <View id={id} style={styles.headingContainer} {...hoverProps}>
      <Text style={[headingStyle, styles.headingInline]}>
        {children}
        {isHovering && scrollToTop && (
          <Text
            style={[
              styles.inlineArrow,
              {
                color: isDarkMode ? '#CCCCCC' : '#555555',
                backgroundColor: isDarkMode ? 'rgba(80, 80, 90, 0.4)' : 'rgba(230, 230, 235, 0.7)'
              }
            ]}
            onPress={scrollToTop}
          >
            {' '}
            ↑
          </Text>
        )}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  headingContainer: {
    position: 'relative'
  },
  headingInline: {
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'nowrap'
  },
  inlineArrow: {
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 8,
    marginRight: 4,
    opacity: 0.8,
    paddingHorizontal: 4,
    paddingVertical: 2,
    borderRadius: 4,
    overflow: 'hidden',
    backgroundColor: 'rgba(200, 200, 200, 0.2)'
  },
  // Keep these for the ScrollToTopArrow component
  arrowContainer: {
    marginLeft: 8,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.15,
    shadowRadius: 1,
    elevation: 1
  },
  arrowButton: {
    paddingHorizontal: 6,
    height: 20,
    width: 20,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row'
  }
});

export default MarkdownHeading;
