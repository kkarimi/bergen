import ClipboardModule from '@react-native-clipboard/clipboard';
import { Highlight, themes } from 'prism-react-renderer';
import React, { useState, useEffect } from 'react';
import {
  Animated,
  Pressable,
  Clipboard as RNClipboard,
  Text,
  View,
  useColorScheme
} from 'react-native';

// Fallback clipboard implementation
const Clipboard = {
  setString: (text: string) => {
    try {
      // Try to use the module
      ClipboardModule.setString(text);
    } catch (e) {
      // Fallback to built-in Clipboard API
      RNClipboard.setString(text);
    }
  }
};

// Code block renderer with syntax highlighting
const CodeBlock = ({ language, value }: { language: string; value: string }) => {
  const isDarkMode = useColorScheme() === 'dark';
  const displayLanguage = language || 'text';
  const [copied, setCopied] = useState(false);
  const fadeAnim = useState(new Animated.Value(1))[0];
  const pulseAnim = useState(new Animated.Value(1))[0];

  // Reset copied state after 2 seconds
  useEffect(() => {
    let timeout: NodeJS.Timeout;
    if (copied) {
      // Pulse animation
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.1,
          duration: 100,
          useNativeDriver: true
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 100,
          useNativeDriver: true
        })
      ]).start();

      // Fade animation
      Animated.sequence([
        Animated.timing(fadeAnim, {
          toValue: 0.7,
          duration: 200,
          useNativeDriver: true
        }),
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 200,
          useNativeDriver: true
        })
      ]).start();

      timeout = setTimeout(() => {
        setCopied(false);
      }, 2000);
    }
    return () => clearTimeout(timeout);
  }, [copied, fadeAnim, pulseAnim]);

  const handleCopy = () => {
    try {
      Clipboard.setString(value);
      setCopied(true);
    } catch (e) {
      console.error('Failed to copy to clipboard:', e);
    }
  };

  return (
    <Highlight
      theme={isDarkMode ? themes.vsDark : themes.github}
      code={value}
      language={displayLanguage}
    >
      {({ className, style, tokens, getLineProps, getTokenProps }) => (
        <View
          style={{
            backgroundColor: style.backgroundColor,
            borderRadius: 5,
            marginVertical: 10,
            overflow: 'hidden'
          }}
        >
          {/* Header with language label and copy button */}
          <View
            style={{
              backgroundColor: isDarkMode ? '#2c3136' : '#f6f8fa',
              paddingVertical: 4,
              paddingHorizontal: 10,
              borderBottomWidth: 1,
              borderBottomColor: isDarkMode ? '#1e2227' : '#e1e4e8',
              flexDirection: 'row',
              justifyContent: 'space-between',
              alignItems: 'center'
            }}
          >
            <Text
              style={{
                color: isDarkMode ? '#8b949e' : '#57606a',
                fontSize: 12,
                fontFamily: 'Menlo',
                fontWeight: '500'
              }}
            >
              {displayLanguage !== 'text' ? displayLanguage : ''}
            </Text>

            <Pressable
              onPress={handleCopy}
              style={({ pressed }) => ({
                opacity: pressed ? 0.7 : 1,
                padding: 4
              })}
              accessibilityLabel="Copy code to clipboard"
              accessibilityRole="button"
            >
              <Animated.View
                style={{
                  opacity: fadeAnim,
                  transform: [{ scale: pulseAnim }]
                }}
              >
                <Text
                  style={{
                    color: isDarkMode
                      ? copied
                        ? '#4caf50'
                        : '#8b949e'
                      : copied
                        ? '#4caf50'
                        : '#57606a',
                    fontSize: 12,
                    fontWeight: '500'
                  }}
                >
                  {copied ? '✓ Copied' : '⎘ Copy'}
                </Text>
              </Animated.View>
            </Pressable>
          </View>

          {/* Code content */}
          <View
            style={{
              padding: 10
            }}
          >
            {tokens.map((line, i) => (
              <View key={i} style={{ flexDirection: 'row' }}>
                <Text
                  style={{
                    width: 30,
                    color: isDarkMode ? '#666' : '#999',
                    textAlign: 'right',
                    paddingRight: 5,
                    fontFamily: 'Menlo'
                  }}
                >
                  {i + 1}
                </Text>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', flex: 1 }}>
                  {line.map((token, key) => {
                    const tokenProps = getTokenProps({ token });
                    const tokenStyle = tokenProps.style || {};
                    return (
                      <Text
                        key={key}
                        style={{
                          color: tokenStyle.color || (isDarkMode ? '#FFF' : '#000'),
                          fontWeight: tokenStyle.fontWeight as any,
                          fontStyle: tokenStyle.fontStyle as any,
                          fontFamily: 'Menlo'
                        }}
                      >
                        {token.content}
                      </Text>
                    );
                  })}
                </View>
              </View>
            ))}
          </View>
        </View>
      )}
    </Highlight>
  );
};

export default CodeBlock;
