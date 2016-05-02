def convert_images(body, filename)
  image_dir = '{{site.baseurl}}/images/' + filename.sub("\.hiki", "") + '/'

  body.map do |line|
    line.gsub(/\{\{attach_view\('(.+)'\)\}\}/) { "<img src='#{image_dir}#{$1}' alt='#{$1}'></img>" }
  end
end

def convert_footnote(body)
  footnote_counter = 0
  footnotes = []

  body = body.map do |line|
    line.gsub(/{{fn\(\'(.+?)\'\)}}/) do
      footnote_counter += 1
      footnotes << footnote_body(footnote_counter, $1)
      "#{footnote_link(footnote_counter)}"
    end
  end

  unless footnotes.nil?
    footnotes.unshift "<div =class'footnotes'><ol>"
    footnotes.push "</ol></div>"
  end

  body.concat(footnotes)
end

def footnote_link(counter)
  "<sup id='fnref#{counter}'><a href='\#fn#{counter}' rel='footnote'>#{counter}</a></sup>"
end

def footnote_body(counter, body)
  "<li id='fn#{counter}'><p>#{body}<a href='\#fnref#{counter}' rev='footnote'>←</a></p></li>"
end

def convert_definition(body)
  body.map do |line|
    if line =~ /\A:([^:]+):(.+)\Z/
      line.sub(/\A:([^:]+):(.+)\Z/, '<dl><dt>\1</dt><dd>\2</dd></dl>').
      gsub(/\[(.+?)\]\(([^\)]+?)\)/, '<a href="\2">\1</a>')
    else
      line
    end
  end
end

ISSUE_DATE = {
  "0001" => "2004-09-10",
  "0002" => "2004-10-16",
  "0003" => "2004-11-15",
  "0004" => "2004-12-17",
  "0005" => "2005-02-15",
  "0006" => "2005-05-09",
  "0007" => "2005-06-19",
  "0008" => "2005-07-19",
  "0009" => "2005-09-06",
  "0010" => "2005-10-10",
  "0011" => "2005-11-16",
  "0012" => "2005-12-23",
  "0013" => "2006-02-20",
  "0014" => "2006-05-15",
  "0015" => "2006-07-13",
  "0016" => "2006-09-20",
  "0017" => "2006-11-26",
  "0018" => "2007-02-28",
  "0019" => "2007-05-18"
}

ARGV.each do |filename|
  lines = File.readlines(filename)

  # 最初の行にはタイトルが入っているものと仮定
  first_line = lines.shift.chomp

  dirname = File.dirname(filename)
  basename = File.basename(filename)
  # ファイル名の命名規則。最初の4文字は発行した号
  issue_num = basename[0, 4]

  # Jekyll用のヘッダ
  headers = [ "---\n",
    "layout: post\n",
    "title: #{first_line}\n",
    "short_title: #{first_line}\n",
    "tags: #{issue_num}\n",
    "---\n\n"]

  body = lines.map { |line|
    line.sub(/^(\!+)/) { '#'*($1.length + 1) + ' ' }.  ## イレギュラー対応。タイトルをh1にする
    sub(/^(\*)\s/) { '-'*($1.length) + ' ' }.
    sub(/^\"\"/) { '> ' }.
    gsub(/\[\[([^|]+)\|([^\]]+)\]\]/) { '[' + $1 + '](' + $2 + ')' }.
    gsub(/'''([^']+)'''/) { '***' + $1 + '***' }
  }

  body = convert_images(body, basename)
  body = convert_definition(body)
  body = convert_footnote(body)
  headers.concat(body)

  # Markdownファイルとして出力
  md_filename = File.join(dirname, ISSUE_DATE[issue_num] + "-" + basename.sub(/\.hiki$/, '.md'))
  open(md_filename, 'w') { |f| f.write(headers.join) }
end
