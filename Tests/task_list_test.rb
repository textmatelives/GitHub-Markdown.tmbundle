#!/usr/bin/env ruby -wEutf-8
# Insert Task and Check Off Task (Support/lib/task_list.rb). Markers are
# GFM-strict on output: unchecked "[ ]", checked "[x]".

require_relative '../Support/lib/task_list'

if $PROGRAM_NAME == __FILE__
  $failures = 0

  def check(label)
    yield
  rescue => e
    puts "FAIL #{label}: #{e.class}: #{e.message}"
    $failures += 1
  end

  def assert_equal(want, got)
    raise "want #{want.inspect}, got #{got.inspect}" unless want == got
  end

  check('task on a blank line starts a box at column 0') do
    assert_equal("- [ ] $0\n",
      TaskList.insert_task("\n", 0, 0))
  end

  check('task aligns with the list above') do
    assert_equal("* a\n  * b\n  - [ ] $0\n",
      TaskList.insert_task("* a\n  * b\n\n", 2, 0))
  end

  check('task under a numbered item uses its indent and a box') do
    assert_equal("1. a\n   2. b\n   - [ ] $0\n",
      TaskList.insert_task("1. a\n   2. b\n\n", 2, 0))
  end

  check('task excises a typed trigger') do
    assert_equal("- a\n- [ ] $0\n",
      TaskList.insert_task("- a\ntask", 1, 4))
  end

  check('task on a prose line converts it in place') do
    assert_equal("- a\n- [ ] note$0\n",
      TaskList.insert_task("- a\nnote\n", 1, 4))
  end

  check('task on a plain item boxes it in place') do
    assert_equal("- [ ] buy milk$0\n",
      TaskList.insert_task("- buy milk", 0, 10))
    assert_equal("1. [ ] x$0\n",
      TaskList.insert_task("1. x", 0, 4))
  end

  check('task on a finished task inserts a fresh box below') do
    assert_equal("- [ ] a\n- [ ] $0\n",
      TaskList.insert_task("- [ ] a\n", 0, 7))
    assert_equal("  - [x] a\n  - [ ] $0\n",
      TaskList.insert_task("  - [x] a\n", 0, 9))
  end

  check('task on an empty box refills it') do
    assert_equal("  - [ ] $0\n",
      TaskList.insert_task("  - [ ]\n", 0, 6))
  end

  check('task never doubles a box on other markers') do
    assert_equal("* [ ] x\n- [ ] $0\n",
      TaskList.insert_task("* [ ] x\n", 0, 7))
    assert_equal("1. [ ] x\n- [ ] $0\n",
      TaskList.insert_task("1. [ ] x\n", 0, 8))
  end

  check('task converts the reported nested case in place') do
    doc = "###GitHub-Markdown\n" \
      "    - [x] task-list-checkboxes now up as closing #10  \n" \
      "        - [ ] Delete README line about the Font Settings bundle (PR)\n" \
      "        - [ ] task/done\n" \
      "        - [ ] Preview-mode preference independent of the system appearance (issue on app + PR)\n" \
      "task        existing\n"
    want = "###GitHub-Markdown\n" \
      "    - [x] task-list-checkboxes now up as closing #10  \n" \
      "        - [ ] Delete README line about the Font Settings bundle (PR)\n" \
      "        - [ ] task/done\n" \
      "        - [ ] Preview-mode preference independent of the system appearance (issue on app + PR)\n" \
      "        - [ ] existing$0\n"
    assert_equal(want, TaskList.insert_task(doc, 5, 4))
  end

  check('task turns an empty bullet into a box') do
    assert_equal("  - [ ] $0\n",
      TaskList.insert_task("  - \n", 0, 4))
  end

  check('task with no list above keeps the caret indent') do
    assert_equal("    - [ ] $0\n",
      TaskList.insert_task("    \n", 0, 4))
  end

  check('task outside the text passes through') do
    assert_equal("* a\n", TaskList.insert_task("* a\n", 5, 0))
  end

  check('task on the trailing line after a final newline') do
    assert_equal("- a\n- [ ] $0\n",
      TaskList.insert_task("- a\n", 1, 0))
  end

  check('task in an empty document starts a box') do
    assert_equal("- [ ] $0\n",
      TaskList.insert_task("", 0, 0))
  end

  check('task escapes content but not the cursor') do
    out = TaskList.insert_task("* a$b\n\n", 1, 0) { |s| s.gsub("$", "\\$") }
    assert_equal("* a\\$b\n- [ ] $0\n", out)
  end

  check('done checks the first box in place') do
    assert_equal("- [x] a", TaskList.check_off("- [ ] a", 7))
    assert_equal("1. [x] a", TaskList.check_off("1. [ ] a", 8))
    assert_equal("- [x] a", TaskList.check_off("- [\t] a", 8))
  end

  check('done leaves checked lines untouched') do
    assert_equal("- [x] a", TaskList.check_off("- [x] a", 7))
    assert_equal("- [X] a", TaskList.check_off("- [X] a", 7))
    assert_equal("- [✓] a", TaskList.check_off("- [✓] a", 7))
  end

  check('done boxes a plain list marker instead of doubling it') do
    assert_equal("- [x] buy milk", TaskList.check_off("- buy milk", 10))
    assert_equal("1. [x] buy milk", TaskList.check_off("1. buy milk", 11))
    assert_equal("- [x] ", TaskList.check_off("- ", 2))
  end

  check('done starts a box on bare and blank lines') do
    assert_equal("- [x] buy milk", TaskList.check_off("buy milk", 8))
    assert_equal("  - [x] ", TaskList.check_off("  ", 2))
  end

  check('done excises a typed trigger') do
    assert_equal("- [x] ", TaskList.check_off("done", 4))
    assert_equal("- [x] a", TaskList.check_off("- [ ] adone", 11))
  end

  check('done clamps wild columns') do
    assert_equal("- [x] a", TaskList.check_off("- [ ] a", 99))
    assert_equal("- [x] a", TaskList.check_off("- [ ] a", -3))
  end

  check('snippet escaping covers the metacharacters') do
    assert_equal('a\\$b\\\\c\\`d', TaskList.escape_snippet('a$b\\c`d'))
    assert_equal("plain", TaskList.escape_snippet("plain"))
  end

  check('byte column converts to char column on a unicode line') do
    line = "- [ ] cafédone"
    char_col = line.index("done")
    byte_col = line[0...char_col].bytesize
    raise 'fixture has no multibyte gap' unless byte_col > char_col
    assert_equal(char_col, TaskList.byte_col_to_char_col(line, byte_col))
    assert_equal("- [x] café", TaskList.check_off(line, TaskList.byte_col_to_char_col(line, line.bytesize)))
  end

  if $failures == 0
    puts 'ok'
  else
    puts "#{$failures} failed"
    exit 1
  end
end
