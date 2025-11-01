; Inject language into code cells
(code_cell
  language: (language) @lang
  body: (code_body) @injection
  (#set! injection.language @lang))

; Inject markdown into markdown cells
(markdown_cell
  body: (markdown_body) @injection
  (#set! injection.language "markdown"))