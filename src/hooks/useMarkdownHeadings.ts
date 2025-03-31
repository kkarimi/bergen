import { useEffect, useState } from 'react';

interface HeadingItem {
  level: number;
  text: string;
  position: number;
}

interface TabData {
  id: string;
  filePath: string;
  fileName: string;
  content: string;
}

/**
 * Custom hook that extracts and parses headings from markdown content
 * @param getActiveTab Function that returns the currently active tab data
 * @returns Array of heading objects with level, text, and position
 */
const useMarkdownHeadings = (getActiveTab: () => TabData | undefined): HeadingItem[] => {
  const [headings, setHeadings] = useState<HeadingItem[]>([]);

  useEffect(() => {
    const activeTab = getActiveTab();
    if (activeTab?.content) {
      // Simple regex to extract headings from markdown
      const headingRegex = /^(#{1,6})\s+(.+)$/gm;
      const extractedHeadings: HeadingItem[] = [];
      const content = activeTab.content;

      // Track position in the document for scrolling
      let position = 0;
      const lines = content.split('\n');

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const match = headingRegex.exec(line);

        if (match) {
          extractedHeadings.push({
            level: match[1].length, // # = 1, ## = 2, etc.
            text: match[2].trim(),
            position: position
          });
        }

        // Reset regex for next iteration
        headingRegex.lastIndex = 0;
        position += line.length + 1; // +1 for the newline
      }

      setHeadings(extractedHeadings);
    } else {
      setHeadings([]);
    }
  }, [getActiveTab]);

  return headings;
};

export default useMarkdownHeadings;
