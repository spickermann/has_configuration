# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'standard/rake'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

task default: %i[spec standard]
