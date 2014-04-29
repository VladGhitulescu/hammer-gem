require 'rdiscount'
require 'parsers/html'

module Hammer
  class MarkdownParser < Parser

    accepts :md
    register_as_default_for_extensions :md
    returns :html

    def to_format(format)
      if format == :html
        parse(@markdown)
      elsif format == :md
        @markdown
      end
    end

    def parse(text)
      @markdown = text
      parser = Hammer::HTMLParser.new(:path => @path)
      parser.directory = @directory
      text = parser.parse(text) # beforehand
      text = convert(text)
      text = text[0..-2] while text.end_with?("\n")
      text
    end

    private

    def convert(markdown)
      # doc = Kramdown::Document.new(markdown, options).to_html
      RDiscount.new(markdown, :smart).to_html
    end

  end
end