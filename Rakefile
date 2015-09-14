require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end
RuboCop::RakeTask.new(:rubocop)

task default: [:spec, :rubocop]
