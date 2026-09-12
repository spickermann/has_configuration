# frozen_string_literal: true

RSpec.describe HasConfiguration do
  def configured_class(yaml)
    File.write(config_file, yaml)
    file = config_file
    Class.new { has_configuration file: file, env: nil }
  end

  it "provides the same immutable configuration on classes and instances", :aggregate_failures do
    klass = configured_class("value: first")
    expect(klass.new.configuration).to equal(klass.configuration)
    expect(klass.configuration).to be_frozen
  end

  it "inherits the nearest configured ancestor through multiple levels", :aggregate_failures do
    parent = configured_class("value: parent")
    child = Class.new(parent)
    grandchild = Class.new(child)
    expect(child.configuration).to equal(parent.configuration)
    expect(grandchild.new.configuration).to equal(parent.configuration)
  end

  it "replaces inherited configuration completely without merging", :aggregate_failures do # standard:disable RSpec/ExampleLength
    parent = configured_class("parent_only: original\nvalue: parent")
    child = Class.new(parent)
    File.write(config_file, "value: child")
    child.has_configuration file: config_file, env: nil
    expect(child.configuration.to_h).to eq("value" => "child")
    expect(parent.configuration.value).to eq("parent")
    expect(Class.new(parent).configuration).to equal(parent.configuration)
    expect(Class.new(child).configuration).to equal(child.configuration)
  end

  it "retains an existing configuration if a replacement cannot load", :aggregate_failures do
    klass = configured_class("value: original")
    File.write(config_file, "false")
    expect { klass.has_configuration file: config_file }.to raise_error(ArgumentError)
    expect(klass.configuration.value).to eq("original")
  end

  it "preserves the macro return value", :aggregate_failures do
    klass = configured_class("value: original")
    expect(klass.has_configuration(file: config_file)).to equal(klass)
  end

  it "keeps the existing global class macro", :aggregate_failures do
    expect(Object).to respond_to(:has_configuration)
    expect(String).to respond_to(:has_configuration)
  end

  it "requires an explicit filename for anonymous classes", :aggregate_failures do
    expect { Class.new.has_configuration }.to raise_error(ArgumentError, /Unable to resolve filename/)
  end

  it "derives a filename from the class name outside Rails", :aggregate_failures do # standard:disable RSpec/ExampleLength
    stub_const("ExampleSettings", Class.new)
    Dir.chdir(File.dirname(config_file)) do
      File.write("examplesettings.yml", "value: standalone")
      ExampleSettings.has_configuration
    end
    expect(ExampleSettings.configuration.value).to eq("standalone")
  end

  it "uses the root and environment of an already loaded Rails", :aggregate_failures do # standard:disable RSpec/ExampleLength
    rails = Data.define(:root, :env).new(root: Pathname.new(File.dirname(config_file)), env: "test")
    stub_const("Rails", rails)
    stub_const("ExampleSettings", Class.new)
    Dir.mkdir(rails.root.join("config"))
    File.write(rails.root.join("config", "examplesettings.yml"), "test: {value: rails}")
    ExampleSettings.has_configuration
    expect(ExampleSettings.configuration.value).to eq("rails")
  end

  it "lets explicit options override Rails defaults", :aggregate_failures do
    stub_const("Rails", Data.define(:env).new(env: "test"))
    config = configuration_from("value: standalone", env: nil)
    expect(config.value).to eq("standalone")
  end

  it "tolerates a Rails constant that is not initialized", :aggregate_failures do
    stub_const("Rails", Module.new)
    File.write(config_file, "value: standalone")
    expect(HasConfiguration::Configuration.new(Class, file: config_file).value).to eq("standalone")
  end

  it "updates inheriting descendants when their parent is explicitly reconfigured", :aggregate_failures do # standard:disable RSpec/ExampleLength
    parent = configured_class("value: original")
    child = Class.new(parent)
    previous = child.configuration
    File.write(config_file, "value: replacement")
    parent.has_configuration file: config_file
    expect(child.configuration.value).to eq("replacement")
    expect(previous.value).to eq("original")
  end
end
