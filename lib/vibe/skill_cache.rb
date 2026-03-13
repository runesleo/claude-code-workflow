# frozen_string_literal: true

require 'singleton'

module Vibe
  # Cache for skill-related data to improve performance
  # Uses Singleton pattern for global cache instance
  #
  # Usage:
  #   cache = SkillCache.instance
  #   cache.fetch_registry { load_registry_from_disk }
  #   cache.fetch_skill('id') { load_skill_from_disk }
  #
  class SkillCache
    include Singleton

    DEFAULT_TTL = 300 # 5 minutes

    def initialize
      @cache = {}
      @timestamps = {}
      @mutex = Mutex.new
    end

    # Fetch data from cache or execute block to load
    #
    # @param key [String] Cache key
    # @param ttl [Integer] Time to live in seconds
    # @yield Block to execute if cache miss
    # @return Cached or freshly loaded data
    def fetch(key, ttl = DEFAULT_TTL)
      @mutex.synchronize do
        if valid?(key, ttl)
          return @cache[key]
        end

        data = yield
        @cache[key] = data
        @timestamps[key] = Time.now
        data
      end
    end

    # Get cached value without loading
    #
    # @param key [String] Cache key
    # @return [Object, nil] Cached value or nil
    def get(key)
      @mutex.synchronize do
        @cache[key]
      end
    end

    # Store value in cache
    #
    # @param key [String] Cache key
    # @param value [Object] Value to cache
    def set(key, value)
      @mutex.synchronize do
        @cache[key] = value
        @timestamps[key] = Time.now
      end
    end

    # Invalidate specific cache entry
    #
    # @param key [String] Cache key to invalidate
    def invalidate(key)
      @mutex.synchronize do
        @cache.delete(key)
        @timestamps.delete(key)
      end
    end

    # Invalidate all cache entries matching pattern
    #
    # @param pattern [Regexp] Pattern to match keys
    def invalidate_pattern(pattern)
      @mutex.synchronize do
        @cache.keys.select { |k| k.match?(pattern) }.each do |key|
          @cache.delete(key)
          @timestamps.delete(key)
        end
      end
    end

    # Clear entire cache
    def clear
      @mutex.synchronize do
        @cache.clear
        @timestamps.clear
      end
    end

    # Check if cache entry is valid (not expired)
    #
    # @param key [String] Cache key
    # @param ttl [Integer] Time to live in seconds
    # @return [Boolean] True if valid
    def valid?(key, ttl = DEFAULT_TTL)
      return false unless @cache.key?(key)
      return false unless @timestamps.key?(key)

      age = Time.now - @timestamps[key]
      age < ttl
    end

    # Get cache statistics
    #
    # @return [Hash] Cache stats
    def stats
      @mutex.synchronize do
        {
          size: @cache.size,
          keys: @cache.keys,
          oldest_entry: @timestamps.values.min,
          newest_entry: @timestamps.values.max
        }
      end
    end

    # Preload registry into cache
    #
    # @param repo_root [String] Repository root path
    def preload_registry(repo_root)
      registry_path = File.join(repo_root, "core/skills/registry.yaml")
      return unless File.exist?(registry_path)

      doc = YAML.safe_load(File.read(registry_path), aliases: true)
      return unless doc && doc['skills']

      skills = doc['skills'].map do |skill|
        {
          id: skill['id'],
          namespace: skill['namespace'],
          name: skill['id'].split('/').last,
          intent: skill['intent'],
          description: skill['description'],
          trigger_mode: skill['trigger_mode'],
          priority: skill['priority'],
          requires_tools: skill['requires_tools'] || [],
          supported_targets: skill['supported_targets'] || {},
          entrypoint: skill['entrypoint'],
          safety_level: skill['safety_level']
        }
      end

      set('registry_skills', skills)
      set('registry_loaded_at', Time.now)
    end

    # Get cached registry or load if not cached
    #
    # @param repo_root [String] Repository root path
    # @return [Array<Hash>] Skills from registry
    def get_registry(repo_root)
      fetch('registry_skills') do
        preload_registry(repo_root)
        get('registry_skills') || []
      end
    end

    # Get cached project config or load if not cached
    #
    # @param project_root [String] Project root path
    # @return [Hash] Project skill configuration
    def get_project_config(project_root)
      cache_key = "project_config:#{project_root}"

      fetch(cache_key, 60) do # 1 minute TTL for project config
        config_path = File.join(project_root, ".vibe/skills.yaml")

        if File.exist?(config_path)
          YAML.safe_load(File.read(config_path), aliases: true) || {}
        else
          {
            'schema_version' => 1,
            'adapted_skills' => {},
            'skipped_skills' => [],
            'installed_packs' => {}
          }
        end
      end
    end

    # Invalidate project config cache
    #
    # @param project_root [String] Project root path
    def invalidate_project_config(project_root)
      invalidate_pattern(/project_config:#{Regexp.escape(project_root)}/)
    end
  end
end
