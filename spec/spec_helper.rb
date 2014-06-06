require 'yaml'

require 'has_configuration'
require 'has_configuration/configuration'

if RUBY_VERSION >= "1.9"
  require 'coveralls'
  Coveralls.wear!
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
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
