require "uri"

class Converter

  ISSUE_DATE = {
    "0001" => "2004-09-10", "0002" => "2004-10-16",
    "0003" => "2004-11-15", "0004" => "2004-12-17",
    "0005" => "2005-02-15", "0006" => "2005-05-09",
    "0007" => "2005-06-19", "0008" => "2005-07-19",
    "0009" => "2005-09-06", "0010" => "2005-10-10",
    "0011" => "2005-11-16", "0012" => "2005-12-23",
    "0013" => "2006-02-20", "0014" => "2006-05-15",
    "0015" => "2006-07-13", "0016" => "2006-09-20",
    "0017" => "2006-11-26", "0018" => "2007-02-28",
    "0019" => "2007-05-18", "0020" => "2007-08-15",
    "0021" => "2007-09-29", "0022" => "2007-12-17",
    "0023" => "2008-03-31", "0024" => "2008-10-01",
    "0025" => "2009-02-07", "0026" => "2009-06-30",
    "0027" => "2009-09-13", "0028" => "2009-12-07",
    "0029" => "2010-03-16", "0030" => "2010-06-15",
    "0031" => "2010-10-07", "0032" => "2011-01-31",
    "0033" => "2011-04-05", "0034" => "2011-06-12",
    "0035" => "2011-09-26", "0036" => "2011-11-28",
    "0037" => "2012-02-05", "0038" => "2012-05-22",
    "0039" => "2012-09-05", "0040" => "2012-11-25",
    "0041" => "2013-02-24", "0042" => "2013-05-29",
    "0043" => "2013-07-31", "0044" => "2013-09-30",
    "0045" => "2013-12-21", "0046" => "2014-04-05",
    "0047" => "2014-06-30", "0048" => "2014-09-19",
    "0049" => "2014-12-14", "0050" => "2015-05-10",
    "0051" => "2015-09-06", "0052" => "2015-12-06"
  }

  attr_accessor :filename, :lines

  def initialize(filename)
    @filename = filename
    @lines = []
    @title = nil
    @basename = File.basename(@filename)
    @issue_num = @basename[0, 4]
    if @basename == "#{@issue_num}.hiki"
      @basename = "#{@issue_num}-index.hiki"
    end
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
    file_read if lines.size == 0

    # convert_source(lines)
    convert_footnote(lines)
    convert_table(lines)
  end

  def create_header
    file_read if lines.size == 0

    tags = "#{@issue_num}"

    @basename.match(/\d{4}\-([^\.]+).hiki/) do |md|
      tags = "#{tags} #{md[1]}"
    end

    header =
      [ "---\n",
        "layout: post\n",
        "title: #{@title}\n",
        "short_title: #{@title}\n",
        "tags: #{tags}\n",
        "---\n\n"
      ]
    lines.unshift(*header)
  end

  def output_file
    dirname = File.dirname(@filename)

    output_filename = File.join(dirname, ISSUE_DATE[@issue_num] + "-" + @basename.sub(/\.hiki$/, '.md'))
    open(output_filename, 'w') { |f| f.write(lines.join) }
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
    line.gsub!(/'''([^']+)'''/) { '**' + $1 + '**' }
  end

  def convert_link(line)
    convert_raa_link(line)
    convert_rubylist_link(line)
    convert_rubydev_link(line)
    convert_rubytalk_link(line)
    convert_rubycore_link(line)
    convert_rwiki_link(line)
    convert_normal_link(line)
  end

  def convert_quote(line)
    convert_markdown_in_quote(line)
    convert_normal_quote(line)
  end

  def convert_images(line)
    image_dir = '{{site.baseurl}}/images/' + @basename.sub("\.hiki", "") + '/'

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
      if line.chomp =~ /\A\s\s[^-].+\z/
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
      footnotes.unshift "<div class='footnotes'><ol>"
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
    @title = @lines.shift.chomp
  end

  def convert_raa_link(line)
    line.gsub!(/\[\[RAA:([^\]]+)\]\]/) { '[RAA:' + $1 + '](http://raa.ruby-lang.org/project/' + $1 + ')'}
  end

  def convert_rubylist_link(line)
    line.gsub!(/\[\[ruby\-list:(\d+)\]\]/) {'[ruby-list:' + $1 + '](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/' + $1 + ')'}
  end

  def convert_rubytalk_link(line)
    line.gsub!(/\[\[ruby-talk:(\d+)\]\]/) { '[ruby-talk:' + $1 + '](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/' + $1 + ')' }
  end

  def convert_rubycore_link(line)
    line.gsub!(/\[\[ruby-core:(\d+)\]\]/) { '[ruby-core:' + $1 + '](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/' + $1 + ')' }
  end

  def convert_rubydev_link(line)
    line.gsub!(/\[\[ruby-dev:(\d+)\]\]/) { '[ruby-dev:' + $1 + '](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-dev/' + $1 + ')' }
  end

  def convert_rwiki_link(line)
    line.gsub!(/\[\[RWiki:([^\]]+)\]\]/) { '[RWiki:' + $1 + '](http://pub.cozmixng.org/~the-rwiki/rw-cgi.rb?cmd=view;name=' + URI.encode_www_form_component($1.encode("EUC-JP")) + ')' }
  end

  def convert_normal_link(line)
    line.gsub!(/\[\[([^|\]]+)\|([^\]]+)\]\]/) { '[' + $1 + '](' + $2 + ')' }
  end

  def convert_markdown_in_quote(line)
    line.sub!(/\A\"\"#/) { '> \#'}
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
    "[^#{counter}]"
    # "<sup id='fnref#{counter}'><a href='\#fn#{counter}' rel='footnote'>#{counter}</a></sup>"
  end

  def footnote_body(counter, body)
    "[^#{counter}]: #{body}"
    # "<li id='fn#{counter}'><p>#{body}<a href='\#fnref#{counter}' rev='footnote'>←</a></p></li>\n"
  end
end
