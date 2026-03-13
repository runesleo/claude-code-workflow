#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
load File.expand_path("../../bin/vibe", __dir__)

repo_root = File.expand_path("../..", __dir__)

puts "Benchmarking YAML loading operations..."
puts

n = 100

Benchmark.bmbm do |x|
  x.report("tiers_doc (first load):") do
    n.times do
      new_cli = VibeCLI.new(repo_root)
      new_cli.tiers_doc
    end
  end

  x.report("tiers_doc (cached):") do
    cli = VibeCLI.new(repo_root)
    cli.tiers_doc # Warm up
    n.times do
      cli.tiers_doc
    end
  end

  x.report("providers (first load):") do
    n.times do
      new_cli = VibeCLI.new(repo_root)
      new_cli.providers
    end
  end

  x.report("providers (cached):") do
    cli = VibeCLI.new(repo_root)
    cli.providers # Warm up
    n.times do
      cli.providers
    end
  end
end
