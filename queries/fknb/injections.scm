;; ─────────────────────────────────────────────────────
;; Inject Markdown inside markdown cells
;; ─────────────────────────────────────────────────────

((notebook_markdown_cell
  (markdown_text_line) @injection.content)
 (#set! injection.language "markdown"))




;; ─────────────────────────────────────────────────────
;; Inject language inside real notebook code cells
;; #%% [python]
;; ─────────────────────────────────────────────────────

((notebook_code_cell
  lang: (language_tag) @injection.language
  (raw_code_line) @injection.content))

;; fallback: if no language matched, treat as python
((notebook_code_cell
  (raw_code_line) @injection.content)
 (#set! injection.language "python"))
