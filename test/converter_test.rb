require 'minitest/autorun'
require_relative '../scripts/converter'

class TestConverter < Minitest::Test
  def test_convert_line_ordered_list
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["# aaa", "# bbb", "ccc"]) do
      converter.convert_line
      assert_equal(["1. aaa", "1. bbb", "ccc"], converter.lines)
    end
  end

  def test_convert_line_section
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["!aaa", "!bbb"]) do
      converter.convert_line
      assert_equal(["## aaa", "## bbb"], converter.lines)
    end
  end

  def test_convert_line_unordered_list
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["* aaa", "* bbb"]) do
      converter.convert_line
      assert_equal(["- aaa", "- bbb"], converter.lines)
    end
  end

  def test_convert_line_strong
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["hoge", "'''aaaaa'''"]) do
      converter.convert_line
      assert_equal(["hoge", "***aaaaa***"], converter.lines)
    end
  end

  def test_convert_line_link
    converter = Converter.new("dummy.hiki")

    input_data = [
                  "[[RAA:hoge]]",
                  "[[ruby-list:123]]",
                  "[[RWiki:abc]]",
                  "[[hoge|http://aaa.com/]]"
                ]

    converter.stub(:lines, input_data) do
      converter.convert_line

      expected_data = [
        "[RAA:hoge](http://raa.ruby-lang.org/project/hoge)",
        "[ruby-list:123](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/123)",
        "[RWiki:abc](http://pub.cozmixng.org/~the-rwiki/rw-cgi.rb?cmd=view;name=abc)",
        "[hoge](http://aaa.com/)"
      ]

      assert_equal(expected_data, converter.lines)
    end
  end

  def test_convert_line_image
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["hoge", "{{attach_view('logo2.png')}}"]) do
      converter.convert_line
      assert_equal(
        [
          "hoge",
          "<img src='{{site.baseurl}}/images/dummy/logo2.png' alt='logo2.png'></img>"
        ], converter.lines)
    end
  end

  def test_convert_line_definition
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["hoge", ":aaaaa: bbbb"]) do
      converter.convert_line
      assert_equal(["hoge", "__aaaaa__  bbbb\n"], converter.lines)
    end
  end

  def test_convert_line_italic
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["hoge", "''aaa''"]) do
      converter.convert_line
      assert_equal(["hoge", " _aaa_ "], converter.lines)
    end
  end

  def test_convert_line_isbn_image
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["hoge", "{{isbn_image_hoge}}"]) do
      converter.convert_line
      assert_equal(["hoge", "{% isbn_image_hoge %}"], converter.lines)
    end
  end

  def test_convert_line_backnumber
    converter = Converter.new("dummy.hiki")

    converter.stub(:lines,["hoge", "{{backnumber('abc')}}"]) do
      converter.convert_line
      assert_equal(["hoge", "\n{% for post in site.tags.abc%}\n  - [{{ post.title }}]({{ post.url }})\n{% endfor %}\n"], converter.lines)
    end
  end

  def test_convert_source
    converter = Converter.new("dummy.hiki")
    bodies = [" puts 'Hello World'\n", " puts 'Hogehoge'\n", "\n", "あいう\n"]
    expect = ["\n```ruby\nputs 'Hello World'\n", "puts 'Hogehoge'\n", "```\n\n", "あいう\n"]

    converter.stub(:lines, bodies) do
      converter.convert_body
      assert_equal(expect, converter.lines)
    end
  end

  def test_convert_footnote
    converter = Converter.new("dummy.hiki")
    bodies = ["ほげ{{fn('aaa')}}", "bbb", "ccc"]
    expect = ["ほげ<sup id='fnref1'><a href='#fn1' rel='footnote'>1</a></sup>",
              "bbb", "ccc",
              "<div =class'footnotes'><ol>",
              "<li id='fn1'><p>aaa<a href='#fnref1' rev='footnote'>←</a></p></li>\n",
              "</ol></div>"]

    converter.stub(:lines, bodies) do
      converter.convert_body
      assert_equal(expect, converter.lines)
    end
  end

  def test_convert_table
    converter = Converter.new("dummy.hiki")
    bodies = ["||Win32||X11||MacOSX||MacOSClassic", "|| ○ || ○|| ○ || ○ "]
    expect = ["\n|Win32|X11|MacOSX|MacOSClassic|\n|---|---|---|---|\n",
              "| ○ | ○| ○ | ○ |\n"]

    converter.stub(:lines, bodies) do
      converter.convert_body
      assert_equal(expect, converter.lines)
    end
  end





end
