#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
load File.expand_path("../../bin/vibe", __dir__)

repo_root = File.expand_path("../..", __dir__)
cli = VibeCLI.new(repo_root)

n = 10_000

puts "Benchmarking deep_merge and deep_copy operations..."
puts

Benchmark.bmbm do |x|
  x.report("deep_merge (hashes):") do
    n.times do
      cli.send(:deep_merge, { a: 1, b: { c: 2 } }, { b: { d: 3 }, e: 4 })
    end
  end

  x.report("deep_merge (arrays):") do
    n.times do
      cli.send(:deep_merge, [1, 2, 3], [4, 5, 6])
    end
  end

  x.report("deep_merge (mixed):") do
    n.times do
      cli.send(:deep_merge, { a: [1, 2], b: { c: 3 } }, { a: [3, 4], d: 5 })
    end
  end

  x.report("deep_copy (simple hash):") do
    n.times do
      cli.send(:deep_copy, { a: 1, b: 2, c: 3 })
    end
  end

  x.report("deep_copy (nested):") do
    n.times do
      cli.send(:deep_copy, { a: { b: { c: { d: 4 } } }, e: [1, 2, 3] })
    end
  end

  x.report("deep_copy (array):") do
    n.times do
      cli.send(:deep_copy, [1, 2, [3, 4], { a: 1 }])
    end
  end
end
