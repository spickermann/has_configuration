# frozen_string_literal: true

require 'has_configuration'

require 'support/rails_mock'

RSpec.describe HasConfiguration::Configuration do
  let(:klass) { Class }

  before do
    allow_any_instance_of(
      Configuration
    ).to receive(:raw_file).and_return(File.read(fixture))
  end

  describe '.new' do
    let(:fixture) { 'spec/fixtures/class.yml' }

    context 'when no filename provided' do
      let(:file) { '/RAILS_ROOT/config/class.yml' }

      it 'loads default file' do
        configuration = described_class.new(klass)
        expect(configuration).to have_received(:raw_file).with(file)
      end
    end

    context 'when filename provided' do
      let(:file) { 'foo/bar.yml' }

      it 'loads provided file' do
        configuration = described_class.new(klass, file: file)
        expect(configuration).to have_received(:raw_file).with(file)
      end
    end
  end

  context 'when initialized' do
    let(:environment) { nil }

    context 'without env option' do
      subject(:hash) { described_class.new(klass).to_h }

      let(:fixture) { 'spec/fixtures/class.yml' }

      it 'return the expected hash' do
        expect(hash).to eq('env' => 'test')
      end
    end

    context 'with env option' do
      subject(:hash) { described_class.new(klass, env: environment).to_h }

      let(:environment) { 'production' }
      let(:fixture) { 'spec/fixtures/class.yml' }

      it 'return the expected hash' do
        expect(hash).to eq('env' => environment)
      end
    end

    context 'with yaml defaults' do
      subject(:hash) { described_class.new(klass).to_h }

      let(:fixture) { 'spec/fixtures/with_defaults.yml' }

      it 'return the expected hash' do
        expect(hash).to eq('default' => 'default', 'env' => 'test')
      end
    end

    context 'with erb' do
      subject(:hash) { described_class.new(klass).to_h }

      let(:fixture) { 'spec/fixtures/with_erb.yml' }

      it 'return the expected hash' do
        expect(hash).to eq('erb' => Rails.env)
      end
    end
  end

  describe '#to_h' do
    let(:fixture) { 'spec/fixtures/with_nested_attributes.yml' }

    context 'without arguments' do
      subject { described_class.new(klass).to_h }

      it { is_expected.to be_a(HashWithIndifferentAccess) }
    end

    context 'with :stringify' do
      subject { described_class.new(klass).to_h(:stringify) }

      it { is_expected.to eq('env' => 'test', 'nested' => { 'foo' => 'bar', 'baz' => true }) }
    end

    context 'with :symbolized' do
      subject { described_class.new(klass).to_h(:symbolized) }

      it { is_expected.to eq(env: 'test', nested: { foo: 'bar', baz: true }) }
    end
  end

  describe 'struct methods' do
    let(:configuration) { described_class.new(klass) }
    let(:fixture) { 'spec/fixtures/with_nested_attributes.yml' }

    it 'supports multiple getter variants' do
      expect(configuration.to_h[:env]).to eql('test')
      expect(configuration.env).to eql('test')

      expect(configuration.to_h[:nested]['foo']).to eql('bar')
      expect(configuration.nested.foo).to eql('bar')
    end
  end
end
