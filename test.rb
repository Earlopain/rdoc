require "rdoc"
require "cgi/escape"
require "prism"

code = <<~'RUBY'.freeze
  puts a.==(1)
RUBY
pp RDoc::Parser::PrismColorizer.tokens(Prism.parse(code))
a = RDoc::TokenStream.to_html_prism RDoc::Parser::PrismColorizer.tokens(Prism.parse(code)), code.dup
puts a
puts
puts "-----"
puts
b = RDoc::TokenStream.to_html RDoc::Parser::RipperStateLex.parse(code)
puts b

puts
puts a == b
