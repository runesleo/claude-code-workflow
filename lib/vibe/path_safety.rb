# frozen_string_literal: true

require_relative 'errors'

module Vibe
  # Output path safety guards, destination conflict checks, file tree
  # copying, and marker file management.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Depends on methods from:
  #   Vibe::Utils — write_json, display_path
  module PathSafety
    UNSAFE_OUTPUT_PATHS = ["/", "/tmp", "/var", "/etc", "/usr"].freeze
    # macOS temp directories under /var are safe
    SAFE_VAR_PREFIXES = ["/var/folders/"].freeze

    def ensure_safe_output_path!(output_root)
      expanded = normalize_path(output_root)
      home = File.expand_path(Dir.home)
      repo = File.expand_path(@repo_root)

      # Check if path is under a safe /var prefix (e.g., /var/folders/ on macOS)
      is_safe_var = SAFE_VAR_PREFIXES.any? { |prefix|
        normalized_prefix = normalize_path(prefix)
        expanded.start_with?(normalized_prefix)
      }

      UNSAFE_OUTPUT_PATHS.each do |unsafe|
        unsafe_expanded = normalize_path(unsafe)
        if expanded == unsafe_expanded || expanded.start_with?("#{unsafe_expanded}/")
          # Allow if it's under a safe /var prefix
          next if unsafe == "/var" && is_safe_var
          raise PathSafetyError, "Refusing to use #{expanded} as output root: overlaps with #{unsafe}"
        end
      end

      raise PathSafetyError, "Refusing to use #{expanded} as output root: overlaps with $HOME (#{home})" if expanded == home

      if expanded == repo || (expanded.start_with?("#{repo}/") && !expanded.start_with?("#{repo}/generated/"))
        raise PathSafetyError, "Refusing to use #{expanded} as output root: overlaps with source repo (#{repo}).\nUse a path under generated/ or an external directory."
      end

      if repo.start_with?("#{expanded}/")
        raise PathSafetyError, "Refusing to use #{expanded} as output root: source repo is inside it."
      end

      parts = expanded.split("/").reject(&:empty?)
      if parts.length < 2
        raise PathSafetyError, "Refusing to use #{expanded} as output root: path is too shallow (need at least 2 levels)."
      end
    end

    def ensure_no_path_overlap!(output_root, destination_root)
      out = File.expand_path(output_root)
      dest = File.expand_path(destination_root)

      if out == dest
        raise PathSafetyError, "Output root and destination root are the same path: #{out}\nUse separate directories."
      end
      if paths_overlap?(out, dest)
        raise PathSafetyError, "Output root (#{out}) and destination root (#{dest}) overlap.\nUse non-overlapping directories."
      end
    end

    def paths_overlap?(left, right)
      # Normalize each path independently to handle symlinks correctly
      left_root = normalize_path(left)
      right_root = normalize_path(right)

      left_root.start_with?("#{right_root}/") || right_root.start_with?("#{left_root}/")
    end

    private

    # Normalize a path by resolving symlinks in existing parent directories.
    # For /tmp/foo/bar where /tmp exists but foo/bar don't:
    # - Resolve /tmp to /private/tmp (on macOS)
    # - Append /foo/bar to get /private/tmp/foo/bar
    def normalize_path(path)
      # Expand path first to handle relative paths
      expanded = File.expand_path(path)

      # Try to resolve symlinks if path exists
      begin
        return File.realpath(expanded)
      rescue Errno::ENOENT
        # Path doesn't exist, try to resolve parent directories
        # This handles cases like: symlink -> real, comparing with real/nonexistent/child
        parent = File.dirname(expanded)
        basename = File.basename(expanded)

        # Recursively normalize parent if it's not root
        if parent != expanded && parent != "/"
          normalized_parent = normalize_path(parent)
          return File.join(normalized_parent, basename)
        end

        # Parent is root or same as current, return as-is
        return expanded
      end
    end

    def enforce_safe_destination!(staging_root, destination_root, force)
      return if force

      conflicts = staged_file_paths(staging_root).select do |relative_path|
        File.exist?(File.join(destination_root, relative_path))
      end

      return if conflicts.empty?

      sample = conflicts.first(5).map { |path| "  - #{path}" }.join("\n")
      raise PathSafetyError, <<~TEXT
        Destination already contains #{conflicts.length} generated path(s).
        Re-run with --force to overwrite them.

        Sample conflicts:
        #{sample}
      TEXT
    end

    def write_marker(path, destination_root:, manifest:, output_root:, mode:)
      write_json(
        path,
        {
          "schema_version" => 5,
          "mode" => mode,
          "source_repo" => ".",
          "destination_root" => display_path(destination_root),
          "generated_output" => display_path(File.expand_path(output_root)),
          "target" => manifest["target"],
          "profile" => manifest["profile"],
          "profile_mapping" => manifest["profile_mapping"],
          "overlay" => manifest["overlay"],
          "effective_policy_count" => manifest["policies"].length,
          "applied_at" => Time.now.utc.iso8601
        }
      )
    end

    def staged_file_paths(root, prefix = nil)
      entries = Dir.glob(File.join(root, "*"), File::FNM_DOTMATCH).reject do |path|
        [".", ".."].include?(File.basename(path))
      end

      entries.flat_map do |entry|
        relative = [prefix, File.basename(entry)].compact.join("/")

        if File.directory?(entry)
          staged_file_paths(entry, relative)
        else
          relative
        end
      end
    end

    def copy_tree_contents(source_root, destination_root)
      entries = Dir.glob(File.join(source_root, "*"), File::FNM_DOTMATCH).reject do |path|
        [".", ".."].include?(File.basename(path))
      end

      entries.each do |entry|
        destination = File.join(destination_root, File.basename(entry))

        if File.directory?(entry)
          FileUtils.mkdir_p(destination)
          copy_tree_contents(entry, destination)
        else
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.cp(entry, destination)
        end
      end
    end

  end
end
