# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.authors = ["Martin Spickermann"]
  spec.email = ["spickermann@gmail.com"]
  spec.homepage = "https://github.com/spickermann/has_configuration"
  spec.license = "MIT"

  spec.name = "has_configuration"
  spec.version = HasConfiguration::VERSION::STRING

  spec.summary = "Simple configuration handling"
  spec.description = <<-DESCRIPTION
    Loads trusted YAML settings into deeply immutable configuration objects
    with class and instance getters and optional Rails, ERB and ActiveSupport integration.
  DESCRIPTION

  spec.files = Dir.glob(
    ["CHANGELOG.md", "MIT-LICENSE", "README.md", "RELEASING.md", "lib/**/*.rb", "spec/**/*"], base: __dir__
  ).select { |file| File.file?(File.join(__dir__, file)) }.sort

  spec.require_path = ["lib"]

  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
end
