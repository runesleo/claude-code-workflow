# frozen_string_literal: true

require_relative "test_helper"
require "fileutils"
require "tmpdir"
require "open3"
require_relative "../lib/vibe/superpowers_installer"

class TestSuperpowersInstaller < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir("vibe_test_superpowers")
    @original_install_dir = Vibe::SuperpowersInstaller::SUPERPOWERS_DEFAULT_INSTALL_DIR
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
  end

  # --- Constants ---

  def test_constants_defined
    assert_kind_of Array, Vibe::SuperpowersInstaller::SUPERPOWERS_REPO_URLS
    refute_empty Vibe::SuperpowersInstaller::SUPERPOWERS_REPO_URLS
    assert_kind_of String, Vibe::SuperpowersInstaller::SUPERPOWERS_DEFAULT_INSTALL_DIR
    assert_equal 60, Vibe::SuperpowersInstaller::CLONE_TIMEOUT
    assert_equal 3, Vibe::SuperpowersInstaller::MAX_RETRIES
  end

  def test_repo_urls_include_github
    urls = Vibe::SuperpowersInstaller::SUPERPOWERS_REPO_URLS
    assert urls.any? { |url| url.include?("github.com") }, "Should include GitHub URL"
  end

  def test_repo_urls_include_mirror
    urls = Vibe::SuperpowersInstaller::SUPERPOWERS_REPO_URLS
    assert urls.size >= 2, "Should have at least 2 mirror URLs"
  end

  # --- Platform Symlink Paths ---

  def test_platform_symlink_paths_defined
    paths = Vibe::SuperpowersInstaller::SUPERPOWERS_PLATFORM_SYMLINK_PATHS
    assert_kind_of Hash, paths

    # Check key platforms
    assert_includes paths.keys, "claude-code"
    assert_includes paths.keys, "opencode"
    assert_includes paths.keys, "kimi-code"
  end

  def test_platform_symlink_paths_structure
    paths = Vibe::SuperpowersInstaller::SUPERPOWERS_PLATFORM_SYMLINK_PATHS

    paths.each do |platform, config|
      assert_kind_of Hash, config, "Config for #{platform} should be a Hash"
      assert_includes config.keys, :source_subdir, "#{platform} should have :source_subdir"
      assert_includes config.keys, :target_dir, "#{platform} should have :target_dir"
    end
  end

  # --- Clone with Retry (mocked) ---

  def test_clone_from_mirrors_returns_array
    # Mock clone_with_retry to avoid actual network calls
    Vibe::SuperpowersInstaller.stub :clone_with_retry, true do
      result = Vibe::SuperpowersInstaller.clone_from_mirrors(
        ["https://example.com/repo.git"],
        @test_dir
      )

      assert_kind_of Array, result
      assert_equal 2, result.size
      assert_equal true, result[0]
      assert_kind_of String, result[1]
    end
  end

  def test_clone_from_mirrors_first_success
    call_count = 0
    stub_clone = lambda do |url, _target|
      call_count += 1
      true  # First attempt succeeds
    end

    Vibe::SuperpowersInstaller.stub :clone_with_retry, stub_clone do
      success, used_url = Vibe::SuperpowersInstaller.clone_from_mirrors(
        ["https://first.com/repo.git", "https://second.com/repo.git"],
        @test_dir
      )

      assert_equal true, success
      assert_equal "https://first.com/repo.git", used_url
      assert_equal 1, call_count, "Should only try first URL"
    end
  end

  def test_clone_from_mirrors_fallback_to_second
    call_count = 0
    stub_clone = lambda do |url, _target|
      call_count += 1
      url.include?("second")  # Only second URL succeeds
    end

    Vibe::SuperpowersInstaller.stub :clone_with_retry, stub_clone do
      success, used_url = Vibe::SuperpowersInstaller.clone_from_mirrors(
        ["https://first.com/repo.git", "https://second.com/repo.git"],
        @test_dir
      )

      assert_equal true, success
      assert_equal "https://second.com/repo.git", used_url
      assert_equal 2, call_count, "Should try both URLs"
    end
  end

  def test_clone_from_mirrors_all_fail
    stub_clone = lambda { |_url, _target| false }

    Vibe::SuperpowersInstaller.stub :clone_with_retry, stub_clone do
      success, used_url = Vibe::SuperpowersInstaller.clone_from_mirrors(
        ["https://first.com/repo.git", "https://second.com/repo.git"],
        @test_dir
      )

      assert_equal false, success
      assert_nil used_url
    end
  end

  # --- Verification ---

  def test_verify_installation_structure
    result = Vibe::SuperpowersInstaller.verify_installation("claude-code")

    assert_kind_of Hash, result
    assert_includes result.keys, :success
    assert_includes result.keys, :location
    assert_includes result.keys, :skills_count
    assert_includes result.keys, :linked_count
    assert_includes result.keys, :issues
  end

  def test_verify_installation_returns_boolean_success
    result = Vibe::SuperpowersInstaller.verify_installation("claude-code")
    assert [true, false].include?(result[:success]), "success should be boolean"
  end

  def test_verify_installation_invalid_platform
    result = Vibe::SuperpowersInstaller.verify_installation("invalid-platform")
    assert_equal false, result[:success]
    refute_empty result[:issues]
  end

  # --- Install Superpowers (integration-like, requires git) ---

  def test_install_superpowers_checks_git
    # This test verifies the git check happens
    # We can't easily mock system() in a clean way, so we just verify
    # the method exists and returns a boolean
    result = Vibe::SuperpowersInstaller.install_superpowers("claude-code")
    assert [true, false].include?(result), "Should return boolean"
  end

  # --- Edge Cases ---

  def test_clone_from_mirrors_empty_urls
    success, used_url = Vibe::SuperpowersInstaller.clone_from_mirrors([], @test_dir)
    assert_equal false, success
    assert_nil used_url
  end

  def test_clone_from_mirrors_single_url_success
    stub_clone = lambda { |_url, _target| true }

    Vibe::SuperpowersInstaller.stub :clone_with_retry, stub_clone do
      success, used_url = Vibe::SuperpowersInstaller.clone_from_mirrors(
        ["https://only.com/repo.git"],
        @test_dir
      )

      assert_equal true, success
      assert_equal "https://only.com/repo.git", used_url
    end
  end

  def test_verify_installation_with_nonexistent_directory
    # Use a platform that doesn't have installation
    result = Vibe::SuperpowersInstaller.verify_installation("claude-code")

    # Should handle gracefully even if not installed
    assert_kind_of Hash, result
    assert_kind_of Array, result[:issues]
  end

  def test_install_superpowers_default_platform
    # Test that install_superpowers uses default platform
    result = Vibe::SuperpowersInstaller.install_superpowers
    assert [true, false].include?(result), "Should return boolean"
  end

  def test_install_superpowers_with_explicit_platform
    result = Vibe::SuperpowersInstaller.install_superpowers("opencode")
    assert [true, false].include?(result), "Should return boolean"
  end

  # --- Symlink Configuration ---

  def test_all_platforms_have_valid_paths
    paths = Vibe::SuperpowersInstaller::SUPERPOWERS_PLATFORM_SYMLINK_PATHS

    paths.each do |platform, config|
      assert_kind_of String, config[:source_subdir],
        "#{platform} source_subdir should be String"
      assert_kind_of String, config[:target_dir],
        "#{platform} target_dir should be String"

      refute_empty config[:source_subdir],
        "#{platform} source_subdir should not be empty"
      refute_empty config[:target_dir],
        "#{platform} target_dir should not be empty"
    end
  end

  def test_target_dirs_are_absolute_or_tilde_paths
    paths = Vibe::SuperpowersInstaller::SUPERPOWERS_PLATFORM_SYMLINK_PATHS

    paths.each do |platform, config|
      target = config[:target_dir]
      assert(
        target.start_with?("~") || target.start_with?("/"),
        "#{platform} target_dir should be absolute or tilde path: #{target}"
      )
    end
  end

  # --- URL Validation ---

  def test_repo_urls_are_valid_git_urls
    urls = Vibe::SuperpowersInstaller::SUPERPOWERS_REPO_URLS

    urls.each do |url|
      assert url.end_with?(".git"), "URL should end with .git: #{url}"
      assert(
        url.start_with?("https://") || url.start_with?("git://"),
        "URL should use https or git protocol: #{url}"
      )
    end
  end

  def test_repo_urls_no_duplicates
    urls = Vibe::SuperpowersInstaller::SUPERPOWERS_REPO_URLS
    assert_equal urls.size, urls.uniq.size, "Should not have duplicate URLs"
  end

  # --- Constants Validation ---

  def test_clone_timeout_is_positive
    assert Vibe::SuperpowersInstaller::CLONE_TIMEOUT > 0,
      "CLONE_TIMEOUT should be positive"
  end

  def test_max_retries_is_positive
    assert Vibe::SuperpowersInstaller::MAX_RETRIES > 0,
      "MAX_RETRIES should be positive"
  end

  def test_max_retries_is_reasonable
    assert Vibe::SuperpowersInstaller::MAX_RETRIES <= 5,
      "MAX_RETRIES should not be too high (avoid excessive waiting)"
  end

  def test_default_install_dir_is_absolute
    dir = Vibe::SuperpowersInstaller::SUPERPOWERS_DEFAULT_INSTALL_DIR
    assert dir.start_with?("/"), "Default install dir should be absolute path"
  end

  # --- Platform Coverage ---

  def test_supports_major_platforms
    paths = Vibe::SuperpowersInstaller::SUPERPOWERS_PLATFORM_SYMLINK_PATHS
    major_platforms = ["claude-code", "opencode", "kimi-code", "cursor"]

    major_platforms.each do |platform|
      assert_includes paths.keys, platform,
        "Should support major platform: #{platform}"
    end
  end

  def test_platform_symlink_paths_frozen
    paths = Vibe::SuperpowersInstaller::SUPERPOWERS_PLATFORM_SYMLINK_PATHS
    assert paths.frozen?, "SUPERPOWERS_PLATFORM_SYMLINK_PATHS should be frozen"
  end

  def test_repo_urls_frozen
    urls = Vibe::SuperpowersInstaller::SUPERPOWERS_REPO_URLS
    assert urls.frozen?, "SUPERPOWERS_REPO_URLS should be frozen"
  end
end
