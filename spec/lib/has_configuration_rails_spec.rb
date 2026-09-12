# frozen_string_literal: true

RSpec.describe HasConfiguration, :rails do
  it "uses the defaults of a real initialized Rails application" do # standard:disable RSpec/ExampleLength
    root = File.dirname(config_file)
    Dir.mkdir(File.join(root, "config"))
    File.write(File.join(root, "config", "service.yml"), "test: {value: rails, enabled: false}")
    source = <<~RUBY
      ENV['RAILS_ENV'] = 'test'
      require 'has_configuration'
      require 'rails'
      require 'rails/application'
      require 'logger'
      class TestApplication < Rails::Application
        config.eager_load = false
        config.secret_key_base = 'test-secret-not-used-outside-this-process'
        config.logger = Logger.new(File::NULL)
      end
      TestApplication.config.root = ARGV.fetch(0)
      TestApplication.initialize!
      class Service
        has_configuration
      end
      abort 'wrong configuration' unless Service.configuration.value == 'rails'
      abort 'lost false' unless Service.new.configuration.enabled == false
      abort 'not frozen' unless Service.configuration.frozen?
      puts "Rails #{ENV.fetch("RAILS_VERSION")} integration passed"
    RUBY
    output, error, status = Open3.capture3(RbConfig.ruby, "-I", File.expand_path("../../lib", __dir__), "-e", source, root)
    expect(status.success?).to be(true), "#{output}\n#{error}"
  end

  it "exports detached indifferent hashes without changing the default", :aggregate_failures do # standard:disable RSpec/ExampleLength
    config = configuration_from("items: [[{name: original}]]")
    snapshot = config.to_h(:indifferent)
    expect(snapshot).to be_a(ActiveSupport::HashWithIndifferentAccess)
    expect(snapshot[:items][0][0]["name"]).to eq("original")
    snapshot[:items][0][0][:name].replace("changed")
    expect(config.items[0][0].name).to eq("original")
    expect(config.to_h).to be_instance_of(Hash)
    expect(config.to_h(:indifferent)[:items][0][0][:name]).to eq("original")
  end
end
