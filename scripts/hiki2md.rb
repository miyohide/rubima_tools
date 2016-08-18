require_relative './converter'

ARGV.each do |filename|
  converter = Converter.new(filename)
  converter.convert_line
  converter.convert_body
  converter.create_header

  converter.output_file
end
