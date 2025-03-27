import type React from 'react';
import { useState } from 'react';
import { ActivityIndicator, StyleSheet, View, useColorScheme } from 'react-native';
import { WebView } from 'react-native-webview';

interface MermaidDiagramProps {
  value: string;
}

const MermaidDiagram: React.FC<MermaidDiagramProps> = ({ value }) => {
  const isDarkMode = useColorScheme() === 'dark';
  const [loading, setLoading] = useState(true);

  // Sanitize the Mermaid diagram definition
  const sanitizedValue = value.replace(/"/g, '&quot;');

  // HTML template with Mermaid library
  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Mermaid Diagram</title>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
        <style>
          body {
            margin: 0;
            padding: 0;
            background-color: ${isDarkMode ? '#1E1E1E' : '#FFFFFF'};
            display: flex;
            justify-content: center;
          }
          #diagram {
            width: 100%;
            display: flex;
            justify-content: center;
          }
          svg {
            max-width: 100%;
          }
        </style>
        <script>
          document.addEventListener('DOMContentLoaded', function() {
            mermaid.initialize({
              startOnLoad: true,
              theme: '${isDarkMode ? 'dark' : 'default'}',
              securityLevel: 'loose'
            });
            
            window.addEventListener('load', function() {
              // Notify React Native when rendering is complete
              window.ReactNativeWebView.postMessage('rendered');
            });
          });
        </script>
      </head>
      <body>
        <div id="diagram" class="mermaid">
          ${sanitizedValue}
        </div>
      </body>
    </html>
  `;

  const styles = StyleSheet.create({
    container: {
      height: 300,
      borderRadius: 5,
      overflow: 'hidden',
      marginVertical: 10,
      backgroundColor: isDarkMode ? '#1E1E1E' : '#FFFFFF'
    },
    loadingContainer: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: isDarkMode ? '#1E1E1E' : '#FFFFFF'
    },
    webView: {
      backgroundColor: isDarkMode ? '#1E1E1E' : '#FFFFFF',
      height: 300
    }
  });

  return (
    <View style={styles.container}>
      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={isDarkMode ? '#2C9BF0' : '#007AFF'} />
        </View>
      )}
      <WebView
        originWhitelist={['*']}
        source={{ html }}
        onMessage={(event) => {
          if (event.nativeEvent.data === 'rendered') {
            setLoading(false);
          }
        }}
        style={styles.webView}
      />
    </View>
  );
};

export default MermaidDiagram;
