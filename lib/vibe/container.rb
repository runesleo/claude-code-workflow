# frozen_string_literal: true

require_relative "utils"
require_relative "errors"
require_relative "doc_rendering"
require_relative "native_configs"
require_relative "overlay_support"
require_relative "path_safety"
require_relative "target_renderers"
require_relative "external_tools"
require_relative "init_support"

module Vibe
  # Simple dependency injection container for Vibe components.
  #
  # PURPOSE:
  #   This container provides a foundation for future testability improvements.
  #   Currently used minimally in VibeCLI for initialization, but can be
  #   expanded for:
  #   - Testing: Inject mock services (e.g., mock YAML loader)
  #   - Configuration: Allow runtime service registration
  #   - Modularity: Enable service replacement in different environments
  #
  # USAGE EXAMPLE (future):
  #   # In tests
  #   container = Vibe::Container.new(repo_root)
  #   container.register(:yaml_loader, mock_yaml_loader)
  #   cli = VibeCLI.new(repo_root, container: container)
  #
  # STATUS: OPTIONAL FEATURE (YAGNI consideration)
  #   This is infrastructure for future improvements. If you don't need DI capabilities,
  #   you can safely ignore this class. It adds minimal overhead (~43 lines)
  #   and no runtime cost unless used.
  #
  # TRADE-OFFS:
  #   - PRO: Adds flexibility for testing and configuration
  #   - CON: Not currently used extensively (could be considered over-engineering)
  #   - ALTERNATIVE: Remove this class if DI is not needed
  #
  #
  class Container
    attr_reader :repo_root

    def initialize(repo_root)
      @repo_root = repo_root
      @services = {}
      @yaml_mutex = Mutex.new
    end

    def utils
      @services[:utils] ||= Utils
    end

    def yaml_loader
      @services[:yaml_loader] ||= ->(path) { YAML.load_file(File.join(@repo_root, path)) }
    end

    def register(name, service)
      @services[name] = service
    end

    def resolve(name)
      @services[name] || raise(ConfigurationError, "Service #{name} not registered")
    end

    def registered?(name)
      @services.key?(name)
    end
  end
end
