require 'has_configuration'

require 'support/rails_mock'

RSpec.describe HasConfiguration::Configuration do
  let(:klass) { Class }

  before do
    allow_any_instance_of(
      Configuration
    ).to receive(:raw_file).and_return(File.read(fixture))
  end

  describe ".new" do
    let(:fixture) { 'spec/fixtures/class.yml' }

    context "when no filename provided" do
      let(:file) { "/RAILS_ROOT/config/class.yml" }

      it "loads default file" do
        expect_any_instance_of(Configuration).to receive(:raw_file).with(file)
        HasConfiguration::Configuration.new(klass)
      end
    end

    context "when filename provided" do
      let(:file) { "foo/bar.yml" }

      it "loads provided file" do
        expect_any_instance_of(Configuration).to receive(:raw_file).with(file)
        HasConfiguration::Configuration.new(klass, file: file)
      end
    end
  end

  context "when initialized" do
    let(:environment) { nil }

    context "environment" do
      let(:fixture) { 'spec/fixtures/class.yml' }

      context "without env option" do
        subject(:hash) { HasConfiguration::Configuration.new(klass).to_h }

        it 'return the expected hash' do
          expect(hash).to eq('env' => 'test')
        end
      end

      context "with env option" do
        let(:environment) { 'production' }

        subject(:hash) { HasConfiguration::Configuration.new(klass, env: environment).to_h }

        it 'return the expected hash' do
          expect(hash).to eq('env' => environment)
        end
      end
    end

    context "yaml defaults" do
      let(:fixture) { 'spec/fixtures/with_defaults.yml' }

      subject(:hash) { HasConfiguration::Configuration.new(klass).to_h }

      it 'return the expected hash' do
        expect(hash).to eq('default' => 'default', 'env' => 'test')
      end
    end

    context "with erb" do
      let(:fixture) { 'spec/fixtures/with_erb.yml' }

      subject(:hash) { HasConfiguration::Configuration.new(klass).to_h }

      it 'return the expected hash' do
        expect(hash).to eq('erb' => Rails.env)
      end
    end
  end

  describe "#to_h" do
    let(:fixture) { 'spec/fixtures/with_nested_attributes.yml' }

    context "#to_h" do
      subject { HasConfiguration::Configuration.new(klass).to_h }
      it { should be_a(HashWithIndifferentAccess) }
    end

    context "#to_h(:stringify)" do
      subject { HasConfiguration::Configuration.new(klass).to_h(:stringify) }
      it { should eq('env' => 'test', 'nested' => { 'foo' => 'bar', 'baz' => true }) }
    end

    context "#to_h(:symbolized)" do
      subject { HasConfiguration::Configuration.new(klass).to_h(:symbolized) }
      it { should eq(env: 'test', nested: { foo: 'bar', baz: true }) }
    end
  end

  describe "struct methods" do
    let(:configuration) { HasConfiguration::Configuration.new(klass) }
    let(:fixture) { 'spec/fixtures/with_nested_attributes.yml' }

    it "is structified" do
      expect(configuration.to_h[:env]           ).to eql('test')
      expect(configuration.env                  ).to eql('test')

      expect(configuration.to_h[:nested]['foo'] ).to eql('bar')
      expect(configuration.nested.foo           ).to eql('bar')
    end
  end
end
