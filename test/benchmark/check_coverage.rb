#!/usr/bin/env ruby
# frozen_string_literal: true

#
# SimpleCov Coverage Threshold Checker
# Uses Ruby instead of bc for better cross-platform compatibility
# This ensures the script works on all CI platforms
#
# Usage:
#   COVERAGE_THRESHOLD: environment variable, default 60
#   COVERAGE_FILE: path to SimpleCov result file, defaults to coverage/.last_run.json
#
# Example:
#   COVERAGE_THRESHOLD=80 ruby test/benchmark/check_coverage.rb
#
# Exit codes:
#   0 - Coverage meets or exceeds threshold
#   1 - Coverage below threshold (exits with error)
#   2 - Coverage file not found (exits with error)

require 'json'

coverage_file = ENV['COVERAGE_FILE'] || 'coverage/.last_run.json'
threshold = (ENV['COVERAGE_THRESHOLD'] || 60).to_f

unless File.exist?(coverage_file)
  puts "ERROR: Coverage file not found at #{coverage_file}"
  puts "Please ensure SimpleCov is configured correctly in test/test_helper.rb"
  exit 2
end

begin
  result = JSON.parse(File.read(coverage_file))
  # SimpleCov format: result['result']['line'] or result['result']['covered_percent']
  covered_percent = result['result']['line'] || result['result']['covered_percent']

  unless covered_percent.is_a?(Numeric)
    puts "ERROR: Coverage data is not numeric"
    puts "Available keys: #{result['result'].keys.inspect}"
    exit 1
  end
rescue JSON::ParserError => e
  puts "ERROR: Failed to parse #{coverage_file}: #{e.message}"
  exit 1
end

puts "Coverage: #{covered_percent}%"

if covered_percent < threshold
  puts "ERROR: Coverage #{covered_percent}% is below threshold #{threshold}%"
  puts "Current coverage: #{covered_percent}%"
  exit 1
else
  puts "✅ Coverage #{covered_percent}% meets threshold #{threshold}%"
  exit 0
end
