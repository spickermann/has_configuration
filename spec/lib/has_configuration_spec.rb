RSpec.describe HasConfiguration do
  context 'when declared' do
    Dummy = Class.new do
      require 'has_configuration'
      has_configuration file: 'spec/fixtures/class.yml'
    end

    context 'with a class' do
      subject(:dummy) { Dummy }

      it { is_expected.to respond_to(:configuration) }

      it 'returns a configuration' do
        expect(dummy.configuration).to be
      end
    end

    context 'with an instance' do
      subject(:dummy) { Dummy.new }

      it { is_expected.to respond_to(:configuration) }

      it 'returns a configuration' do
        expect(dummy.configuration).to be
      end
    end
  end
end
