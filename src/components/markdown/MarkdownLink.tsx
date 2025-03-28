import type React from 'react';
import { Linking, Text, useColorScheme } from 'react-native';
import RNFS from 'react-native-fs';

// Link renderer
const MarkdownLink = ({
  href,
  children,
  currentFilePath,
  scrollToHeading
}: {
  href: string;
  children: React.ReactNode;
  currentFilePath?: string;
  scrollToHeading?: (id: string) => void;
}) => {
  const isDarkMode = useColorScheme() === 'dark';

  const handlePress = async () => {
    if (href) {
      // Handle fragment/anchor links within the current document
      if (href.startsWith('#') && scrollToHeading) {
        const headingId = href.substring(1); // Remove the # character
        console.log('Scrolling to heading with id:', headingId);
        scrollToHeading(headingId);
        return;
      }

      // Handle different URL types
      let urlToOpen = href;

      try {
        // Handle relative paths by resolving them against the current file path
        if (
          href.startsWith('./') ||
          href.startsWith('../') ||
          (!href.includes(':') && !href.startsWith('#'))
        ) {
          console.log('Handling relative link:', href);

          if (currentFilePath) {
            // Get the directory of the current file
            const currentDir = currentFilePath.substring(0, currentFilePath.lastIndexOf('/'));

            // Resolve the relative path
            let resolvedPath;
            if (href.startsWith('./')) {
              // For ./path format
              resolvedPath = `${currentDir}/${href.substring(2)}`;
            } else if (href.startsWith('../')) {
              // For ../path format - go up one directory
              const parentDir = currentDir.substring(0, currentDir.lastIndexOf('/'));
              resolvedPath = `${parentDir}/${href.substring(3)}`;
            } else {
              // For simple filename, assume same directory
              resolvedPath = `${currentDir}/${href}`;
            }

            console.log('Resolved path:', resolvedPath);

            // Handle filename with hash/fragment
            let fragment = '';
            if (resolvedPath.includes('#')) {
              const [pathPart, hashPart] = resolvedPath.split('#');
              resolvedPath = pathPart;
              fragment = hashPart;
            }

            // Check if the file exists before trying to open it
            if (await RNFS.exists(resolvedPath)) {
              console.log('File exists, attempting to open');

              // If this is a markdown file, we can handle it within the app
              if (resolvedPath.endsWith('.md') || resolvedPath.endsWith('.markdown')) {
                // Read the file content
                const content = await RNFS.readFile(resolvedPath, 'utf8');

                // Dispatch an event to notify the app to open this file in a new tab
                const openMarkdownFile = (global as any).openMarkdownFile;
                console.log('Calling openMarkdownFile with path:', resolvedPath);
                if (openMarkdownFile) {
                  openMarkdownFile(resolvedPath, content, true);

                  // If there was a fragment and it's the same file, wait briefly then scroll
                  if (fragment && resolvedPath === currentFilePath && scrollToHeading) {
                    setTimeout(() => {
                      scrollToHeading(fragment);
                    }, 300); // Small delay to allow render
                  }

                  return; // Exit early as we're handling this in-app
                }
              }

              // For external file URLs
              urlToOpen = `file://${resolvedPath}`;
              if (fragment) {
                urlToOpen += `#${fragment}`;
              }
            } else {
              console.warn('Resolved file does not exist:', resolvedPath);
            }
          } else {
            console.warn('Cannot resolve relative path without current file path');
          }
        }

        // For file:// URLs, make sure they're properly encoded
        if (href.startsWith('file://')) {
          const fileUrl = new URL(href);
          // Make sure the path part is properly encoded
          urlToOpen = fileUrl.toString();
          console.log('Encoded file URL:', urlToOpen);
        }

        // For http/https links, ensure they're properly formatted
        if (href.startsWith('http://') || href.startsWith('https://')) {
          // Parse and re-stringify to handle any encoding issues
          const httpUrl = new URL(href);
          urlToOpen = httpUrl.toString();
        }

        console.log('Opening URL:', urlToOpen);
        Linking.openURL(urlToOpen).catch((err) => {
          console.error('Failed to open URL:', err);
        });
      } catch (error) {
        console.error('Error processing URL:', error);
        // Fallback to original URL if there was an error parsing
        Linking.openURL(href).catch((err) => {
          console.error('Failed to open URL:', err);
        });
      }
    }
  };

  return (
    <Text
      style={{
        color: isDarkMode ? '#58A6FF' : '#0366D6',
        textDecorationLine: 'underline'
      }}
      onPress={handlePress}
    >
      {children}
    </Text>
  );
};

export default MarkdownLink;
