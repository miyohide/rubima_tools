require 'minitest/autorun'
require_relative '../scripts/converter'

class TestConverter < Minitest::Test
  def test_convert_line_ordered_list
    converter = Converter.new("dummy.txt")

    converter.stub(:lines,["# aaa", "# bbb", "ccc"]) do
      converter.convert_line
      assert_equal(["1. aaa", "1. bbb", "ccc"], converter.lines)
    end
  end

  def test_convert_line_section
    converter = Converter.new("dummy.txt")

    converter.stub(:lines,["!aaa", "!bbb"]) do
      converter.convert_line
      assert_equal(["## aaa", "## bbb"], converter.lines)
    end
  end

  def test_convert_line_unordered_list
    converter = Converter.new("dummy.txt")

    converter.stub(:lines,["* aaa", "* bbb"]) do
      converter.convert_line
      assert_equal(["- aaa", "- bbb"], converter.lines)
    end
  end

  def test_convert_line_strong
    converter = Converter.new("dummy.txt")

    converter.stub(:lines,["hoge", "'''aaaaa'''"]) do
      converter.convert_line
      assert_equal(["hoge", "***aaaaa***"], converter.lines)
    end
  end

  def test_convert_line_link
    converter = Converter.new("dummy.txt")

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

  def test_convert_line_definition
    converter = Converter.new("dummy.txt")

    converter.stub(:lines,["hoge", ":aaaaa: bbbb"]) do
      converter.convert_line
      assert_equal(["hoge", "__aaaaa__  bbbb\n"], converter.lines)
    end
  end

  def test_convert_line_italic
    converter = Converter.new("dummy.txt")

    converter.stub(:lines,["hoge", "''aaa''"]) do
      converter.convert_line
      assert_equal(["hoge", " _aaa_ "], converter.lines)
    end
  end

  def test_convert_line_isbn_image
    converter = Converter.new("dummy.txt")

    converter.stub(:lines,["hoge", "{{isbn_image_hoge}}"]) do
      converter.convert_line
      assert_equal(["hoge", "{% isbn_image_hoge %}"], converter.lines)
    end
  end

end
