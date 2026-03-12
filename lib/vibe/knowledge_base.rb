# frozen_string_literal: true

require "yaml"

module Vibe
  # Structured knowledge base with YAML storage and multilingual support
  class KnowledgeBase
    attr_reader :data, :path

    def initialize(repo_root)
      @repo_root = repo_root
      @path = File.join(repo_root, "memory", "knowledge.yaml")
      @data = load_data
    end

    # Load YAML data from file
    def load_data
      return {} unless File.exist?(@path)

      YAML.safe_load(File.read(@path), aliases: true) || {}
    end

    # Search for lessons by keyword (supports English and Chinese)
    def search(query, lang: :en)
      query = query.downcase
      results = []

      # Search pitfalls
      @data.fetch("pitfalls", []).each do |pitfall|
        keywords = pitfall.dig("keywords", lang.to_s) || []
        if keywords.any? { |kw| query.include?(kw.downcase) || kw.downcase.include?(query) }
          results << { type: :pitfall, data: pitfall }
        end
      end

      # Search patterns
      @data.fetch("patterns", []).each do |pattern|
        name = pattern.dig("name", lang.to_s) || ""
        when_to_use = pattern.dig("when_to_use", lang.to_s) || ""
        if name.downcase.include?(query) || when_to_use.downcase.include?(query)
          results << { type: :pattern, data: pattern }
        end
      end

      results
    end

    # Get all pitfalls
    def pitfalls
      @data.fetch("pitfalls", [])
    end

    # Get all patterns
    def patterns
      @data.fetch("patterns", [])
    end

    # Get all ADRs
    def adrs
      @data.fetch("adrs", [])
    end

    # Get quick reference
    def quick_reference
      @data.fetch("quick_reference", {})
    end

    # Increment times_encountered for a pitfall
    def record_encounter(pitfall_id)
      pitfalls = @data["pitfalls"] || []
      pitfall = pitfalls.find { |p| p["id"] == pitfall_id }
      return unless pitfall

      pitfall["times_encountered"] ||= 0
      pitfall["times_encountered"] += 1
      save
    end

    # Export to markdown for backward compatibility
    def export_to_markdown(lang: :en)
      lines = ["# Project Knowledge\n", "> Structured knowledge base\n"]

      # Pitfalls section
      lines << "## Technical Pitfalls\n"
      pitfalls.each do |p|
        lines << "### #{p['id']}\n"
        lines << "**Issue**: #{p.dig('issue', lang.to_s)}\n"
        lines << "**Solution**: #{p.dig('solution', lang.to_s)}\n"
        lines << "**Encountered**: #{p['times_encountered'] || 0} times\n\n"
      end

      # Patterns section
      lines << "## Reusable Patterns\n"
      patterns.each do |p|
        lines << "### #{p.dig('name', lang.to_s)}\n"
        lines << "**When to use**: #{p.dig('when_to_use', lang.to_s)}\n"
        lines << "**Times used**: #{p['times_used'] || 0}\n\n"
      end

      # ADRs section
      lines << "## Architecture Decisions\n"
      adrs.each do |adr|
        lines << "### #{adr['id']}: #{adr['title']} (#{adr['date']})\n"
        lines << "- **Status**: #{adr['status']}\n"
        lines << "- **Context**: #{adr['context']}\n"
        lines << "- **Decision**: #{adr['decision']}\n\n"
      end

      lines.join("\n")
    end

    private

    def save
      File.write(@path, YAML.dump(@data))
    end
  end
end
