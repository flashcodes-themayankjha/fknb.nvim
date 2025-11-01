;; Code cell marker line: "#%% python"
((notebook_code_cell
  lang: (language_tag) @keyword)) @module

;; Markdown cell marker "#% markdown"
((notebook_markdown_cell) @string.special)

;; Raw code inside code cell
(raw_code_line) @text

;; Markdown text inside markdown cell
(markdown_text_line) @text

;; Fenced code block inside markdown
(markdown_fenced_block) @comment
