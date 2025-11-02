# Syntax Highlighting in FKNB

FKNB leverages Neovim's Tree-sitter integration for robust and accurate syntax highlighting of notebook cells. This document outlines the key components involved.

## 1. Tree-sitter Grammar (`tree-sitter-fknb/grammar.js`)

The `grammar.js` file defines the Tree-sitter grammar for `.fknb` files. It specifies the structure of a notebook, recognizing two primary cell types:

*   **Markdown Cells (`notebook_markdown_cell`):** Identified by the `#%` marker.
*   **Code Cells (`notebook_code_cell`):** Identified by the `#%%` marker, optionally followed by a language tag (e.g., `[python]`).

The grammar breaks down these cells into their constituent parts, such as `raw_code_line` for code content and `markdown_text_line` for markdown content.

## 2. Highlights Queries (`queries/fknb/highlights.scm`)

The `highlights.scm` file contains Tree-sitter queries that map nodes in the parsed syntax tree to Neovim highlight groups. This is how different parts of your notebook (like cell markers, language tags, and content) get their colors.

Key mappings include:
*   `notebook_code_cell` language tags (`[python]`) are highlighted as `@keyword`.
*   `notebook_markdown_cell` markers (`#%`) are highlighted as `@string.special`.
*   `raw_code_line` and `markdown_text_line` are generally highlighted as `@text`.
*   Fenced code blocks within markdown cells are highlighted as `@comment`.

## 3. Injections Queries (`queries/fknb/injections.scm`)

The `injections.scm` file is crucial for enabling language-specific highlighting *within* notebook cells. It tells Tree-sitter to inject other language parsers into specific regions of the `fknb` syntax tree.

*   **Markdown Injection:** Markdown cells have the `markdown` parser injected into their content (`markdown_text_line`). This ensures that markdown syntax (headers, lists, etc.) is correctly highlighted.
*   **Code Cell Injection:**
    *   If a code cell has a `language_tag` (e.g., `#%% [python]`), the specified language parser (e.g., `python`) is injected into the `raw_code_line` content.
    *   As a fallback, if no language tag is found, the `python` parser is injected by default. This ensures that code cells always receive some form of syntax highlighting.

These three components work in concert to provide a rich and accurate syntax highlighting experience for FKNB notebooks in Neovim.
