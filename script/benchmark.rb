# frozen_string_literal: true

require "has_configuration"
require "tempfile"
require "objspace"
require "json"

def measure(samples)
  results = Array.new(samples) do
    GC.start
    allocated = GC.stat(:total_allocated_objects)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    [(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000,
      GC.stat(:total_allocated_objects) - allocated]
  end
  {median_ms: results.map(&:first).sort[samples / 2].round(3),
   median_allocations: results.map(&:last).sort[samples / 2]}
end

Tempfile.create(["has-configuration-benchmark", ".yml"]) do |file|
  values = 100.times.to_h { |group| ["group#{group}", 20.times.to_h { |key| ["key#{key}", "value#{key}"] }] }
  file.write(YAML.dump(values))
  file.flush
  create = -> { HasConfiguration::Configuration.new(Class, file: file.path, env: nil) }
  create.call.group0.key0
  result = {ruby: RUBY_VERSION, yaml_bytes: file.size, groups: 100, leaves: 2000, samples: 15}
  result[:load] = measure(15) { create.call }
  config = create.call
  snapshot = config.to_h
  result[:dot_100k] = measure(15) { 100_000.times { config.group0.key0 } }
  result[:local_hash_100k] = measure(15) { 100_000.times { snapshot["group0"]["key0"] } }
  result[:exports_100] = measure(15) { 100.times { config.to_h } }
  result[:symbolized_exports_100] = measure(15) { 100.times { config.to_h(:symbolized) } }
  retained = Array.new(5) do
    config = nil
    GC.start
    before = ObjectSpace.memsize_of_all
    config = create.call
    GC.start
    ObjectSpace.memsize_of_all - before
  end
  result[:approximate_retained_heap_bytes] = retained.sort[2]
  puts JSON.pretty_generate(result)
end
