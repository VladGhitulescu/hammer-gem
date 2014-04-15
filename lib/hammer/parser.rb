require 'lib/hammer/parsers/extensions'

module Hammer
  class Parser

    attr_accessor :optimized, :path, :directory, :variables
    #TODO: Do we move dependencies into a module?
    attr_accessor :dependencies, :wildcard_dependencies
    include ExtensionMapper

    def parse(text)
      return text
    end

    # Used when creating a parser, to initialize variables from the last parser.
    def from_hash(hash)
      self.variables = hash[:variables]
      return self
    end

    # Used to initialize the next parser when chained.
    def to_hash
      {
        dependencies: @dependencies,
        wildcard_dependencies: @wildcard_dependencies,
        variables: @variables
      }
    end

    class << self
      def parse_file(input_directory, filename, optimized, &block)
        data, output = {}, nil

        # Parse here
        Hammer::Parser.for_filename(filename).each do |parser_class|
          parser = parser_class.new().from_hash(data)
          text   = File.open(filename).read()
          output = parser.parse(text)
          data   = parser.to_hash
        end

        block.call(output, data)
      end
    end

  end
end