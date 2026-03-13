# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/test_*.rb", "test/**/test_*.rb"]
  t.verbose = true
end

Rake::TestTask.new(:test_single) do |t|
  t.libs << "test" << "lib"
  t.verbose = true
end

desc "Run all validation checks"
task :validate do
  require "yaml"

  puts "🔍 Running validation pipeline..."

  # 1. Validate YAML files
  Dir.glob("core/**/*.yaml").each do |f|
    begin
      YAML.safe_load(File.read(f), aliases: true)
      puts "✓ #{f}"
    rescue => e
      abort "✗ #{f}: #{e.message}"
    end
  end
  puts "✅ Core YAML files are well-formed."

  # 2. Vibe inspect
  unless system("bin/vibe inspect --json > /dev/null")
    abort "❌ Vibe inspect failed."
  end
  puts "✅ Vibe inspect succeeded."

  # 3. Skill entrypoint paths
  puts "🔍 Checking skill entrypoint paths..."
  registry = YAML.safe_load(File.read("core/skills/registry.yaml"), aliases: true)
  registry["skills"].select { |s| s["builtin"] }.each do |s|
    path = s["entrypoint"]
    abort "Missing entrypoint: #{path}" unless File.exist?(path)
  end
  puts "✅ All builtin skill entrypoints exist."

  # 4. Document cross-references
  puts "🔍 Checking document cross-references..."
  behaviors_path = "rules/behaviors.md"
  if File.exist?(behaviors_path)
    content = File.read(behaviors_path)
    refs = content.scan(/Read (docs\/[^\s)]+)/)
    refs.each do |ref|
      path = ref[0]
      abort "Missing doc: #{path}" unless File.exist?(path)
    end
  end
  puts "✅ All doc references exist."

  puts "✅ Validation complete."
end

desc "Run tests with coverage"
task :coverage => :test do
  puts "📊 Coverage report generated"
end

desc "Clean generated files"
task :clean do
  rm_rf "generated"
  rm_rf "coverage"
  puts "🧹 Cleaned generated files"
end

desc "Build all supported targets"
task :build do
  targets = %w[claude-code opencode]
  targets.each do |target|
    puts "Building #{target}..."
    system("ruby", "-Ilib", "bin/vibe", "build", target, "--output", "generated/#{target}")
  end
end

task default: :test
