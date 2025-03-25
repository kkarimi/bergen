import React from 'react';
import { ScrollView, StyleSheet, useColorScheme, Text, View } from 'react-native';

// Import markdown components
import CodeBlock from './CodeBlock';
import InlineCode from './InlineCode';
import MarkdownLink from './MarkdownLink';
import MarkdownHeading from './MarkdownHeading';
import { MarkdownText, MarkdownStrong, MarkdownEmphasis } from './TextElements';
import MarkdownListItem from './MarkdownListItem';
import MarkdownBlockquote from './MarkdownBlockquote';
import MarkdownHr from './MarkdownHr';

// Unified Markdown renderer component
const MarkdownViewer = ({content, filePath}: {content: string, filePath?: string}) => {
  const isDarkMode = useColorScheme() === 'dark';
  
  const markdownStyles = StyleSheet.create({
    container: {
      flex: 1,
      paddingHorizontal: 20,
      paddingVertical: 20,
      backgroundColor: isDarkMode ? '#1E1E1E' : '#FFFFFF',
    },
  });

  // Process inline elements like bold, italic, links, inline code
  const processInlineElements = (text: string): React.ReactNode[] => {
    let elements: React.ReactNode[] = [];
    let currentText = '';

    // Helper to add current text to elements
    const pushCurrentText = () => {
      if (currentText) {
        elements.push(currentText);
        currentText = '';
      }
    };

    // Process text character by character
    let i = 0;
    while (i < text.length) {
      // Bold text with **
      if (text.substr(i, 2) === '**' && i + 2 < text.length) {
        const endBold = text.indexOf('**', i + 2);
        if (endBold !== -1) {
          pushCurrentText();
          elements.push(
            <MarkdownStrong key={`bold-${i}`}>
              {processInlineElements(text.substring(i + 2, endBold))}
            </MarkdownStrong>
          );
          i = endBold + 2;
          continue;
        }
      }

      // Italic text with *
      if (text[i] === '*' && text[i+1] !== '*' && i + 1 < text.length) {
        const endItalic = text.indexOf('*', i + 1);
        if (endItalic !== -1) {
          pushCurrentText();
          elements.push(
            <MarkdownEmphasis key={`italic-${i}`}>
              {processInlineElements(text.substring(i + 1, endItalic))}
            </MarkdownEmphasis>
          );
          i = endItalic + 1;
          continue;
        }
      }

      // Inline code with `
      if (text[i] === '`') {
        const endCode = text.indexOf('`', i + 1);
        if (endCode !== -1) {
          pushCurrentText();
          elements.push(
            <InlineCode key={`code-${i}`} value={text.substring(i + 1, endCode)} />
          );
          i = endCode + 1;
          continue;
        }
      }

      // Links with [text](url)
      if (text[i] === '[') {
        const closeBracket = text.indexOf(']', i);
        if (closeBracket !== -1 && text[closeBracket + 1] === '(') {
          const closeParenthesis = text.indexOf(')', closeBracket);
          if (closeParenthesis !== -1) {
            pushCurrentText();
            const linkText = text.substring(i + 1, closeBracket);
            const linkUrl = text.substring(closeBracket + 2, closeParenthesis);
            elements.push(
              <MarkdownLink 
                key={`link-${i}`} 
                href={linkUrl}
                currentFilePath={filePath}
              >
                {processInlineElements(linkText)}
              </MarkdownLink>
            );
            i = closeParenthesis + 1;
            continue;
          }
        }
      }

      // Add current character to text buffer
      currentText += text[i];
      i++;
    }

    // Push any remaining text
    pushCurrentText();
    
    return elements;
  };

  // Process the markdown content line-by-line
  const lines = content.split('\n');
  const processedLines: JSX.Element[] = [];
  
  let inCodeBlock = false;
  let codeBlockContent = '';
  let codeBlockLanguage = '';
  
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
          <CodeBlock key={`code-${i}`} language={codeBlockLanguage} value={codeBlockContent} />
        );
      }
      continue;
    }
    
    if (inCodeBlock) {
      codeBlockContent += line + '\n';
      continue;
    }
    
    // Handle blockquotes
    if (trimmedLine.startsWith('> ')) {
      processedLines.push(
        <MarkdownBlockquote key={`blockquote-${i}`}>
          {processInlineElements(trimmedLine.substring(2))}
        </MarkdownBlockquote>
      );
      continue;
    }
    
    // Handle horizontal rules
    if (trimmedLine === '---' || trimmedLine === '___' || trimmedLine === '***') {
      processedLines.push(<MarkdownHr key={`hr-${i}`} />);
      continue;
    }
    
    // Handle unordered lists
    if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
      processedLines.push(
        <MarkdownListItem key={`ul-${i}`} ordered={false}>
          {processInlineElements(trimmedLine.substring(2))}
        </MarkdownListItem>
      );
      continue;
    }
    
    // Handle ordered lists
    if (/^\d+\./.test(trimmedLine)) {
      const number = parseInt(trimmedLine.split('.')[0], 10);
      processedLines.push(
        <MarkdownListItem key={`ol-${i}`} ordered={true} index={number}>
          {processInlineElements(trimmedLine.substring(trimmedLine.indexOf('.') + 1).trim())}
        </MarkdownListItem>
      );
      continue;
    }
    
    // Handle headings
    if (trimmedLine.startsWith('# ')) {
      processedLines.push(
        <MarkdownHeading key={`h1-${i}`} level={1}>
          {processInlineElements(trimmedLine.substring(2))}
        </MarkdownHeading>
      );
    } else if (trimmedLine.startsWith('## ')) {
      processedLines.push(
        <MarkdownHeading key={`h2-${i}`} level={2}>
          {processInlineElements(trimmedLine.substring(3))}
        </MarkdownHeading>
      );
    } else if (trimmedLine.startsWith('### ')) {
      processedLines.push(
        <MarkdownHeading key={`h3-${i}`} level={3}>
          {processInlineElements(trimmedLine.substring(4))}
        </MarkdownHeading>
      );
    } else if (trimmedLine === '') {
      // Empty line
      processedLines.push(<View key={`space-${i}`} style={{height: 12}} />);
    } else {
      // Regular paragraph
      processedLines.push(
        <MarkdownText key={`p-${i}`}>
          {processInlineElements(line)}
        </MarkdownText>
      );
    }
  }

  return (
    <ScrollView style={markdownStyles.container}>
      {processedLines}
    </ScrollView>
  );
};

export default MarkdownViewer;