#!/usr/bin/env ruby
# Usage: redcarpet.rb [<file>...]
# Convert one or more GitHub Flavored Markdown files to HTML and print to
# standard output. With no <file> or when <file> is "-", read GitHub Flavored
# Markdown source text from standard input.
#
# Rendering uses Redcarpet for GFM and Rouge for code highlighting. Both gems
# come from TextMate's shared gem store (see tm/gems) — no Python, no pygments.

if ARGV.include?("--help")
  File.read(__FILE__).split("\n").grep(/^# /).each do |line|
    puts line[2..-1]
  end
  exit 0
end

require "#{ENV['TM_SUPPORT_PATH']}/lib/tm/gems"
# This script runs as $TM_MARKDOWN, invoked by the base Markdown bundle's
# preview command, so TM_BUNDLE_SUPPORT points at *that* bundle. Resolve our
# own Gemfile relative to this script instead.
TextMate::Gems.setup(name: "Markdown (GitHub)", gemfile: File.expand_path("../Gemfile", __dir__))

require "redcarpet"
require "rouge"
require File.expand_path("../lib/relative_safe_links", __dir__)
require File.expand_path("../lib/diagrams", __dir__)

class RougeSmartyHTML < Redcarpet::Render::HTML
  include Redcarpet::Render::SmartyPants
  include RelativeSafeLinks

  # Diagram languages seen while rendering, so the page loads only the
  # libraries it needs.
  def diagram_languages
    @diagram_languages ||= []
  end

  def block_code(code, language)
    if Diagrams.language?(language)
      diagram_languages << language
      return Diagrams.block(language, code)
    end

    lexer = Rouge::Lexer.find_fancy(language) || Rouge::Lexers::PlainText.new
    inner = Rouge::Formatters::HTML.new.format(lexer.lex(code))
    %{<pre class="highlight"><code>#{inner}</code></pre>}
  end
end

def checkbox_html(checked)
  "<li><input type='checkbox' #{"checked" if checked} style='margin-right:0.5em;'/>"
end

def markdown(text)
  # Raw HTML passes through: the preview shows the author's own document, and
  # <video>, <audio>, <iframe> and friends are how media that has no Markdown
  # syntax gets embedded. GitHub strips most of it; Markdown.pl, which the base
  # bundle uses when this one is absent, lets all of it through.
  options = {
    :filter_html     => false,
    :safe_links_only => true,
    :with_toc_data   => true,
    :hard_wrap       => true,
  }
  renderer = RougeSmartyHTML.new(options)
  extensions = {
    :no_intra_emphasis   => true,
    :tables              => true,
    :fenced_code_blocks  => true,
    :autolink            => true,
    :strikethrough       => true,
    :space_after_headers => true,
  }
  html = Redcarpet::Markdown.new(renderer, extensions).render(text)
  html.gsub!("<li>[ ]", checkbox_html(false))
  html.gsub!("<li>[x]", checkbox_html(true))
  html << Diagrams.scripts(renderer.diagram_languages)
end

puts %{<style>#{Rouge::Themes::Github.render(scope: ".highlight")}
#{MediaEmbeds::STYLE}</style>}
puts markdown(ARGF.read)
