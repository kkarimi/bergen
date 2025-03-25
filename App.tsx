import React, {useState, useEffect} from 'react';
import { Highlight, themes } from 'prism-react-renderer'
import {
  SafeAreaView,
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  useColorScheme,
  NativeModules,
  NativeEventEmitter,
} from 'react-native';
import RNFS from 'react-native-fs';

// Get native modules
const { NativeMenuModule, FileManagerModule } = NativeModules;

// Component to render file item in sidebar
const FileItem = ({
  name,
  isDirectory,
  isSelected,
  onPress,
}: {
  name: string;
  isDirectory: boolean;
  isSelected: boolean;
  onPress: () => void;
}) => {
  const isDarkMode = useColorScheme() === 'dark';
  
  return (
    <TouchableOpacity
      style={[
        styles.fileItem,
        isSelected && styles.selectedFile,
        isSelected && {backgroundColor: isDarkMode ? '#3A3A3C' : '#E5E5EA'},
      ]}
      onPress={onPress}>
      <Text
        style={[
          styles.fileName,
          {color: isDarkMode ? '#FFFFFF' : '#000000'},
          isDirectory && styles.directoryName,
        ]}>
        {isDirectory ? '📁 ' : '📄 '}
        {name}
      </Text>
    </TouchableOpacity>
  );
};

// Unified component for markdown rendering and code highlighting
const MarkdownViewer = ({content}: {content: string}) => {
  const isDarkMode = useColorScheme() === 'dark';
  
  // Enhanced markdown styles
  const markdownStyles = StyleSheet.create({
    container: {
      flex: 1,
      paddingHorizontal: 20,
      paddingVertical: 20,
      backgroundColor: isDarkMode ? '#1E1E1E' : '#FFFFFF',
    },
    heading1: {
      fontSize: 32, 
      fontWeight: 'bold',
      marginBottom: 16,
      marginTop: 24,
      color: isDarkMode ? '#E6E6E6' : '#000000',
      borderBottomWidth: 1,
      borderBottomColor: isDarkMode ? '#444444' : '#EEEEEE',
      paddingBottom: 8,
    },
    heading2: {
      fontSize: 24, 
      fontWeight: 'bold',
      marginBottom: 12,
      marginTop: 20,
      color: isDarkMode ? '#E6E6E6' : '#000000',
    },
    heading3: {
      fontSize: 20, 
      fontWeight: 'bold',
      marginBottom: 8,
      marginTop: 16,
      color: isDarkMode ? '#E6E6E6' : '#000000',
    },
    paragraph: {
      fontSize: 16,
      marginBottom: 12,
      lineHeight: 24,
      color: isDarkMode ? '#CCCCCC' : '#24292E',
    },
    codeBlock: {
      marginVertical: 12,
      backgroundColor: isDarkMode ? '#282C34' : '#F6F8FA',
      padding: 16,
      borderRadius: 6,
    },
    codeText: {
      fontFamily: 'Menlo',
      fontSize: 14,
      color: isDarkMode ? '#E6E6E6' : '#24292E',
    },
    listItem: {
      flexDirection: 'row', 
      marginVertical: 4,
      paddingLeft: 8,
    },
    listBullet: {
      color: isDarkMode ? '#CCCCCC' : '#24292E',
      marginRight: 8,
      width: 16,
    },
    listText: {
      color: isDarkMode ? '#CCCCCC' : '#24292E',
      flex: 1,
      fontSize: 16,
      lineHeight: 24,
    },
    blockquote: {
      borderLeftWidth: 4,
      borderLeftColor: isDarkMode ? '#444444' : '#DDDDDD',
      paddingLeft: 16,
      marginVertical: 12,
      backgroundColor: isDarkMode ? '#222222' : '#F6F8FA',
      padding: 12,
      borderRadius: 4,
    },
    blockquoteText: {
      color: isDarkMode ? '#BBBBBB' : '#6A737D',
      fontStyle: 'italic',
    },
    strong: {
      fontWeight: 'bold',
    },
    emphasis: {
      fontStyle: 'italic',
    },
    horizontalRule: {
      height: 1,
      backgroundColor: isDarkMode ? '#444444' : '#EEEEEE',
      marginVertical: 16,
    },
    link: {
      color: isDarkMode ? '#58A6FF' : '#0366D6',
      textDecorationLine: 'underline',
    },
  });
  
  // Code highlighting component (inlined)
  const renderCodeBlock = (code: string, language: string) => {
    return (
      <Highlight
        theme={themes.shadesOfPurple}
        code={code}
        language={language || 'text'}
      >
        {({ className, style, tokens, getLineProps, getTokenProps }) => (
          <View style={{
            backgroundColor: style.backgroundColor,
            padding: 10,
            borderRadius: 5,
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
  
  // Markdown processing logic
  let inCodeBlock = false;
  let codeBlockContent = '';
  let codeBlockLanguage = '';
  
  const lines = content.split('\n');
  const processedLines: JSX.Element[] = [];
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();
    
    // Handle code blocks
    if (trimmedLine.startsWith('```')) {
      if (!inCodeBlock) {
        inCodeBlock = true;
        codeBlockContent = '';
        codeBlockLanguage = trimmedLine.substring(3).trim();
      } else {
        // End of code block - render with syntax highlighting
        inCodeBlock = false;
        processedLines.push(
          <View key={`code-${i}`} style={markdownStyles.codeBlock}>
            {renderCodeBlock(codeBlockContent, codeBlockLanguage)}
          </View>
        );
      }
      continue;
    }
    
    if (inCodeBlock) {
      codeBlockContent += line + '\n';
      continue;
    }
    
    // Normal markdown processing
    if (trimmedLine.startsWith('# ')) {
      processedLines.push(
        <Text key={`h1-${i}`} style={markdownStyles.heading1}>
          {trimmedLine.substring(2)}
        </Text>
      );
    } else if (trimmedLine.startsWith('## ')) {
      processedLines.push(
        <Text key={`h2-${i}`} style={markdownStyles.heading2}>
          {trimmedLine.substring(3)}
        </Text>
      );
    } else if (trimmedLine.startsWith('### ')) {
      processedLines.push(
        <Text key={`h3-${i}`} style={markdownStyles.heading3}>
          {trimmedLine.substring(4)}
        </Text>
      );
    } else if (trimmedLine.startsWith('> ')) {
      // Blockquote
      processedLines.push(
        <View key={`blockquote-${i}`} style={markdownStyles.blockquote}>
          <Text style={markdownStyles.blockquoteText}>
            {trimmedLine.substring(2)}
          </Text>
        </View>
      );
    } else if (trimmedLine === '---' || trimmedLine === '___' || trimmedLine === '***') {
      // Horizontal rule
      processedLines.push(
        <View key={`hr-${i}`} style={markdownStyles.horizontalRule} />
      );
    } else if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
      // Unordered list item
      processedLines.push(
        <View key={`ul-${i}`} style={markdownStyles.listItem}>
          <Text style={markdownStyles.listBullet}>•</Text>
          <Text style={markdownStyles.listText}>
            {trimmedLine.substring(2)}
          </Text>
        </View>
      );
    } else if (/^\d+\./.test(trimmedLine)) {
      // Numbered list
      const number = trimmedLine.split('.')[0];
      processedLines.push(
        <View key={`ol-${i}`} style={markdownStyles.listItem}>
          <Text style={markdownStyles.listBullet}>{number}.</Text>
          <Text style={markdownStyles.listText}>
            {trimmedLine.substring(trimmedLine.indexOf('.') + 1).trim()}
          </Text>
        </View>
      );
    } else if (trimmedLine === '') {
      // Empty line
      processedLines.push(<View key={`space-${i}`} style={{height: 12}} />);
    } else {
      // Regular paragraph
      // For simplicity, we're not handling inline formatting like bold/italic
      processedLines.push(
        <Text key={`p-${i}`} style={markdownStyles.paragraph}>
          {line}
        </Text>
      );
    }
  }
  
  return (
    <ScrollView style={markdownStyles.container}>
      {processedLines}
    </ScrollView>
  );
};

const App = () => {
  // Default to Documents directory for initial path
  const [currentPath, setCurrentPath] = useState(RNFS.DocumentDirectoryPath);
  const [files, setFiles] = useState<RNFS.ReadDirItem[]>([]);
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [fileContent, setFileContent] = useState<string>('');
  const [isSidebarCollapsed, setSidebarCollapsed] = useState(true);
  const isDarkMode = useColorScheme() === 'dark';
  
  // Set up native event listeners for menu actions
  useEffect(() => {
    // Initialize native event emitter
    const menuEventEmitter = new NativeEventEmitter(NativeMenuModule);
    
    // Listen for file menu actions
    const fileMenuSubscription = menuEventEmitter.addListener(
      'fileMenuAction',
      (event) => {
        console.log('Received file menu action:', event);
        if (event.action === 'fileSelected' && event.path) {
          console.log('Will handle selected file:', event.path);
          handleSelectedFile(event.path);
        }
      }
    );
    
    // Listen for view menu actions
    const viewMenuSubscription = menuEventEmitter.addListener(
      'viewMenuAction',
      (event) => {
        console.log('Received view menu action:', event);
        if (event.action === 'toggleSidebar') {
          console.log('Toggling sidebar visibility to:', event.show);
          setSidebarCollapsed(!event.show);
        }
      }
    );
    
    // Clean up subscriptions
    return () => {
      fileMenuSubscription.remove();
      viewMenuSubscription.remove();
    };
  }, []);
  
  // Handle file selection from native file picker
  const handleSelectedFile = async (filePath: string) => {
    console.log('handleSelectedFile called with:', filePath);
    
    if (!filePath.endsWith('.md') && !filePath.endsWith('.markdown')) {
      console.warn('Not a markdown file:', filePath);
      return;
    }
    
    try {
      // Update the current directory to the parent directory of the selected file
      const parentPath = filePath.substring(0, filePath.lastIndexOf('/'));
      console.log('Setting current path to:', parentPath);
      setCurrentPath(parentPath);
      
      // Load file content
      console.log('Reading file content...');
      const content = await RNFS.readFile(filePath, 'utf8');
      console.log('File content loaded, length:', content.length);
      
      // Set selected file and content
      console.log('Updating state with selected file and content');
      setSelectedFile(filePath);
      setFileContent(content);
      
      // Refresh file list
      console.log('Refreshing file list...');
      const dirItems = await RNFS.readDir(parentPath);
      setFiles(dirItems.sort((a, b) => {
        if (a.isDirectory() && !b.isDirectory()) return -1;
        if (!a.isDirectory() && b.isDirectory()) return 1;
        return a.name.localeCompare(b.name);
      }));
      console.log('File list updated with', dirItems.length, 'items');
    } catch (error) {
      console.error('Failed to load selected file:', error);
      setFileContent('Error loading file content.');
    }
  };
  
  // Initialize the file list without automatically opening welcome.md
  useEffect(() => {
    // Skip if a file is already selected
    if (selectedFile && fileContent) {
      return;
    }
    
    // Just load the file list without auto-opening welcome.md
    const loadFileList = async () => {
      try {
        const results = await RNFS.readDir(currentPath);
        setFiles(results.sort((a, b) => {
          if (a.isDirectory() && !b.isDirectory()) return -1;
          if (!a.isDirectory() && b.isDirectory()) return 1;
          return a.name.localeCompare(b.name);
        }));
      } catch (error) {
        console.error('Failed to read directory:', error);
      }
    };
    
    loadFileList();
  }, [currentPath, selectedFile, fileContent]);

  // Load files from the current directory
  useEffect(() => {
    const loadFiles = async () => {
      try {
        const results = await RNFS.readDir(currentPath);
        // Sort by directories first, then by name
        results.sort((a, b) => {
          if (a.isDirectory() && !b.isDirectory()) return -1;
          if (!a.isDirectory() && b.isDirectory()) return 1;
          return a.name.localeCompare(b.name);
        });
        setFiles(results);
      } catch (error) {
        console.error('Failed to read directory:', error);
      }
    };

    loadFiles();
  }, [currentPath]);

  // Handle file selection
  const handleFilePress = async (file: RNFS.ReadDirItem) => {
    if (file.isDirectory()) {
      setCurrentPath(file.path);
      setSelectedFile(null);
      setFileContent('');
    } else if (file.name.toLowerCase().endsWith('.md')) {
      setSelectedFile(file.path);
      try {
        const content = await RNFS.readFile(file.path, 'utf8');
        setFileContent(content);
      } catch (error) {
        console.error('Failed to read file:', error);
        setFileContent('Error loading file content.');
      }
    }
  };

  // Go up one directory
  const navigateUp = () => {
    const parentPath = currentPath.split('/').slice(0, -1).join('/');
    if (parentPath) {
      setCurrentPath(parentPath);
      setSelectedFile(null);
      setFileContent('');
    }
  };
  
  // Open file dialog to select any markdown file
  const openFilePicker = async () => {
    try {
      if (FileManagerModule) {
        // Use the native file picker
        const filePath = await FileManagerModule.showOpenDialog();
        if (filePath) {
          handleSelectedFile(filePath);
        }
      } else {
        console.warn('FileManagerModule not available. Falling back to default directory');
        // Fallback: open the user's home directory
        const homePath = RNFS.DocumentDirectoryPath.split('/').slice(0, 3).join('/') + '/Documents';
        if (await RNFS.exists(homePath)) {
          setCurrentPath(homePath);
          setSelectedFile(null);
          setFileContent('');
        }
      }
    } catch (error) {
      console.error('Failed to open file picker:', error);
    }
  };

  // Toggle sidebar collapsed state
  const toggleSidebar = () => {
    setSidebarCollapsed(!isSidebarCollapsed);
  };

  return (
    <SafeAreaView style={[
      styles.container,
      {backgroundColor: isDarkMode ? '#000000' : '#FFFFFF'}
    ]}>
      <View style={styles.appContainer}>
        {/* Sidebar collapse button */}
        <TouchableOpacity 
          style={[
            styles.collapseButton,
            {backgroundColor: isDarkMode ? '#2C2C2E' : '#E5E5EA'}
          ]}
          onPress={toggleSidebar}>
          <Text style={{
            color: isDarkMode ? '#2C9BF0' : '#007AFF',
            fontSize: 16,
            fontWeight: 'bold'
          }}>
            {isSidebarCollapsed ? '›' : '‹'}
          </Text>
        </TouchableOpacity>

        {/* Sidebar */}
        {!isSidebarCollapsed && (
          <View style={[
            styles.sidebar, 
            {backgroundColor: isDarkMode ? '#1C1C1E' : '#F2F2F7'}
          ]}>
            <View style={styles.navigationHeader}>
              <TouchableOpacity 
                style={styles.navigationButton} 
                onPress={navigateUp}>
                <Text style={{color: isDarkMode ? '#2C9BF0' : '#007AFF'}}>↑ Up</Text>
              </TouchableOpacity>
              <Text 
                style={[
                  styles.currentPathText,
                  {color: isDarkMode ? '#FFFFFF' : '#000000'}
                ]} 
                numberOfLines={1}>
                {currentPath.split('/').pop()}
              </Text>
            </View>
            <View style={styles.actionHeader}>
              <TouchableOpacity 
                style={[
                  styles.actionButton,
                  {backgroundColor: isDarkMode ? '#2C2C2E' : '#E5E5EA'}
                ]} 
                onPress={openFilePicker}>
                <Text style={{color: isDarkMode ? '#2C9BF0' : '#007AFF'}}>📂 Open File</Text>
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.fileList}>
              {files.map((file, index) => (
                <FileItem
                  key={index}
                  name={file.name}
                  isDirectory={file.isDirectory()}
                  isSelected={selectedFile === file.path}
                  onPress={() => handleFilePress(file)}
                />
              ))}
              {files.length === 0 && (
                <Text style={[
                  styles.emptyDirectoryText,
                  {color: isDarkMode ? '#8E8E93' : '#8E8E93'}
                ]}>
                  Empty directory
                </Text>
              )}
            </ScrollView>
          </View>
        )}

        {/* Main content area */}
        <View style={[
          styles.contentArea,
          isSidebarCollapsed && styles.expandedContent
        ]}>
          {selectedFile && fileContent ? (
            <>
              <View style={styles.filePathDisplay}>
                <Text style={{
                  fontSize: 12,
                  color: isDarkMode ? '#8E8E93' : '#8E8E93',
                  marginBottom: 5
                }}>
                  File: {selectedFile.split('/').pop()}
                </Text>
              </View>
              <MarkdownViewer content={fileContent} />
            </>
          ) : (
            <View style={[
              styles.noFileSelected,
              {backgroundColor: isDarkMode ? '#1C1C1E' : '#F2F2F7'}
            ]}>
              <Text style={{
                fontSize: 20, 
                fontWeight: 'bold',
                color: isDarkMode ? '#FFFFFF' : '#000000',
                textAlign: 'center',
                marginBottom: 16
              }}>
                Welcome to Bergen Markdown Viewer
              </Text>
              <Text style={{
                fontSize: 16, 
                color: isDarkMode ? '#8E8E93' : '#8E8E93',
                textAlign: 'center',
                marginBottom: 32
              }}>
                Get started by opening a markdown file
              </Text>
              <TouchableOpacity 
                style={[
                  styles.openFileButton,
                  {backgroundColor: isDarkMode ? '#2C9BF0' : '#007AFF'}
                ]} 
                onPress={openFilePicker}>
                <Text style={{
                  color: '#FFFFFF',
                  fontSize: 16,
                  fontWeight: 'bold'
                }}>
                  Open Markdown File
                </Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  appContainer: {
    flex: 1,
    flexDirection: 'row',
  },
  collapseButton: {
    width: 24,
    alignItems: 'center',
    justifyContent: 'center',
    borderRightWidth: 1,
    borderRightColor: '#DDDDDD',
    zIndex: 10,
  },
  sidebar: {
    width: 250,
    borderRightWidth: 1,
    borderRightColor: '#DDDDDD',
  },
  navigationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#DDDDDD',
  },
  actionHeader: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#DDDDDD',
  },
  navigationButton: {
    paddingVertical: 5,
    paddingHorizontal: 10,
  },
  actionButton: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    alignItems: 'center',
  },
  currentPathText: {
    fontSize: 12,
    marginLeft: 10,
    flex: 1,
  },
  fileList: {
    flex: 1,
  },
  fileItem: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#EEEEEE',
  },
  selectedFile: {
    backgroundColor: '#E5E5EA',
  },
  fileName: {
    fontSize: 14,
  },
  directoryName: {
    fontWeight: 'bold',
  },
  contentArea: {
    flex: 1,
  },
  expandedContent: {
    flex: 1,
  },
  noFileSelected: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  webView: {
    flex: 1,
  },
  emptyDirectoryText: {
    padding: 15,
    textAlign: 'center',
    fontStyle: 'italic',
  },
  filePathDisplay: {
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 5,
    borderBottomWidth: 1,
    borderBottomColor: '#EEEEEE',
  },
  openFileButton: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
});

export default App;