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

  def test_convert_definition
    bodies = [":発言者:発言内容", ":発言者2:発言内容2", "あああ:いいい"]
    expect = ["__発言者__ 発言内容\n",
        "__発言者2__ 発言内容2\n",
        "あああ:いいい"]

    actuals = bodies.map { |body| convert_definition(body) }

    assert_equal expect, actuals
  end

  def test_convert_link
    bodies = ["[[RWiki:逆引きRuby/Tk]]", "[[ruby-list:37857]]",
              "[[RAA:qtruby]]", "[[FOX|http://www.fox-toolkit.org/]]"]
    expect = ["[RWiki:逆引きRuby/Tk](http://pub.cozmixng.org/~the-rwiki/rw-cgi.rb?cmd=view;name=%B5%D5%B0%FA%A4%ADRuby%2FTk)",
              "[ruby-list:37857](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/37857)",
              "[RAA:qtruby](http://raa.ruby-lang.org/project/qtruby)", "[FOX](http://www.fox-toolkit.org/)"]

    actuals = bodies.map { |body| convert_link(body) }

    assert_equal expect, actuals
  end

  def test_convert_quote
    bodies = ['""#コメント行', '""通常行']
    expect = ['> \#コメント行', '> 通常行']

    assert_equal expect, bodies.map { |body| convert_quote(body) }
  end

  def test_convert_source
    bodies = [" puts 'Hello World'\n", " puts 'Hogehoge'\n", "\n", "あいう\n"]
    expect = ["\n```ruby\nputs 'Hello World'\n", "puts 'Hogehoge'\n", "```\n\n", "あいう\n"]

    result = convert_source(bodies)

    assert_equal expect, result
  end

  def test_create_header
    expect = [
      "---\n",
      "layout: post\n",
      "title: タイトル\n",
      "short_title: タイトル\n",
      "tags: 0012 hoge\n",
      "---\n\n"
    ]
    actual = create_header("タイトル", "0012", "0012-hoge.hiki")
    assert_equal expect, actual
  end

  def test_convert_italic
    bodies = ['ほげ\'\'ここからイタリック\'\'ここは普通']
    expect = ['ほげ _ここからイタリック_ ここは普通']

    assert_equal expect, bodies.map { |body| convert_italic(body) }
  end

  def test_include_toc1
    bodies = ["あああ\n", "いいい{{toc_here}}\n", "ううう\n"]

    assert_equal true, include_toc?(bodies)
  end

  def test_include_toc2
    bodies = ["あああ\n", "いいい\n", "ううう\n"]

    assert_equal false, include_toc?(bodies)
  end
end
