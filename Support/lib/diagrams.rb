require "cgi"

# Fenced code blocks written in a diagram language are not syntax-highlighted.
# Their source is kept in the page as text and a browser-side library, loaded
# only when the page actually contains such a block, turns it into a drawing
# once the preview has loaded. Adding a language is adding an entry here: the
# element class the library looks for, the script that provides it, and the
# call that starts it.
#
# The scripts come from a CDN, the same way the base Markdown bundle loads
# MathJax, so previews of diagrams need network access.
module Diagrams
  LIBRARIES = {
    "mermaid" => {
      css_class: "mermaid",
      script:    "https://cdn.jsdelivr.net/npm/mermaid@12.2.0/dist/mermaid.min.js",
      init:      "mermaid.initialize({ startOnLoad: true });",
    },
  }.freeze

  module_function

  def language?(language)
    LIBRARIES.key?(normalize(language))
  end

  # The element the library replaces with the rendered diagram. The source is
  # escaped like any text node; the library reads it back decoded.
  def block(language, code)
    library = LIBRARIES[normalize(language)]
    return nil unless library
    %(<pre class="#{library[:css_class]}">#{CGI.escapeHTML(code)}</pre>)
  end

  # Script tags for every library a rendered page needs, each once.
  def scripts(languages)
    used = languages.map { |language| normalize(language) }.uniq
    LIBRARIES.select { |name, _| used.include?(name) }.map { |_, library|
      %(<script src="#{library[:script]}"></script>\n<script>#{library[:init]}</script>\n)
    }.join
  end

  def normalize(language)
    language.to_s.strip.downcase
  end
end
