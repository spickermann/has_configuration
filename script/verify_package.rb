# frozen_string_literal: true

require "rubygems/package"
require "tmpdir"
require "open3"
require "rbconfig"
require "digest"

project = File.expand_path("..", __dir__)
existing_artifact = File.expand_path(ARGV.first) if ARGV.first

Dir.mktmpdir("has-configuration-package") do |directory|
  artifact = existing_artifact || File.join(directory, "has_configuration.gem")
  Dir.chdir(project) do
    specification = Gem::Specification.load("has_configuration.gemspec")
    abort "Runtime dependencies must be empty" unless specification.runtime_dependencies.empty?
    abort "Unexpected minimum Ruby" unless specification.required_ruby_version.to_s == ">= 3.3.0"
    required = %w[README.md CHANGELOG.md RELEASING.md MIT-LICENSE lib/has_configuration.rb lib/has_configuration/node.rb]
    abort "Missing package files" unless (required - specification.files).empty?
    Gem::Package.build(specification, false, false, artifact) unless existing_artifact
    packaged = Gem::Package.new(artifact).spec
    unless packaged.name == specification.name && packaged.version == specification.version &&
        packaged.files == specification.files && packaged.runtime_dependencies.empty? &&
        packaged.required_ruby_version == specification.required_ruby_version
      abort "Package metadata does not match the release source"
    end
  end

  environment = {
    "GEM_HOME" => File.join(directory, "gems"),
    "GEM_PATH" => File.join(directory, "gems"),
    "RUBYOPT" => nil,
    "RUBYLIB" => nil,
    "BUNDLE_GEMFILE" => nil,
    "BUNDLE_BIN_PATH" => nil
  }
  output, error, status = Open3.capture3(environment, RbConfig.ruby, "-rrubygems/gem_runner",
    "-e", "Gem::GemRunner.new.run(ARGV)", "--", "install", artifact, "--local", "--no-document", chdir: directory)
  abort "Installation failed:\n#{output}\n#{error}" unless status.success?

  File.write(File.join(directory, "settings.yml"), "enabled: false\nempty: null\nitems: [{name: original}]\n")
  smoke = <<~'SMOKE'
    require 'has_configuration'
    installed = Gem.loaded_specs.fetch('has_configuration')
    abort 'loaded from source checkout' unless File.realpath(installed.full_gem_path).start_with?(File.realpath(ENV.fetch('GEM_HOME')) + '/')
    abort 'unexpected runtime dependencies' unless installed.runtime_dependencies.empty?
    abort 'optional dependency loaded' if defined?(Rails) || defined?(ERB) || defined?(ActiveSupport) || defined?(OpenStruct)
    class Service
      has_configuration file: 'settings.yml'
    end
    class Child < Service; end
    c = Service.configuration
    abort 'falsy values lost' unless c.enabled == false && c.empty.nil?
    abort 'not frozen' unless c.frozen? && c.items.frozen? && c.items.first.name.frozen?
    abort 'inheritance broken' unless Child.new.configuration.equal?(c)
    snapshot = c.to_h(:symbolized)
    snapshot[:items].first[:name].replace('changed')
    abort 'snapshot shares state' unless c.items.first.name == 'original'
    begin
      c.missing
      abort 'missing getter did not raise'
    rescue NoMethodError
    end
    puts "Installed #{installed.full_name} on Ruby #{RUBY_VERSION}: plain YAML smoke passed"
  SMOKE
  output, error, status = Open3.capture3(environment, RbConfig.ruby, "-e", smoke, chdir: directory)
  abort "Smoke test failed:\n#{output}\n#{error}" unless status.success?
  puts output

  File.write(File.join(directory, "template.yml"), "value: <%= 20 + 22 %>\n")
  template_smoke = <<~SMOKE
    require 'has_configuration'
    abort 'ERB preloaded' if defined?(ERB)
    begin
      c = HasConfiguration::Configuration.new(Class, file: 'template.yml')
      abort 'ERB result incorrect' unless c.value == 42
      puts 'Installed package: fresh ERB smoke passed'
    rescue LoadError => error
      abort error.message unless error.message.include?('requires the optional erb gem')
      puts 'Installed package: ERB absent; actionable optional-dependency error verified'
    end
  SMOKE
  output, error, status = Open3.capture3(environment, RbConfig.ruby, "-e", template_smoke, chdir: directory)
  abort "Template smoke test failed:\n#{output}\n#{error}" unless status.success?
  puts output
  puts "Package SHA256: #{Digest::SHA256.file(artifact).hexdigest}"
end
