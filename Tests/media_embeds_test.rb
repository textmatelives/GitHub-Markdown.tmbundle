# Run with: ruby Tests/media_embeds_test.rb
require "minitest/autorun"
require File.expand_path("../Support/lib/media_embeds", __dir__)

class MediaEmbedsTest < Minitest::Test
  def test_images_stay_images
    assert_equal %(<img src="shot.png" alt="shot">), MediaEmbeds.tag("shot.png", nil, "shot")
    assert_equal %(<img src="logo.svg" alt="">), MediaEmbeds.tag("logo.svg", nil, nil)
  end

  def test_video_extensions_become_a_video_element
    %w[clip.mp4 clip.m4v clip.mov clip.webm CLIP.MP4].each do |src|
      assert_equal %(<video controls src="#{src}" title="clip"></video>), MediaEmbeds.tag(src, nil, "clip"), src
    end
  end

  def test_audio_extensions_become_an_audio_element
    %w[a.mp3 a.m4a a.aac a.wav a.aiff a.aif a.ogg a.flac].each do |src|
      assert_equal %(<audio controls src="#{src}"></audio>), MediaEmbeds.tag(src, nil, ""), src
    end
  end

  def test_query_strings_and_fragments_do_not_hide_the_extension
    assert_match(/\A<video /, MediaEmbeds.tag("clip.mp4?v=2", nil, ""))
    assert_match(/\A<audio /, MediaEmbeds.tag("a.mp3#t=10", nil, ""))
  end

  def test_style_fits_pictures_and_video_to_the_page
    assert_equal "img, video { max-width: 100%; height: auto; }", MediaEmbeds::STYLE
  end

  def test_attributes_are_escaped
    assert_equal(
      %(<img src="a&amp;b.png" alt="&lt;alt&gt;" title="say &quot;hi&quot;">),
      MediaEmbeds.tag("a&b.png", 'say "hi"', "<alt>")
    )
  end
end
