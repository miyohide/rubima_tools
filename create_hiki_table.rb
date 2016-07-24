table_string = "| issue | name | check | remark |\n|---|---|---|---|\n"

Dir.glob("data/00*.hiki") { |f|
  issue, name = File.basename(f, ".hiki").split("-", 2)
  name = "cover" if name.nil?
  table_string += "|#{issue}|#{name}|　|　|\n"
}

puts table_string
