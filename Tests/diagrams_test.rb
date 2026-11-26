# Run with: ruby Tests/diagrams_test.rb
# Exercises the diagram registry alone — no redcarpet, no gem store.
require "minitest/autorun"
require File.expand_path("../Support/lib/diagrams", __dir__)

class DiagramsTest < Minitest::Test
  def test_recognises_registered_languages_case_insensitively
    assert Diagrams.language?("mermaid")
    assert Diagrams.language?("Mermaid")
    refute Diagrams.language?("ruby")
    refute Diagrams.language?(nil)
    refute Diagrams.language?("")
  end

  def test_block_keeps_the_source_as_escaped_text_for_the_browser_library
    actual = Diagrams.block("mermaid", "graph TD; A-->B & C;\n")
    assert_equal %(<pre class="mermaid">graph TD; A--&gt;B &amp; C;\n</pre>), actual
  end

  def test_block_rejects_unknown_languages
    assert_nil Diagrams.block("ruby", "puts 1")
  end

  def test_scripts_are_emitted_once_per_language_actually_used
    html = Diagrams.scripts(%w[mermaid Mermaid])
    assert_equal 1, html.scan("mermaid.min.js").length
    assert_includes html, %(<script src="https://cdn.jsdelivr.net/npm/mermaid@12.2.0/dist/mermaid.min.js"></script>)
    assert_includes html, "mermaid.initialize("
  end

  def test_mermaid_follows_the_colour_scheme_of_the_page
    html = Diagrams.scripts(%w[mermaid])
    assert_includes html, %q{window.matchMedia("(prefers-color-scheme: dark)")}
    assert_includes html, %q{theme: dark.matches ? "dark" : "default"}
  end

  def test_mermaid_redraws_when_the_colour_scheme_changes
    html = Diagrams.scripts(%w[mermaid])
    # The source is kept before mermaid replaces it with an SVG, and put back for the redraw
    assert_includes html, %q{el.dataset.source = el.textContent}
    assert_includes html, %q{dark.addEventListener("change"}
    assert_includes html, %q{el.textContent = el.dataset.source}
    assert_includes html, %q{el.removeAttribute("data-processed")}
    assert_includes html, %q{mermaid.run({ nodes: blocks })}
  end

  def test_scripts_are_empty_when_no_diagram_was_rendered
    assert_equal "", Diagrams.scripts([])
    assert_equal "", Diagrams.scripts(%w[ruby])
  end
end
