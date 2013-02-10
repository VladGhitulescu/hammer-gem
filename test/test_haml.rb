require "./tests.rb"

class TestHaml < Test::Unit::TestCase
  context "A HAML file parser" do
    setup do
      @parser               = Hammer::HAMLParser.new
    end
    
    should "parse haml" do
      @parser.text = "#hello Hi"
      assert_equal "<div id='hello'>Hi</div>\n", @parser.parse()
    end
  end
end