# frozen_string_literal: true

RSpec.describe HasConfiguration::Configuration do
  it "preserves false and nil values at every depth", :aggregate_failures do
    config = configuration_from("enabled: false\nempty: null\nnested: {enabled: false, empty: null}\n")
    expect([config.enabled, config.empty, config.nested.enabled, config.nested.empty]).to eq([false, nil, false, nil])
  end

  it "reports existing falsy keys and rejects missing keys", :aggregate_failures do
    config = configuration_from("enabled: false\nnested: {}\n")
    expect(config).to respond_to(:enabled)
    expect(config).not_to respond_to(:missing)
    expect { config.missing }.to raise_error(NoMethodError)
    expect { config.nested.missing }.to raise_error(NoMethodError)
  end

  it "supports hashes inside arrays and arrays inside arrays", :aggregate_failures do
    config = configuration_from("items: [{name: first}, [{name: second}]]\n")
    expect([config.items[0].name, config.items[1][0].name]).to eq(%w[first second])
  end

  it "does not delegate arbitrary OpenStruct methods or setters", :aggregate_failures do
    config = configuration_from("enabled: true\n")
    expect { config.public_send(:enabled=, false) }.to raise_error(NoMethodError)
    expect(config.enabled).to be(true)
    expect(config).not_to respond_to(:table, :delete_field)
  end

  it "rejects arguments, keywords and blocks on getters", :aggregate_failures do
    config = configuration_from("value: ok\n")
    expect { config.value(1) }.to raise_error(ArgumentError)
    expect { config.value(test: true) }.to raise_error(ArgumentError)
    expect { config.value {} }.to raise_error(ArgumentError)
  end

  it "keeps Ruby methods available despite colliding keys", :aggregate_failures do
    config = configuration_from("send: blocked\nrespond_to?: blocked\nclass: blocked\nto_h: blocked\nnormal: ok\n")
    expect(config.public_send(:normal)).to eq("ok")
    expect(config).to respond_to(:normal)
    expect(config.class).to eq(described_class)
    expect(config.to_h.fetch("to_h")).to eq("blocked")
  end

  it "uses the same collision policy inside nested mappings", :aggregate_failures do
    config = configuration_from("nested: {class: value, to_h: value, normal: ok}\n")
    expect(config.nested.class).to eq(HasConfiguration::Node)
    expect(config.nested.to_h.fetch("class")).to eq("value")
    expect(config.nested.normal).to eq("ok")
  end

  it "does not expose settings in missing-method error messages", :aggregate_failures do
    config = configuration_from("password: super-secret-value\n")
    expect { config.missing }.to raise_error(NoMethodError) { |error| expect(error.message).not_to include("super-secret-value") }
  end

  it "deeply freezes every configuration value", :aggregate_failures do # standard:disable RSpec/ExampleLength
    config = configuration_from("nested: {name: first}\nitems: [{name: second}, [third]]\n")
    expect(config).to be_frozen
    expect(config.nested).to be_frozen
    expect { config.nested.name << "!" }.to raise_error(FrozenError)
    expect { config.items << "!" }.to raise_error(FrozenError)
    expect { config.items[1][0].replace("new") }.to raise_error(FrozenError)
  end

  it "returns plain string-keyed hashes by default", :aggregate_failures do
    config = configuration_from("nested: {name: first}\n")
    expect(config.to_h).to be_instance_of(Hash)
    expect(config.to_h).to eq("nested" => {"name" => "first"})
  end

  [:symbolized, :stringify, nil].each do |type|
    it "returns independent deep mutable copies for #{type.inspect}", :aggregate_failures do # standard:disable RSpec/ExampleLength
      config = configuration_from("nested: {name: first}\nitems: [{name: second}, [third]]\n")
      snapshot = config.to_h(type)
      nested, items, name = (type == :symbolized) ? [:nested, :items, :name] : %w[nested items name]
      snapshot[nested][name].replace("changed")
      snapshot[items][0][name] = "changed"
      snapshot[items][1] << "changed"
      expect(config.nested.name).to eq("first")
      expect(config.items[0].name).to eq("second")
      expect(config.to_h(type)).not_to eq(snapshot)
    end
  end

  it "converts keys throughout nested arrays", :aggregate_failures do
    config = configuration_from("items: [[{nested: {name: first}}]]\n")
    expect(config.to_h(:symbolized)).to eq(items: [[{nested: {name: "first"}}]])
    expect(config.to_h(:stringify)).to eq("items" => [[{"nested" => {"name" => "first"}}]])
  end

  it "does not depend on the order in which views are requested", :aggregate_failures do
    config = configuration_from("nested: {name: original}\n")
    config.to_h(:symbolized)[:nested][:name].replace("changed")
    config.to_h(:stringify)["nested"]["name"] = "changed"
    expect(config.nested.name).to eq("original")
    expect(config.to_h).to eq("nested" => {"name" => "original"})
  end

  ["", "# empty\n", "null", "{}"].each do |yaml|
    it "accepts an empty mapping for #{yaml.inspect}", :aggregate_failures do
      expect(configuration_from(yaml).to_h).to eq({})
    end
  end

  ["false", "true", "42", "text", "[one, two]"].each do |yaml|
    it "rejects a non-mapping root #{yaml.inspect}", :aggregate_failures do
      expect { configuration_from(yaml) }.to raise_error(ArgumentError, /must be a mapping/)
    end
  end

  ["null", "false", "true", "42", "text", "[one, two]"].each do |yaml|
    it "rejects a non-mapping environment #{yaml.inspect}", :aggregate_failures do
      expect { configuration_from("test: #{yaml}\n", env: "test") }.to raise_error(ArgumentError, /environment.*must be a mapping/)
    end
  end

  it "rejects a missing environment during loading", :aggregate_failures do
    expect { configuration_from("test: {}", env: :production) }.to raise_error(ArgumentError, /Missing configuration environment.*production/)
  end

  it "accepts an explicitly empty environment and symbol names", :aggregate_failures do
    expect(configuration_from("test: {}", env: :test).to_h).to eq({})
  end

  it "disables environment selection explicitly", :aggregate_failures do
    expect(configuration_from("test: {}", env: false).to_h).to eq("test" => {})
  end

  it "supports aliases and explicit overrides of merge defaults", :aggregate_failures do
    config = configuration_from("defaults: &defaults {name: default, count: 1}\ntest: {<<: *defaults, name: test}\n", env: :test)
    expect(config.to_h).to eq("name" => "test", "count" => 1)
  end

  it "allows repeated aliases without mistaking them for cycles", :aggregate_failures do
    config = configuration_from("base: &base {name: first}\nitems: [*base, *base]\n")
    expect(config.items.map(&:name)).to eq(%w[first first])
  end

  ["root: &root {child: *root}", "root: &root [*root]"].each do |yaml|
    it "rejects cyclic aliases in #{yaml}", :aggregate_failures do
      expect { configuration_from(yaml) }.to raise_error(ArgumentError, /Cyclic configuration alias/)
    end
  end

  ["value: 1\nvalue: 2", "nested: {value: 1, value: 2}", "items: [{value: 1, value: 2}]"].each do |yaml|
    it "rejects duplicate keys in #{yaml.inspect}", :aggregate_failures do
      expect { configuration_from(yaml) }.to raise_error(ArgumentError, /Duplicate configuration key/)
    end
  end

  ["1: one", "true: value", "on: value", "? [one, two]\n: value"].each do |yaml|
    it "rejects non-string keys in #{yaml.inspect}", :aggregate_failures do
      expect { configuration_from(yaml) }.to raise_error(ArgumentError, /keys must be strings/)
    end
  end

  it "accepts quoted numeric and boolean keys", :aggregate_failures do
    expect(configuration_from("'1': one\n'on': value\n").to_h).to eq("1" => "one", "on" => "value")
  end

  it "preserves YAML syntax errors with a filename", :aggregate_failures do
    expect { configuration_from("broken: [") }.to raise_error(Psych::SyntaxError) { |error| expect(error.file).to eq(config_file) }
  end

  it "does not allow object deserialization", :aggregate_failures do
    expect { configuration_from("value: !ruby/object:Object {}") }.to raise_error(Psych::DisallowedClass)
  end

  it "requires dates to be quoted strings", :aggregate_failures do
    expect { configuration_from("value: 2026-09-12") }.to raise_error(Psych::DisallowedClass)
    expect(configuration_from("value: '2026-09-12'").value).to eq("2026-09-12")
  end

  it "preserves missing-file errors", :aggregate_failures do
    expect { described_class.new(Class, file: config_file) }.to raise_error(Errno::ENOENT)
  end

  it "evaluates ERB when requested by the file", :aggregate_failures do
    expect(configuration_from("value: <%= 20 + 22 %>").value).to eq(42)
  end

  it "does not reevaluate files after the initial load", :aggregate_failures do
    config = configuration_from("value: original")
    File.write(config_file, "value: changed")
    expect(config.value).to eq("original")
  end

  it "rejects additional YAML documents instead of silently ignoring them" do
    expect { configuration_from("---\nvalue: first\n---\nvalue: second\n") }.to raise_error(ArgumentError, /single YAML document/)
  end

  it "rejects duplicates even when one spelling is quoted" do
    expect { configuration_from("value: first\n'value': second\n") }.to raise_error(ArgumentError, /Duplicate configuration key/)
  end

  it "allows merge sequences with explicit overrides" do
    config = configuration_from("first: &first {name: first}\nsecond: &second {count: 2}\ntest: {<<: [*first, *second], name: override}\n", env: :test)
    expect(config.to_h).to eq("name" => "override", "count" => 2)
  end

  it "preserves ERB evaluation failures" do
    expect { configuration_from("value: <%= raise ArgumentError, 'template failure' %>") }.to raise_error(ArgumentError, "template failure")
  end

  it "handles empty and falsy array values" do
    expect(configuration_from("items: [null, false, [], {}]").to_h).to eq("items" => [nil, false, [], {}])
  end
end
