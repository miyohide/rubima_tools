require 'minitest/autorun'
require_relative '../scripts/hiki2md'

class TestHiki2Md < Minitest::Test
  def test_image_tag_titlemark
    actual = image_tag("DIR_NAME/", "Hoge/u26.gif")
    expect = "<img src='{{site.baseurl}}/images/title_mark.gif' alt='title mark'></img>"
    assert_equal expect, actual
  end

  def test_image_tag_not_titlemark
    actual = image_tag("DIR_NAME/", "Hoge/u25.gif")
    expect = "<img src='DIR_NAME/Hoge/u25.gif' alt='Hoge/u25.gif'></img>"
    assert_equal expect, actual
  end

  def test_footnote_link
    actual = footnote_link(12)
    expect = "<sup id='fnref12'><a href='\#fn12' rel='footnote'>12</a></sup>"
    assert_equal expect, actual
  end

  def test_footnote_body
    actual = footnote_body(13, "body1")
    expect = "<li id='fn13'><p>body1<a href='#fnref13' rev='footnote'>←</a></p></li>"
    assert_equal expect, actual

  end
end
