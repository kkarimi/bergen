# Mermaid Diagram Support in Bergen

Bergen now supports Mermaid diagrams in markdown files. This guide explains how to use this feature.

## What is Mermaid?

Mermaid is a JavaScript-based diagramming and charting tool that renders text-based diagram definitions into visual diagrams. It's similar to Markdown in that it uses a simple syntax to create visualizations.

## Using Mermaid in Bergen

To add a Mermaid diagram to your markdown files:

1. Create a code block with language set to "mermaid"
2. Write your diagram definition using Mermaid syntax
3. Close the code block

Example:

````markdown
```mermaid
graph TD
    A[Start] --> B{Is it a markdown file?}
    B -- Yes --> C[Display with formatting]
    B -- No --> D[Show as text]
```
````

## Supported Diagram Types

Bergen supports all standard Mermaid diagram types, including:

### Flowcharts

```mermaid
graph TD
    A[Start] --> B{Decision}
    B -- Yes --> C[Process 1]
    B -- No --> D[Process 2]
    C --> E[End]
    D --> E
```

### Sequence Diagrams

```mermaid
sequenceDiagram
    Alice->>John: Hello John, how are you?
    John-->>Alice: Great!
    Alice-)John: See you later!
```

### Class Diagrams

```mermaid
classDiagram
    Animal <|-- Duck
    Animal <|-- Fish
    Animal <|-- Zebra
    Animal : +int age
    Animal : +String gender
    Animal: +isMammal()
    Animal: +mate()
    class Duck{
      +String beakColor
      +swim()
      +quack()
    }
```

### State Diagrams

```mermaid
stateDiagram-v2
    [*] --> Still
    Still --> [*]
    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

### Entity Relationship Diagrams

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    CUSTOMER }|..|{ DELIVERY-ADDRESS : uses
```

### User Journey Diagram

```mermaid
journey
    title My working day
    section Go to work
      Make tea: 5: Me
      Go upstairs: 3: Me
      Do work: 1: Me, Cat
    section Go home
      Go downstairs: 5: Me
      Sit down: 5: Me
```

## Implementation Notes

- Diagrams automatically adapt to the system's light/dark mode setting
- Bergen uses WebView with mermaid.js to render diagrams
- Internet connection is required for rendering (mermaid.js is loaded from CDN)
- Large or complex diagrams may take longer to render

## Troubleshooting

If your diagram doesn't render properly:

1. Check your syntax against the [Mermaid documentation](https://mermaid.js.org/syntax/flowchart.html)
2. Ensure your code block is properly formatted with triple backticks and "mermaid" language
3. Make sure you have an internet connection for the CDN resources

## Further Resources

- [Official Mermaid Documentation](https://mermaid.js.org/intro/)
- [Mermaid Live Editor](https://mermaid.live/)