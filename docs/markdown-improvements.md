# Markdown Rendering Improvements for Bergen

This document outlines the steps needed to enhance markdown rendering in the Bergen app to support advanced features like links, tables, code highlighting, and formatting.

## Current Implementation

Currently, Bergen implements a basic markdown parser in `App.tsx` that can render:
- Headers (H1, H2, H3)
- Paragraphs
- Code blocks (with syntax highlighting via prism-react-renderer)
- Basic lists

## Proposed Architecture

To improve the markdown support, we should:

1. Refactor the components into a modular structure
2. Use a proper markdown parsing library
3. Add support for more markdown features

### Component Structure

Create a directory structure for components:

```
src/
├── components/
│   ├── FileItem.tsx               # File browser item component
│   ├── markdown/
│   │   ├── CodeBlock.tsx          # Code block with syntax highlighting
│   │   ├── InlineCode.tsx         # Inline code formatting
│   │   ├── MarkdownBlockquote.tsx # Blockquote component
│   │   ├── MarkdownHeading.tsx    # Headings (h1-h6)
│   │   ├── MarkdownHr.tsx         # Horizontal rule
│   │   ├── MarkdownLink.tsx       # Clickable links
│   │   ├── MarkdownListItem.tsx   # List items
│   │   ├── TableComponents.tsx    # Table, row and cell components
│   │   ├── TextElements.tsx       # Text, strong, emphasis components
│   │   └── MarkdownViewer.tsx     # Main markdown renderer
```

### Required Dependencies

Add these dependencies to package.json:

```json
"dependencies": {
  "prism-react-renderer": "^2.4.1",
  "react-markdown": "^8.0.7",
  "remark-gfm": "^4.0.1"
}
```

If `react-markdown` causes issues with React Native for macOS, we could use:

```json
"dependencies": {
  "simple-markdown": "^0.7.3"
}
```

### Implementation Approach

#### Option 1: Using react-markdown (preferred)

```jsx
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

const MarkdownViewer = ({content}) => {
  // Configure renderers for all markdown elements
  const renderers = {
    code: ({node, inline, className, children, ...props}) => {
      // Code highlighting logic
    },
    a: ({href, children}) => (
      <MarkdownLink href={href}>{children}</MarkdownLink>
    ),
    // More renderers for other elements
  };

  return (
    <ScrollView>
      <ReactMarkdown 
        remarkPlugins={[remarkGfm]}
        components={renderers}
      >
        {content}
      </ReactMarkdown>
    </ScrollView>
  );
};
```

#### Option 2: Custom Parser (fallback)

```jsx
const MarkdownViewer = ({content}) => {
  const processInlineElements = (text) => {
    // Process **bold**, *italic*, `code`, and [links](url)
  };

  const renderMarkdown = () => {
    const lines = content.split('\n');
    const elements = [];
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      // Process each line based on pattern (headers, lists, code blocks, etc.)
      // Use the specialized components for each type
    }
    
    return elements;
  };

  return (
    <ScrollView>
      {renderMarkdown()}
    </ScrollView>
  );
};
```

## Features to Support

- **Headings**: h1-h6 with proper styling
- **Text formatting**: Bold, italic, strikethrough
- **Links**: Clickable with proper styling
- **Lists**: Ordered and unordered, nested lists
- **Code blocks**: Syntax highlighting with language support
- **Inline code**: Monospace with background
- **Blockquotes**: Styled quotes with left border
- **Tables**: Properly aligned with headers
- **Horizontal rules**: Styled dividers
- **Images**: If needed

## Testing and Validation

Create test files to validate all markdown features:

```markdown
# Heading 1
## Heading 2
### Heading 3

**Bold text** and *italic text* and `inline code`

[Link to website](https://example.com)

> This is a blockquote

- Unordered list item
- Another item
  - Nested item

1. Ordered list item
2. Second item

| Column 1 | Column 2 |
| -------- | -------- |
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |

```code block with syntax highlighting
function hello() {
  console.log('Hello world');
}
```

---

Horizontal rule above
```

This enhanced markdown rendering will significantly improve the user experience by providing proper formatting for all standard markdown elements.