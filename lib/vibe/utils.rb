# frozen_string_literal: true

require "tmpdir"
require_relative "errors"

module Vibe
  # Generic utilities shared across all Vibe modules.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #                          (used by display_path)
  module Utils
    # Deep merge two nested data structures.
    #
    # DESIGN DECISION: LENIENT MODE (宽容模式)
    # 
    # Why lenient mode?
    # 1. Graceful degradation: Instead of failing on type errors, return extra
    # 2. Backward compatibility: Existing code that depends on flexible merging continues to work
    # 3. Simplicity: No need for complex type checking at merge time
    # 4. Predictability: The behavior is consistent and easy to reason about
    #
    # Trade-offs:
    # - Less strict: Could miss type errors that would only show up in logs
    # - Requires understanding: Developers need to understand that non-matching types are replaced
    #
    # Examples:
    #   deep_merge({a: 1, b: {c: 2}}, {b: {d: 3}, e: 4})
    #   # => {a: 1, b: {c: 2, d: 3}, e: 4}
    #   
    #   deep_merge([1, 2, 3], [3, 4, 5])
    #   # => [1, 2, 3, 4, 5] (uniq)
    #   
    #   deep_merge({a: 1}, "invalid")
    #   # => "invalid" (string is replaced)
    #
    # For strict validation mode, use ValidationError:
    #   def validate_mergeable!(value, name)
    #   return if value.nil? || value.is_a?(Hash) || value.is_a?(Array)
    #   raise ValidationError, "#{name} must be a Hash, Array, or nil, got #{value.class}"
    #   end
    #
    # Alternative approach (if you need strict mode)
    # Use deep_merge(base, extra) and rescue if needed
    # end

    def deep_merge(base, extra)
      return deep_copy(extra) if base.nil?
      return deep_copy(base) if extra.nil?

      if base.is_a?(Hash) && extra.is_a?(Hash)
        merged = deep_copy(base)
        extra.each do |key, value|
          merged[key] = merged.key?(key) ? deep_merge(merged[key], value) : deep_copy(value)
        end
        merged
      elsif base.is_a?(Array) && extra.is_a?(Array)
        (base + extra).uniq
      else
        deep_copy(extra)
      end
    end

    def deep_copy(value)
      return value if value.nil? || value == true || value == false || value.is_a?(Numeric) || value.is_a?(Symbol)

      case value
      when String
        value.dup
      when Array
        value.map { |item| deep_copy(item) }
      when Hash
        value.transform_keys { |k| deep_copy(k) }.transform_values { |v| deep_copy(v) }
      else
        # Fallback to Marshal for other types (preserves type information)
        Marshal.load(Marshal.dump(value))
      end
    end

    def blankish?(value)
      value.nil? || value.to_s.strip.empty?
    end

    # --- Path helpers ---

    # Returns a display-friendly path: relative to @repo_root when possible,
    # otherwise the absolute path.
    def display_path(path)
      absolute = File.expand_path(path)
      repo_prefix = @repo_root.end_with?("/") ? @repo_root : "#{@repo_root}/"
      return "." if absolute == @repo_root
      return absolute.delete_prefix(repo_prefix) if absolute.start_with?(repo_prefix)

      absolute
    end

    # --- I/O helpers ---

    def read_yaml(relative_path)
      read_yaml_abs(File.join(@repo_root, relative_path))
    end

    def read_yaml_abs(path)
      YAML.safe_load(File.read(path), aliases: true)
    end

    def read_json(path)
      JSON.parse(File.read(path))
    end

    def read_json_if_exists(path)
      return nil unless File.exist?(path)

      read_json(path)
    end

    def write_json(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(content) + "\n")
    end

    # --- Formatting helpers ---

    def format_backtick_list(items)
      values = Array(items).map(&:to_s).reject { |item| item.strip.empty? }
      return "`none`" if values.empty?

      values.map { |item| "`#{item}`" }.join(", ")
    end

    # --- Input validation and sanitization ---

    # Maximum path length to prevent DoS attacks
    MAX_PATH_LENGTH = 4096

    # Validate and sanitize a file path input
    # Raises ValidationError if path contains dangerous characters or unsafe traversal
    def validate_path!(path, context: "path")
      raise ValidationError, "#{context} cannot be nil" if path.nil?
      raise ValidationError, "#{context} cannot be empty" if path.to_s.strip.empty?

      path_str = path.to_s
      raise ValidationError, "#{context} exceeds maximum length (#{MAX_PATH_LENGTH})" if path_str.length > MAX_PATH_LENGTH
      raise ValidationError, "#{context} contains null byte" if path_str.include?("\0")
      raise ValidationError, "#{context} contains control characters" if path_str.match?(/[\x00-\x1f\x7f]/)

      # Path traversal protection: prevent escaping from safe directories
      if path_str.include?("..")
        expanded = File.expand_path(path_str)
        # Allow paths within: repo root, current directory, or system temp directory
        allowed_roots = [@repo_root, Dir.pwd, Dir.tmpdir].map { |root| File.expand_path(root) }
        safe = allowed_roots.any? { |root| expanded.start_with?(root) }

        unless safe
          raise ValidationError, "#{context} contains unsafe path traversal: #{path_str}"
        end
      end

      path_str
    end

    # Validate that a value is in an allowed set
    def validate_choice!(value, allowed_values, context: "value")
      raise ValidationError, "#{context} must be one of: #{allowed_values.join(', ')}" unless allowed_values.include?(value)
      value
    end

    # Sanitize a command argument by removing dangerous characters
    def sanitize_command_arg(arg)
      return nil if arg.nil?
      # Remove null bytes and control characters
      arg.to_s.gsub(/[\x00-\x1f\x7f]/, "")
    end
  end
end
