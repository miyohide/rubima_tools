require "uri"

class Converter
  attr_accessor :filename, :lines

  def initialize(filename)
    @filename = filename
    @lines = []
  end

  def convert_line
    file_read if lines.size == 0

    lines.each do |line|
      convert_ordered_list(line)
      convert_section(line)
      convert_unordered_list(line)
      convert_strong(line)
      convert_link(line)
      convert_quote(line)
      convert_images(line)
      convert_definition(line)
      convert_italic(line)
      convert_isbn_image(line)
      convert_backnumber(line)
    end
  end

  def convert_body
    convert_source(lines)
    convert_footnote(lines)
    convert_table(lines)
  end

  def convert_ordered_list(line)
    line.sub!(/^# /) { '1. ' }
  end

  def convert_section(line)
    ## イレギュラー対応。タイトルをh1にする
    line.sub!(/^(\!+)/) { '#'*($1.length + 1) + ' ' }
  end

  def convert_unordered_list(line)
    line.sub!(/^(\*+)\s/) { ' '*($1.length - 1) + '- ' }
  end

  def convert_strong(line)
    line.gsub!(/'''([^']+)'''/) { '***' + $1 + '***' }
  end

  def convert_link(line)
    convert_raa_link(line)
    convert_rubylist_link(line)
    convert_rwiki_link(line)
    convert_normal_link(line)
  end

  def convert_quote(line)
    convert_normal_link(line)
    #line.sub!(/\A\"\"#/) { '> \#'}.
  end

  def convert_images(line)
    image_dir = '{{site.baseurl}}/images/' + @filename.sub("\.hiki", "") + '/'

    line.gsub!(/\{\{attach_view\('([^\)]+)'\)\}\}/) do
      image_tag(image_dir, $1)
    end
  end

  def convert_definition(line)
    line.sub!(/\A:([^:]+):(.+)\Z/, '__\1__ \2' + "\n")
  end

  def convert_italic(line)
    line.gsub!(/\'\'(.+)\'\'/) { ' _' + $1 + '_ ' }
  end

  def convert_isbn_image(line)
    line.gsub!(/\{\{isbn_image_([^\}]+)\}\}/) { '{% isbn_image_' + $1 + ' %}'}
  end

  def convert_backnumber(line)
    line.sub!(/\{\{backnumber\('(.+)'\)\}\}/) {
      "\n{% for post in site.tags." + $1 + "%}\n" +
      "  - [{{ post.title }}]({{ post.url }})\n" +
      "{% endfor %}\n"
    }
  end

  def convert_source(body)
    source_start = false

    body.map! do |line|
      if line =~ /\A /
        line.sub!(/\A /, '')
        unless source_start
          source_start = true
          line = "\n```ruby\n#{line}"
        end
        line
      else
        if source_start
          source_start = false
          line = "```\n#{line}"
        end
        line
      end
    end
  end

  def convert_footnote(body)
    footnote_counter = 0
    footnotes = []

    body.map! do |line|
      line.gsub(/{{fn\(\'(.+?)\'\)}}/) do
        footnote_counter += 1
        footnotes << footnote_body(footnote_counter, $1)
        "#{footnote_link(footnote_counter)}"
      end
    end

    if footnote_counter > 0
      footnotes.unshift "<div =class'footnotes'><ol>"
      footnotes.push "</ol></div>"
      body.concat(footnotes)
    end

    body
  end

  def convert_table(body)
    table_start = false

    body.map! do |line|
      if line =~ /\A\|\|/
        line = line.chomp + "|\n"
        col_num = line.scan(/\|\|([^\|]+)/).size
        line.gsub!(/\|\|/, '|')
        unless table_start
          table_start = true
          line = "\n" + line + "|---" * col_num + "|\n"
        end
        line
      else
        table_start = false
        line
      end
    end
  end

  private

  def file_read
    @lines = File.readlines(@filename)
  end

  def convert_raa_link(line)
    line.gsub!(/\[\[RAA:([^\]]+)\]\]/) { '[RAA:' + $1 + '](http://raa.ruby-lang.org/project/' + $1 + ')'}
  end

  def convert_rubylist_link(line)
    line.gsub!(/\[\[ruby\-list:(\d+)\]\]/) {'[ruby-list:' + $1 + '](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/' + $1 + ')'}
  end

  def convert_rwiki_link(line)
    line.gsub!(/\[\[RWiki:([^\]]+)\]\]/) { '[RWiki:' + $1 + '](http://pub.cozmixng.org/~the-rwiki/rw-cgi.rb?cmd=view;name=' + URI.encode_www_form_component($1.encode("EUC-JP")) + ')' }
  end

  def convert_normal_link(line)
    line.gsub!(/\[\[([^|\]]+)\|([^\]]+)\]\]/) { '[' + $1 + '](' + $2 + ')' }
  end

  def convert_normal_quote(line)
    line.sub!(/\A\"\"/) { "> " }
  end

  def image_tag(image_dir_name, image_file_name)
    if image_file_name =~ /u26\.gif/
      "<img src='{{site.baseurl}}/images/title_mark.gif' alt='title mark'></img>"
    else
      "<img src='#{image_dir_name}#{image_file_name}' alt='#{image_file_name}'></img>"
    end
  end

  def footnote_link(counter)
    "<sup id='fnref#{counter}'><a href='\#fn#{counter}' rel='footnote'>#{counter}</a></sup>"
  end

  def footnote_body(counter, body)
    "<li id='fn#{counter}'><p>#{body}<a href='\#fnref#{counter}' rev='footnote'>←</a></p></li>\n"
  end

end
