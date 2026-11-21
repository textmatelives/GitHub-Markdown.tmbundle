#!/usr/bin/env ruby -wEutf-8
# GFM task-list markers in the Markdown (GitHub) injection.
# [ ] is unchecked, [x] and [X] are checked.
# The bullet is outside meta.paragraph.markdown, so the rule matches the
# box itself. A box in the middle of a sentence matches too.

require 'rexml/document'

module TaskListCheckbox
  module_function

  def unchecked_pattern
    "(\\[)([ \\t])(\\])(?=[ \\t]|$)"
  end

  def checked_pattern
    "(\\[)([xX])(\\])(?=[ \\t]|$)"
  end

  def grammar_patterns(path)
    doc = REXML::Document.new(File.read(path))
    found = {}
    REXML::XPath.each(doc, '//dict[string]') do |dict|
      name = nil
      match = nil
      dict.elements.each do |el|
        next unless el.name == 'string'
        prev = el.previous_element
        next unless prev && prev.name == 'key'
        name = el.text if prev.text == 'name'
        match = el.text if prev.text == 'match'
      end
      found[name] = match if name && match && name.start_with?('markup.checkbox.')
    end
    found
  end
end

if $PROGRAM_NAME == __FILE__
  $failures = 0

  def check(label)
    yield
  rescue => e
    puts "FAIL #{label}: #{e.class}: #{e.message}"
    $failures += 1
  end

  grammar = File.expand_path('../Syntaxes/Markdown (GitHub).tmLanguage', __dir__)
  patterns = TaskListCheckbox.grammar_patterns(grammar)

  check('unchecked pattern is in the grammar') do
    got = patterns['markup.checkbox.unchecked.markdown.github']
    raise "missing rule, have #{patterns.keys.inspect}" unless got == TaskListCheckbox.unchecked_pattern
  end

  check('checked pattern is in the grammar') do
    got = patterns['markup.checkbox.checked.markdown.github']
    raise 'missing rule' unless got == TaskListCheckbox.checked_pattern
  end

  open_re = Regexp.new(TaskListCheckbox.unchecked_pattern)
  done_re = Regexp.new(TaskListCheckbox.checked_pattern)

  def kind(line, open_re, done_re)
    return :open if line.match(open_re)
    return :done if line.match(done_re)
    nil
  end

  {
    '- [ ] foo' => :open,
    '- [x] bar' => :done,
    '- [X] bar' => :done,
    '* [ ] a' => :open,
    '+ [ ] a' => :open,
    '1. [ ] a' => :open,
    '99. [x] a' => :done,
    '  - [ ] nested' => :open,
    '    - [ ] deep' => :open,
    '            - [ ] twelve' => :open,
    "> - [ ] q" => :open,
    '> > - [x] q' => :done,
    ">    - [ ] qnest" => :open,
    "\t- [ ] tabbed" => :open,
    '- [ ]' => :open,
    "- [\t] tab inside" => :open,
    '-  [ ] two spaces' => :open,
    '- [] empty' => nil,
    '- [x]bar' => nil,
    'text [ ] mid' => :open,
    'see - [ ] mid' => :open,
    '- [✓] tick' => nil,
    '1) [ ] paren' => :open,
    '[hello](url)' => nil
  }.each do |line, want|
    check(line.inspect) do
      got = kind(line, open_re, done_re)
      raise "want #{want.inspect}, got #{got.inspect}" unless got == want
    end
  end

  if $failures == 0
    puts 'ok'
  else
    puts "#{$failures} failed"
    exit 1
  end
end
