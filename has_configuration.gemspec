lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'version'

Gem::Specification.new do |spec|
  spec.authors      = ['Martin Spickermann']
  spec.email        = ['spickermann@gmail.com']
  spec.homepage     = 'https://github.com/spickermann/has_configuration'
  spec.license      = 'MIT'

  spec.name         = 'has_configuration'
  spec.version      = HasConfiguration::VERSION::STRING

  spec.summary      = 'Simple configuration handling'
  spec.description  = <<-DESCRIPTION
    Loads configuration setting from a yml file and adds a configuation method
    to class and instances
  DESCRIPTION

  spec.files        = Dir['CHANGELOG', 'MIT-LICENSE', 'README', 'lib/**/*', 'spec/**/*']

  spec.require_path = ['lib']

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_dependency('activesupport', '>= 4.2.2')
  spec.add_development_dependency('coveralls')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rubocop')
  spec.add_development_dependency('rubocop-rspec')
end
