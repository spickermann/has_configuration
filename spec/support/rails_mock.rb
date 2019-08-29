# frozen_string_literal: true

# Mocks Rails Environment
Rails = Class.new do
  def self.root
    Pathname.new('/RAILS_ROOT')
  end

  def self.env
    'test'
  end
end
