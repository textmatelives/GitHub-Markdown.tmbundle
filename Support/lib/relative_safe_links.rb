require "cgi"

# Redcarpet's :safe_links_only drops any link whose destination is not
# "#…", "/…", "http://…", "https://…", "ftp://…" or "mailto:…" — the source
# text is rendered verbatim instead. That is the right policy for a hosted
# renderer, but the TextMate preview sits behind a <base href> pointing at the
# document, so a plain relative link such as GLOSSARY.md#section is exactly
# what the author expects to work, and today it shows up as literal brackets.
#
# Redcarpet only applies its safe-link check inside its C renderer. Defining
# `link` in Ruby replaces that callback, so this module accepts the same
# destinations Redcarpet accepts, plus scheme-less relative paths, and keeps
# rejecting everything Redcarpet rejects: unknown or unsafe schemes
# (javascript:, data:, file:, …), protocol-relative and backslash-led paths,
# and anything containing whitespace or control characters — browsers strip
# those, so "java\tscript:" would otherwise slip through as a scheme.
#
# Images and autolinks are not overridden and keep Redcarpet's own policy.
module RelativeSafeLinks
  # These two mirror sd_autolink_issafe in redcarpet/autolink.c: a known
  # prefix followed by an alphanumeric character.
  SAFE_URI = /\A(?:https?:\/\/|ftp:\/\/|mailto:)[A-Za-z0-9]/i
  SAFE_ROOT_OR_FRAGMENT = /\A(?:\/|#)[A-Za-z0-9]/
  # RFC 3986 §3.1 scheme grammar. A relative reference cannot have a colon in
  # its first path segment, so any match here is a scheme we did not accept.
  URI_SCHEME = /\A[A-Za-z][A-Za-z0-9+.-]*:/
  UNSAFE_CHARACTERS = /[\x00-\x20\x7F]/

  def link(destination, title, content)
    return nil unless safe_link_destination?(destination)

    title_attribute = if title && !title.empty?
      %( title="#{CGI.escapeHTML(title)}")
    else
      ""
    end

    %(<a href="#{CGI.escapeHTML(destination)}"#{title_attribute}>#{content}</a>)
  end

  private

  def safe_link_destination?(destination)
    return false if !destination || destination.empty?
    return false if destination =~ UNSAFE_CHARACTERS
    return true if destination =~ SAFE_URI
    return true if destination =~ SAFE_ROOT_OR_FRAGMENT
    return false if destination.start_with?("/", "#", "\\")
    return false if destination =~ URI_SCHEME

    true
  end
end
