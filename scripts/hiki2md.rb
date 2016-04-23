ARGV.each do |filename|
  lines = File.readlines(filename)

  first_line = lines.shift.chomp
  issue_num = filename[0, 4]

  headers = [ "---\n",
    "layout: default\n",
    "title: #{first_line}\n",
    "short_title: #{first_line}\n",
    "tags: #{issue_num} backnumber\n",
    "---\n\n",
    "# #{first_line}\n\n"]

  body = lines.map { |line|
    line.sub(/^(\!+)\s/) { '#'*($1.length + 1) + ' ' }.  ## イレギュラー対応。タイトルをh1にする
    sub(/^(\*)\s/) { '-'*($1.length) + ' ' }.
    gsub(/\[\[([^|]+)\|([^\]]+)\]\]/) { '[' + $1 + '](' + $2 + ')' }.
    gsub(/'''([^']+)'''/) { '***' + $1 + '***' }
  }

  headers.concat(body)

  md_filename = filename.sub(/\.hiki$/, '.md')
  open(md_filename, 'w') { |f| f.write(headers.join) }
end
