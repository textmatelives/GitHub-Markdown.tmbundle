require "cgi"

# Markdown has one syntax for embedding a file, the image: ![alt](src "title").
# Anything the preview's web view can play is embedded with the element it
# needs, chosen by the file extension, so a document can show its screencast
# or its audio clip the same way it shows a screenshot.
module MediaEmbeds
  VIDEO = %w[mp4 m4v mov webm].freeze
  AUDIO = %w[mp3 m4a aac wav aiff aif ogg oga flac].freeze

  # Embedded pictures and video fit the page instead of forcing a horizontal
  # scroll, as GitHub's own stylesheet does for images.
  STYLE = "img, video { max-width: 100%; height: auto; }".freeze

  module_function

  def tag(src, title, alt)
    src_attribute = %( src="#{CGI.escapeHTML(src)}")

    case extension(src)
    when *VIDEO then %(<video controls#{src_attribute}#{title_attribute(title, alt)}></video>)
    when *AUDIO then %(<audio controls#{src_attribute}#{title_attribute(title, alt)}></audio>)
    else %(<img#{src_attribute} alt="#{CGI.escapeHTML(alt.to_s)}"#{title_attribute(title)}>)
    end
  end

  # A media element has no alt attribute; the alt text becomes its title
  # unless the author gave one.
  def title_attribute(title, fallback = nil)
    text = title.to_s.empty? ? fallback.to_s : title
    text.empty? ? "" : %( title="#{CGI.escapeHTML(text)}")
  end

  def extension(src)
    File.extname(src.to_s.split(/[?#]/, 2).first.to_s).delete_prefix(".").downcase
  end
end
