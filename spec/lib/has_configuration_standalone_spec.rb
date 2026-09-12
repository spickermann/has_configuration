# frozen_string_literal: true

# Fresh-process regressions keep the complete program next to its assertions.
# standard:disable RSpec/ExampleLength

RSpec.describe HasConfiguration do
  it "loads plain YAML without loading Rails, ActiveSupport, OpenStruct or ERB", :aggregate_failures do
    expect_ruby_output("enabled: false\nnested: {value: first}", "ok\n", <<~RUBY)
      require 'has_configuration'
      c = HasConfiguration::Configuration.new(Class, file: ARGV.fetch(0))
      abort 'value mismatch' unless c.enabled == false && c.nested.value == 'first'
      abort 'optional libraries loaded' if defined?(Rails) || defined?(ActiveSupport) || defined?(OpenStruct) || defined?(ERB)
      puts 'ok'
    RUBY
  end

  it "loads ERB explicitly in a fresh process without Rails", :aggregate_failures do
    expect_ruby_output("value: <%= 20 + 22 %>", "42\n", <<~RUBY)
      require 'has_configuration/configuration'
      abort 'ERB preloaded' if defined?(ERB)
      c = HasConfiguration::Configuration.new(Class, file: ARGV.fetch(0))
      abort 'unrelated libraries loaded' if defined?(ActiveSupport) || defined?(OpenStruct)
      puts c.value
    RUBY
  end

  it "keeps plain YAML functional when optional gems cannot be loaded", :aggregate_failures do
    expect_ruby_output("value: first", "first\n", <<~RUBY)
      module MissingOptionalLibraries
        def require(path)
          raise LoadError, path if path.match?(/\\A(?:erb|ostruct|active_support|rails)/)
          super
        end
      end
      Kernel.prepend(MissingOptionalLibraries)
      require 'has_configuration'
      puts HasConfiguration::Configuration.new(Class, file: ARGV.fetch(0)).value
    RUBY
  end

  it "explains the missing optional ERB gem instead of returning raw template text", :aggregate_failures do
    File.write(config_file, "value: <%= 42 %>")
    output, _error, status = ruby_process(<<~RUBY, config_file)
      module MissingERB
        def require(path)
          raise LoadError, 'missing erb' if path == 'erb'
          super
        end
      end
      Kernel.prepend(MissingERB)
      require 'has_configuration'
      begin
        HasConfiguration::Configuration.new(Class, file: ARGV.fetch(0))
      rescue LoadError => e
        puts e.message
      end
    RUBY
    expect(status).to be_success
    expect(output).to include("requires the optional erb gem")
  end

  it "explains the missing optional ActiveSupport gem only when requested", :aggregate_failures do
    File.write(config_file, "value: first")
    output, _error, status = ruby_process(<<~RUBY, config_file)
      module MissingActiveSupport
        def require(path)
          raise LoadError, 'missing activesupport' if path.start_with?('active_support')
          super
        end
      end
      Kernel.prepend(MissingActiveSupport)
      require 'has_configuration'
      c = HasConfiguration::Configuration.new(Class, file: ARGV.fetch(0))
      abort unless c.to_h == {'value' => 'first'}
      begin
        c.to_h(:indifferent)
      rescue LoadError => e
        puts e.message
      end
    RUBY
    expect(status).to be_success
    expect(output).to include("requires the optional activesupport gem")
  end
end

# standard:enable RSpec/ExampleLength
