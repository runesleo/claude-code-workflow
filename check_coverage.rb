#!/usr/bin/env ruby
require 'json'

json = JSON.parse(File.read("coverage/.resultset.json"))
coverage = json["Unit Tests"]["coverage"]

results = coverage.map do |file, data|
  lines = data["lines"]
  covered = lines.count { |l| l && l > 0 }
  total = lines.count { |l| !l.nil? }
  pct = total > 0 ? (covered.to_f / total * 100).round(1) : 0
  [file, pct, covered, total]
end.sort_by { |_, pct, _, _| pct }

puts "=== Coverage Report ==="
puts ""

results.each do |file, pct, covered, total|
  status = pct >= 75 ? "✅" : pct >= 50 ? "⚠️" : "❌"
  filename = file.split("/").last(2).join("/")
  puts "#{status} #{pct.to_s.rjust(5)}% (#{covered.to_s.rjust(3)}/#{total.to_s.rjust(3)}): #{filename}"
end

puts ""
puts "=== Summary ==="
avg = results.map { |_, pct, _, _| pct }.sum / results.length
puts "Average: #{avg.round(1)}%"

below_75 = results.count { |_, pct, _, _| pct < 75 }
below_50 = results.count { |_, pct, _, _| pct < 50 }
puts "Files below 75%: #{below_75}/#{results.length}"
puts "Files below 50%: #{below_50}/#{results.length}"
