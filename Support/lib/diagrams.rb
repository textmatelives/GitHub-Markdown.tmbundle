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
  # Mermaid bakes the theme into the SVG it draws, so a page that follows the
  # system appearance has to draw its diagrams again when that changes. The
  # source of every block is kept before the first drawing replaces it, put
  # back on a change and drawn with the other theme. The script is emitted
  # after the content, so the blocks exist when it runs.
  MERMAID_INIT = <<~JS.gsub(/\s+/, " ").strip.freeze
    (function () {
      var dark = window.matchMedia("(prefers-color-scheme: dark)");
      var blocks = Array.prototype.slice.call(document.querySelectorAll("pre.mermaid"));
      blocks.forEach(function (el) { el.dataset.source = el.textContent; });
      mermaid.initialize({ startOnLoad: true, theme: dark.matches ? "dark" : "default" });
      dark.addEventListener("change", function () {
        blocks.forEach(function (el) { el.textContent = el.dataset.source; el.removeAttribute("data-processed"); });
        mermaid.initialize({ startOnLoad: false, theme: dark.matches ? "dark" : "default" });
        mermaid.run({ nodes: blocks });
      });
    })();
  JS

  LIBRARIES = {
    "mermaid" => {
      css_class: "mermaid",
      script:    "https://cdn.jsdelivr.net/npm/mermaid@12.2.0/dist/mermaid.min.js",
      init:      MERMAID_INIT,
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
