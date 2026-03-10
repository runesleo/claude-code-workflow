# frozen_string_literal: true

module Vibe
  # Base error class for all Vibe-specific errors.
  # Provides a foundation for structured error handling throughout the application.
  # Supports context for better debugging and error reporting.
  class Error < StandardError
    attr_reader :context

    def initialize(message, context: {})
      @context = context
      super(message)
    end

    def to_s
      return super if context.empty?
      "#{super} [Context: #{context.inspect}]"
    end
  end

  # Raised when path safety checks fail.
  # Examples: unsafe output paths, path overlaps, invalid path structures.
  class PathSafetyError < Error; end

  # Raised when security policy violations are detected.
  # Examples: command injection attempts, unauthorized operations.
  class SecurityError < Error; end

  # Raised when input validation fails.
  # Examples: invalid YAML schema, malformed user input, out-of-range values.
  class ValidationError < Error
    attr_reader :field, :value

    def initialize(message, field: nil, value: nil, context: {})
      @field = field
      @value = value
      merged_context = context.dup
      merged_context[:field] = field if field
      merged_context[:value] = value if value
      super(message, context: merged_context)
    end

    def to_s
      msg = super
      return msg if field.nil? && value.nil?
      parts = []
      parts << "field=#{field}" if field
      parts << "value=#{value.inspect}" if value
      "#{msg} (#{parts.join(', ')})"
    end
  end

  # Raised when configuration is invalid or missing.
  # Examples: missing required YAML files, invalid target names.
  class ConfigurationError < Error; end

  # Raised when external tool operations fail.
  # Examples: tool not found, installation failed, verification failed.
  class ExternalToolError < Error; end
end
