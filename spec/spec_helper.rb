require 'yaml'

require 'has_configuration'
require 'has_configuration/configuration'

require 'coveralls'
Coveralls.wear!

RSpec.configure do |config|
  config.mock_with :rspec

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def mock_file(filename)
  Configuration.any_instance.stub(:raw_file).and_return(File.read(filename))
end

# Mocks Rails Environment
Rails = Class.new do

  def self.root
    Pathname.new("/RAILS_ROOT")
  end

  def self.env
    'development'
  end

end
