# Run with: ruby Tests/preview_style_test.rb
# Exercises the stylesheet assembly alone — no Rouge, no gem store.
require "minitest/autorun"
require File.expand_path("../Support/lib/preview_style", __dir__)

class PreviewStyleTest < Minitest::Test
  LIGHT = ".highlight { background-color: #f8f8f8; }"
  DARK  = ".highlight { background-color: #282828; }"

  def css
    PreviewStyle.css(light: LIGHT, dark: DARK, extra: "img { max-width: 100%; }")
  end

  def test_light_highlighter_and_extras_sit_outside_the_dark_media_query
    before, _after = css.split("@media (prefers-color-scheme: dark)")
    assert_includes before, LIGHT
    assert_includes before, "img { max-width: 100%; }"
  end

  def test_dark_highlighter_and_page_colours_sit_inside_the_dark_media_query
    _before, after = css.split("@media (prefers-color-scheme: dark)")
    assert_includes after, DARK
    assert_includes after, PreviewStyle::DARK_PAGE
    refute_includes after, LIGHT
  end

  def test_page_opts_into_both_colour_schemes
    assert_includes css, ":root { color-scheme: light dark; }"
  end

  def test_dark_page_rules_outrank_the_web_theme
    PreviewStyle::DARK_PAGE.each_line do |line|
      assert_match(/!important/, line, "theme rules are class-scoped, so each dark rule must be !important: #{line}")
    end
  end

  def test_tag_wraps_the_stylesheet
    tag = PreviewStyle.tag(light: LIGHT, dark: DARK)
    assert tag.start_with?("<style>\n")
    assert tag.end_with?("</style>")
  end
end
