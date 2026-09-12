# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  if respond_to?(:cover)
    cover "lib/**/*.rb"
  else
    track_files "lib/**/*.rb"
    add_filter ["/spec/", "/bundle/", "/vendor/"]
  end

  if ENV["CI"]
    require "simplecov-lcov"
    SimpleCov::Formatter::LcovFormatter.config do |config|
      config.report_with_single_file = true
      config.single_report_path = "coverage/lcov.info"
    end
    formatter SimpleCov::Formatter::LcovFormatter
  end
end

require "has_configuration"
require "tmpdir"
require "open3"
require "rbconfig"
require "pathname"

module ConfigurationHelpers
  attr_reader :config_file

  def configuration_from(yaml, **options)
    File.write(@config_file, yaml)
    HasConfiguration::Configuration.new(Class, {file: @config_file, env: nil}.merge(options))
  end

  def ruby_process(source, *arguments)
    Open3.capture3({"RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil},
      RbConfig.ruby, "-I", File.expand_path("../lib", __dir__), "-e", source, *arguments)
  end
end

RSpec.configure do |config|
  config.include ConfigurationHelpers
  config.filter_run_excluding rails: true if ENV.fetch("RAILS_VERSION", "").empty?
  config.around do |example|
    Dir.mktmpdir("has-configuration-spec") do |directory|
      @config_file = File.join(directory, "settings.yml")
      example.run
    end
  end
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
