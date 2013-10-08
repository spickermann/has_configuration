require 'spec_helper'

describe HasConfiguration do

  context "when declared" do

    before(:all) do
      Dummy = Class.new do
        has_configuration
      end
    end

    before { mock_file('spec/fixtures/class.yml') }

    context "the class" do
      subject { Dummy }
      it { should respond_to(:configuration) }
      its(:configuration) { should be }
    end

    context "an instance" do
      subject { Dummy.new }
      it { should respond_to(:configuration) }
      its(:configuration) { should be }
    end

  end

end
