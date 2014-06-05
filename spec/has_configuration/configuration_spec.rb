require 'spec_helper'

describe HasConfiguration::Configuration do

  let(:klass) { Class }

  describe ".new" do

    before { mock_file('spec/fixtures/class.yml') }

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
        HasConfiguration::Configuration.new(klass, :file => file)
      end

    end

  end

  context "when initialized" do
    let(:environment) { nil }

    context "environment" do

      before { mock_file('spec/fixtures/class.yml') }

      context "without env option" do
        subject(:hash) { HasConfiguration::Configuration.new(klass).to_h }

        it 'return the expected hash' do
          expect(hash).to eq('env' => 'development')
        end
      end

      context "with env option" do
        subject(:hash) { HasConfiguration::Configuration.new(klass, :env => environment).to_h }

        let(:environment) { 'production' }

        it 'return the expected hash' do
          expect(hash).to eq('env' => environment)
        end
      end

    end

    context "yaml defaults" do
      subject(:hash) { HasConfiguration::Configuration.new(klass).to_h }

      before { mock_file('spec/fixtures/with_defaults.yml') }

      it 'return the expected hash' do
        expect(hash).to eq('default' => 'default', 'development' => 'development')
      end
    end

    context "with erb" do
      subject(:hash) { HasConfiguration::Configuration.new(klass).to_h }

      before { mock_file('spec/fixtures/with_erb.yml') }

      it 'return the expected hash' do
        expect(hash).to eq('erb' => Rails.env)
      end
    end

  end

  describe "#to_h" do

    before { mock_file('spec/fixtures/with_nested_attributes.yml') }

    context "#to_h" do
      subject { HasConfiguration::Configuration.new(klass).to_h }
      it { should be_a(HashWithIndifferentAccess) }
    end

    context "#to_h(:stringify)" do
      subject { HasConfiguration::Configuration.new(klass).to_h(:stringify) }
      it { should eq('development' => 'development', 'nested' => { 'foo' => 'bar', 'baz' => true }) }
    end

    context "#to_h(:symbolized)" do
      subject { HasConfiguration::Configuration.new(klass).to_h(:symbolized) }
      it { should eq(:development => 'development', :nested => { :foo => 'bar', :baz => true }) }
    end

  end

  describe "struct methods" do

    before { mock_file('spec/fixtures/with_nested_attributes.yml') }

    let(:configuration) { HasConfiguration::Configuration.new(klass) }

    it "is structified" do
      expect(configuration.to_h[:development]   ).to eql('development')
      expect(configuration.development          ).to eql('development')

      expect(configuration.to_h[:nested]['foo'] ).to eql('bar')
      expect(configuration.nested.foo           ).to eql('bar')
    end

  end

end
