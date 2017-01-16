lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'version'

Gem::Specification.new do |spec|
  spec.authors      = ['Martin Spickermann']
  spec.email        = ['spickermann@gmail.com']
  spec.homepage     = 'https://github.com/spickermann/has_configuration'

  spec.name         = 'has_configuration'
  spec.version      = HasConfiguration::VERSION::STRING
  spec.summary      = 'Simple configuration handling'
  spec.description  = <<-EOD
    Loads configuration setting from a yml file and adds a configuation method
    to class and instances
  EOD

  spec.license      = 'MIT'

  spec.files        = Dir['CHANGELOG', 'MIT-LICENSE', 'README', 'lib/**/*', 'spec/**/*']

  spec.require_path = ['lib']

  spec.required_ruby_version = '>= 2.1.0'

  spec.add_dependency('activesupport', '>= 3.2.0')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('coveralls')
  spec.add_development_dependency('rubocop')
end
