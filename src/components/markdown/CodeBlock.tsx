import React from 'react';
import { Highlight, themes } from 'prism-react-renderer';
import { View, Text, useColorScheme } from 'react-native';

// Code block renderer with syntax highlighting
const CodeBlock = ({language, value}: {language: string; value: string}) => {
  const isDarkMode = useColorScheme() === 'dark';
  
  return (
    <Highlight
      theme={isDarkMode ? themes.vsDark : themes.github}
      code={value}
      language={language || 'text'}
    >
      {({ className, style, tokens, getLineProps, getTokenProps }) => (
        <View style={{
          backgroundColor: style.backgroundColor,
          padding: 10,
          borderRadius: 5,
          marginVertical: 10,
        }}>
          {tokens.map((line, i) => (
            <View key={i} style={{flexDirection: 'row'}}>
              <Text style={{
                width: 30, 
                color: isDarkMode ? '#666' : '#999',
                textAlign: 'right',
                paddingRight: 5,
                fontFamily: 'Menlo',
              }}>
                {i + 1}
              </Text>
              <View style={{flexDirection: 'row', flexWrap: 'wrap', flex: 1}}>
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
                        fontFamily: 'Menlo',
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
      )}
    </Highlight>
  );
};

export default CodeBlock;