.PHONY: all validate generate inspect clean test schema

# List of supported targets for generation
TARGETS = claude-code codex-cli cursor kimi-code opencode vscode warp antigravity

all: validate generate

validate:
	@echo "🔍 Running validation pipeline..."
	@ruby -ryaml -e "Dir.glob('core/**/*.yaml').each { |f| begin; YAML.load_file(f); rescue => e; puts \"Invalid YAML: #{f}\"; exit 1; end }"
	@echo "✅ Core YAML files are well-formed."
	@bin/vibe inspect --json > /dev/null && echo "✅ Vibe inspect succeeded." || (echo "❌ Vibe inspect failed." && exit 1)
	@echo "✅ Validation complete."

schema:
	@echo "🔍 Validating YAML files against JSON Schema..."
	@bin/validate-schemas

generate:
	@echo "🚀 Generating target Markdown from core specs..."
	@for target in $(TARGETS); do \
		bin/vibe build $$target --output generated/$$target || exit 1; \
	done
	@echo "✅ Generation complete."

inspect:
	@bin/vibe inspect

clean:
	@rm -rf generated/
	@echo "🧹 Cleaned generated directory."

test:
	@echo "🧪 Running unit tests..."
	@ruby -Ilib:test -e "Dir.glob('test/test_*.rb').each { |f| require File.expand_path(f) }"

verify-snapshot:
	@echo "🔍 Verifying snapshot consistency..."
	@ruby -Ilib:test test/test_vibe_cli.rb --name test_checked_in_runtimes_match_renderer
