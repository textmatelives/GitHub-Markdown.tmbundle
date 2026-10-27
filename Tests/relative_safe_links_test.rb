# Run with: ruby Tests/relative_safe_links_test.rb
# Exercises the link policy alone — no redcarpet, no gem store — so it runs
# under the system Ruby with nothing installed.
require "minitest/autorun"
require File.expand_path("../Support/lib/relative_safe_links", __dir__)

class RelativeSafeLinksTest < Minitest::Test
  class Renderer
    include RelativeSafeLinks
  end

  def setup
    @renderer = Renderer.new
  end

  def test_accepts_supported_absolute_schemes_case_insensitively
    destinations = [
      "http://example.com",
      "https://example.com",
      "ftp://example.com",
      "mailto:user@example.com",
      "HTTP://example.com",
      "HtTpS://example.com",
      "FtP://example.com",
      "MaIlTo:user@example.com",
    ]

    destinations.each do |destination|
      assert_link(destination)
    end
  end

  def test_accepts_root_links_and_fragments_with_alphanumeric_prefixes
    ["/root", "/9-root", "#fragment", "#9-fragment"].each do |destination|
      assert_link(destination)
    end
  end

  def test_accepts_scheme_less_relative_paths
    destinations = [
      "GLOSSARY.md#anchor",
      "docs/guide.md",
      "./guide.md",
      "../README.md",
      "?query=value",
      "docs/a:b.md",
    ]

    destinations.each do |destination|
      assert_link(destination)
    end
  end

  def test_rejects_nil_and_empty_destinations
    assert_nil @renderer.link(nil, nil, "unsafe")
    assert_nil @renderer.link("", nil, "unsafe")
  end

  def test_rejects_every_ascii_whitespace_and_control_character
    (0..32).to_a.push(127).each do |codepoint|
      destination = "guide#{codepoint.chr}.md"
      assert_nil @renderer.link(destination, nil, "unsafe"),
        "expected codepoint #{codepoint} to be rejected"
    end
  end

  def test_rejects_obfuscated_schemes
    ["java\tscript:alert(1)", "java\nscript:alert(1)", " javascript:alert(1)"].each do |destination|
      assert_nil @renderer.link(destination, nil, "unsafe"), destination.inspect
    end
  end

  def test_rejects_unknown_schemes_using_rfc_3986_grammar
    destinations = [
      "custom:value",
      "CuStOm:value",
      "a:value",
      "git+ssh:value",
      "web.view-1:value",
      "C:\\Windows\\notepad.exe",
    ]

    destinations.each do |destination|
      assert_nil @renderer.link(destination, nil, "unsafe"), destination
    end
  end

  def test_rejects_unsafe_schemes_including_mixed_case
    destinations = [
      "javascript:alert(1)",
      "JaVaScRiPt:alert(1)",
      "data:text/html,payload",
      "DATA:text/html,payload",
      "file:///tmp/private",
      "FiLe:///tmp/private",
      "vbscript:MsgBox(1)",
    ]

    destinations.each do |destination|
      assert_nil @renderer.link(destination, nil, "unsafe"), destination
    end
  end

  def test_rejects_supported_schemes_without_an_alphanumeric_target
    destinations = [
      "http://-example.com",
      "https://_example.com",
      "ftp://.example.com",
      "mailto:-user@example.com",
    ]

    destinations.each do |destination|
      assert_nil @renderer.link(destination, nil, "unsafe"), destination
    end
  end

  def test_rejects_protocol_relative_destinations
    assert_nil @renderer.link("//example.com/path", nil, "unsafe")
    assert_nil @renderer.link("///example.com/path", nil, "unsafe")
  end

  def test_rejects_leading_backslashes_and_unc_like_paths
    assert_nil @renderer.link("\\guide.md", nil, "unsafe")
    assert_nil @renderer.link("\\\\example.com\\path", nil, "unsafe")
  end

  def test_rejects_root_and_fragment_markers_without_alphanumeric_prefixes
    ["/", "/-root", "#", "#-fragment"].each do |destination|
      assert_nil @renderer.link(destination, nil, "unsafe"), destination
    end
  end

  def test_escapes_attributes_and_preserves_rendered_content
    actual = @renderer.link(
      'guide.md?x=1&y="two"',
      'A "title" & more',
      "<em>guide</em>"
    )

    assert_equal(
      '<a href="guide.md?x=1&amp;y=&quot;two&quot;" title="A &quot;title&quot; &amp; more"><em>guide</em></a>',
      actual
    )
  end

  def test_omits_empty_titles
    assert_equal(
      '<a href="guide.md">guide</a>',
      @renderer.link("guide.md", "", "guide")
    )
  end

  def test_images_follow_the_same_destination_policy_as_links
    assert_equal %(<img src="shot.png" alt="shot">), @renderer.image("shot.png", nil, "shot")
    assert_equal %(<img src="../img/a.png" alt="a" title="t">), @renderer.image("../img/a.png", "t", "a")
    assert_equal %(<img src="https://example.com/a.png" alt="a">), @renderer.image("https://example.com/a.png", nil, "a")

    ["javascript:alert(1)", "data:image/png;base64,AAAA", "file:///tmp/a.png", "//example.com/a.png", "", nil].each do |destination|
      assert_nil @renderer.image(destination, nil, "a"), destination.inspect
    end
  end

  def test_images_pointing_at_media_files_become_media_elements
    assert_equal %(<video controls src="clip.mov" title="clip"></video>), @renderer.image("clip.mov", nil, "clip")
    assert_equal %(<audio controls src="take.aiff"></audio>), @renderer.image("take.aiff", nil, "")
  end

  private

  def assert_link(destination)
    assert_equal(
      %(<a href="#{destination}">guide</a>),
      @renderer.link(destination, nil, "guide"),
      destination
    )
  end
end
