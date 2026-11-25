# Logic behind the Insert Task and Check Off Task commands. Markers are
# GFM-strict on output: unchecked is "[ ]" (space or tab), checked is
# "[x]". Detection is tolerant: "[X]" and "[✓]"-style ticks from other
# tools already count as done, so checking them off is a no-op instead
# of mangling the line.
module TaskList
  module_function

  # TM_LINE_INDEX counts UTF-8 bytes; Ruby 2+ String indexing counts characters.
  # Convert a TextMate byte column into a character column.
  def byte_col_to_char_col(line, byte_col)
    line = line.to_s
    return 0 if byte_col <= 0
    return byte_col if line.empty?
    return line.length if byte_col >= line.bytesize
    line.byteslice(0, byte_col).length
  end

  # Split a physical line into indent, marker core, gap, and body. A
  # marker needs whitespace (or end of line) after it; "*b" is text.
  def parse_item_line(line)
    m = /\A([ \t]*)([-*+]|\d+\.)([ \t]*)(.*)\z/.match(line)
    return nil if m.nil?
    return nil if m[3].empty? && !m[4].empty?
    { indent: m[1], core: m[2], gap: m[3], body: m[4] }
  end

  # Escape snippet metacharacters for snippet output ($0 bypasses this).
  def escape_snippet(text)
    text.to_s.gsub(/([\\$`])/, '\\\\\1')
  end

  # Insert a "- [ ] " task item on the caret's line (`line` is a 0-based
  # index, `col` a character column), aligned with the nearest list item
  # at or above the caret. A typed trigger word immediately before the
  # caret is excised; without one (menu use) the line is used as is. A
  # blank line, a bare bullet, or an empty box is replaced by a fresh
  # box. Anything else on the line is kept: a plain item or prose line
  # is converted to a task in place with the caret at its end, while a
  # finished task gets a fresh box on the line below. The $0 cursor
  # marker bypasses the escape block. Output ends with newline.
  def insert_task(text, line, col, trigger = "task", &escape)
    escape ||= ->(s) { s }
    lines = text.lines.map(&:chomp)
    lines << "" if line == lines.length
    return lines.join("\n") + "\n" unless line.between?(0, lines.length - 1)
    caret = lines[line].to_s
    col = [[col.to_i, 0].max, caret.length].min
    if caret[0...col].end_with?(trigger)
      caret = caret[0...(col - trigger.length)] + caret[col..-1].to_s
      col -= trigger.length
    end
    indent = nil
    line.downto(0) do |i|
      probe = (i == line) ? caret : lines[i]
      parsed = parse_item_line(probe)
      unless parsed.nil?
        indent = parsed[:indent]
        break
      end
    end
    indent = caret[/\A[ \t]*/].to_s if indent.nil?
    item = parse_item_line(caret)
    boxed = item && item[:body].lstrip.match(/\A\[[ xX\t✓]\]\s*(.*)\z/m)
    out = lines.map { |s| [s] }
    if caret.strip.empty?
      out[line] = ["#{indent}- [ ] ", :cursor]
    elsif item && item[:body].strip.empty?
      out[line] = ["#{item[:indent]}#{item[:core]} [ ] ", :cursor]
    elsif boxed && boxed[1].strip.empty?
      out[line] = ["#{item[:indent]}#{item[:core]} [ ] ", :cursor]
    elsif boxed
      out[line] = [caret]
      out.insert(line + 1, ["#{item[:indent]}- [ ] ", :cursor])
    elsif item
      out[line] = ["#{item[:indent]}#{item[:core]} [ ] #{item[:body].strip}", :cursor]
    else
      out[line] = ["#{indent}- [ ] #{caret.strip}", :cursor]
    end
    out.map { |segs|
      segs.map { |s| s == :cursor ? "$0" : escape.call(s) }.join
    }.join("\n") + "\n"
  end

  # Check off the first unchecked box on one bare line (`col` is a
  # character column): "[ ]" becomes "[x]" in place. A line that is
  # already checked stays untouched. Otherwise the line gains a box:
  # a plain list marker turns into one ("- a" to "- [x] a"), any other
  # line gets "- [x] " after its indent. A typed trigger word
  # immediately before the caret is excised first.
  def check_off(line, col, trigger = "done")
    line = line.to_s
    col = [[col.to_i, 0].max, line.length].min
    if line[0...col].end_with?(trigger)
      line = line[0...(col - trigger.length)] + line[col..-1].to_s
    end
    if line.sub!(/((?:(?:[-*+]|\d+[.)])\s*)?)\[[ \t]\]/, '\1[x]')
      # checked off in place
    elsif line =~ /\[[xX✓]\]/
      # already checked: leave untouched
    else
      line = line.sub(/\A(\s*)((?:[-*+]|\d+[.)])\s+)?/) { $1 + ($2 ? "#{$2}[x] " : "- [x] ") }
    end
    line
  end
end
