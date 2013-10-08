lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'version'

Gem::Specification.new do |spec|

  spec.authors      = ['Martin Spickermann']
  spec.email        = ['spickermann@gmail.com']
  spec.homepage     = 'https://github.com/spickermann/has_configuation'

  spec.name         = 'has_configuration'
  spec.version      = HasConfiguration::VERSION::STRING
  spec.summary      = 'Simple configuration handling'
  spec.description  = 'Loads configuration setting from a yml file and adds a configuation method to class and instances'
  spec.license      = 'MIT'

  spec.files        = Dir['CHANGELOG', 'MIT-LICENSE', 'README', 'lib/**/*', 'spec/**/*']

  spec.require_path = ['lib']

  if RUBY_VERSION < '1.9'
    spec.add_dependency('activesupport', '< 4.0.0')
  else
    spec.add_dependency('activesupport', '>= 2.3.5')
  end

  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')

end
