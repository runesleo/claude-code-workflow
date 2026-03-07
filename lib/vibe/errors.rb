# frozen_string_literal: true

module Vibe
  # Base error class for all Vibe-specific errors.
  # Provides a foundation for structured error handling throughout the application.
  class Error < StandardError; end

  # Raised when path safety checks fail.
  # Examples: unsafe output paths, path overlaps, invalid path structures.
  class PathSafetyError < Error; end

  # Raised when security policy violations are detected.
  # Examples: command injection attempts, unauthorized operations.
  class SecurityError < Error; end

  # Raised when input validation fails.
  # Examples: invalid YAML schema, malformed user input, out-of-range values.
  class ValidationError < Error; end

  # Raised when configuration is invalid or missing.
  # Examples: missing required YAML files, invalid target names.
  class ConfigurationError < Error; end

  # Raised when external tool operations fail.
  # Examples: tool not found, installation failed, verification failed.
  class ExternalToolError < Error; end
end
