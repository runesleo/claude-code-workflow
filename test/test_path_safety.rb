# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "tmpdir"
require_relative "../lib/vibe/path_safety"

class TestPathSafety < Minitest::Test
  include Vibe::PathSafety

  def test_paths_overlap_with_parent_child
    Dir.mktmpdir do |tmp|
      parent = File.join(tmp, "parent")
      child = File.join(parent, "child")
      FileUtils.mkdir_p(child)

      assert paths_overlap?(parent, child)
      assert paths_overlap?(child, parent)
    end
  end

  def test_paths_overlap_with_siblings
    Dir.mktmpdir do |tmp|
      sibling1 = File.join(tmp, "sibling1")
      sibling2 = File.join(tmp, "sibling2")
      FileUtils.mkdir_p(sibling1)
      FileUtils.mkdir_p(sibling2)

      refute paths_overlap?(sibling1, sibling2)
    end
  end

  def test_paths_overlap_with_symlinks
    Dir.mktmpdir do |tmp|
      real_parent = File.join(tmp, "real_parent")
      real_child = File.join(real_parent, "child")
      link_to_parent = File.join(tmp, "link_to_parent")

      FileUtils.mkdir_p(real_child)
      File.symlink(real_parent, link_to_parent)

      # Symlink to parent and real child should be detected as overlapping
      assert paths_overlap?(link_to_parent, real_child)
      assert paths_overlap?(real_child, link_to_parent)

      # Child accessed through symlink should overlap with real parent
      child_via_link = File.join(link_to_parent, "child")
      assert paths_overlap?(child_via_link, real_parent)
    end
  end

  def test_paths_overlap_symlink_with_nonexistent_descendant
    # This is the critical edge case GPT identified:
    # One side is an existing symlink, other side is a nonexistent descendant
    # of the real path
    Dir.mktmpdir do |tmp|
      real_dir = File.join(tmp, "real")
      link_dir = File.join(tmp, "link")
      nonexistent_child = File.join(real_dir, "child", "grandchild")

      FileUtils.mkdir_p(real_dir)
      File.symlink(real_dir, link_dir)

      # link -> real, comparing with real/child/grandchild (doesn't exist yet)
      # Should detect overlap because link resolves to real
      assert paths_overlap?(link_dir, nonexistent_child),
        "Failed to detect overlap: symlink (#{link_dir}) vs nonexistent descendant (#{nonexistent_child})"

      # Reverse direction should also work
      assert paths_overlap?(nonexistent_child, link_dir),
        "Failed to detect overlap: nonexistent descendant (#{nonexistent_child}) vs symlink (#{link_dir})"
    end
  end

  def test_paths_overlap_with_nonexistent_paths
    Dir.mktmpdir do |tmp|
      nonexistent1 = File.join(tmp, "nonexistent1")
      nonexistent2 = File.join(nonexistent1, "child")

      # Should fall back to string comparison for nonexistent paths
      assert paths_overlap?(nonexistent1, nonexistent2)
    end
  end

  def test_paths_overlap_with_same_path
    Dir.mktmpdir do |tmp|
      path = File.join(tmp, "same")
      FileUtils.mkdir_p(path)

      # Same path should not be considered overlapping (they're equal, not nested)
      refute paths_overlap?(path, path)
    end
  end

  def test_paths_overlap_with_relative_paths
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        parent = "parent"
        child = "parent/child"
        FileUtils.mkdir_p(child)

        assert paths_overlap?(parent, child)
      end
    end
  end

  def test_paths_overlap_with_trailing_slashes
    Dir.mktmpdir do |tmp|
      parent = File.join(tmp, "parent")
      child = File.join(parent, "child")
      FileUtils.mkdir_p(child)

      assert paths_overlap?("#{parent}/", child)
      assert paths_overlap?(parent, "#{child}/")
    end
  end

  def test_paths_overlap_with_dot_segments
    Dir.mktmpdir do |tmp|
      parent = File.join(tmp, "parent")
      child = File.join(parent, "child")
      FileUtils.mkdir_p(child)

      # Paths with . and .. should be normalized
      assert paths_overlap?(File.join(parent, "."), child)
      assert paths_overlap?(File.join(child, ".."), child)
    end
  end
end
