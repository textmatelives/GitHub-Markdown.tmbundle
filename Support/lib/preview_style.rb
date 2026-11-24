# The stylesheet the preview emits ahead of the rendered Markdown.
#
# The page is styled by the web theme from Themes.tmbundle, which only knows
# light colours and scopes its rules by body class (`body.plain`, `.bright`).
# The HTML output view follows the app appearance, so under a dark appearance
# `prefers-color-scheme: dark` is true and the rules below take over. They
# need `!important` to beat the theme's class-scoped rules; the highlighter
# rules share the `.highlight` selector with the light theme, so the dark
# copy wins by coming later.
module PreviewStyle
  DARK_PAGE = <<~CSS.freeze
    body, #tm_webpreview_content { background: #0d1117 !important; color: #e6edf3 !important; }
    h1, h2, h3, h4, h5, h6 { color: #e6edf3 !important; }
    a, a:visited { color: #58a6ff !important; }
    code, kbd { background: #161b22 !important; color: #e6edf3 !important; }
    pre, pre code { background: #161b22 !important; color: #e6edf3 !important; border-color: #30363d !important; }
    blockquote { color: #8b949e !important; border-left-color: #30363d !important; }
    table, th, td { border-color: #30363d !important; }
    th { background: #161b22 !important; }
    .alternate { background: #161b22 !important; }
    hr { border-color: #30363d !important; background: #30363d !important; }
  CSS

  module_function

  # +light+ and +dark+ are rendered highlighter stylesheets (Rouge themes);
  # +extra+ is appended inside the light block.
  def css(light:, dark:, extra: "")
    <<~CSS
      :root { color-scheme: light dark; }
      #{light}
      #{extra}
      @media (prefers-color-scheme: dark) {
      #{DARK_PAGE}
      #{dark}
      }
    CSS
  end

  def tag(light:, dark:, extra: "")
    "<style>\n#{css(light: light, dark: dark, extra: extra)}</style>"
  end
end
