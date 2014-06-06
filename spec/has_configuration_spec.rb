require 'spec_helper'

describe HasConfiguration do

  context "when declared" do

    before(:all) do
      Dummy = Class.new do
        has_configuration :file => 'spec/fixtures/class.yml'
      end
    end

    context "the class" do
      subject(:dummy) { Dummy }

      it { should respond_to(:configuration) }

      it 'returns a configuration' do
        expect(dummy.configuration).to be
      end
    end

    context "an instance" do
      subject(:dummy) { Dummy.new }

      it { should respond_to(:configuration) }

      it 'returns a configuration' do
        expect(dummy.configuration).to be
      end
    end

  end

end
