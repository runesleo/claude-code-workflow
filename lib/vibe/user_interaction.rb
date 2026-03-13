# frozen_string_literal: true

require_relative "errors"

module Vibe
  # User interaction utilities for CLI prompts and input handling.
  #
  # Host requirements:
  #   None (self-contained utilities)
  module UserInteraction
    NON_INTERACTIVE_HINT = "Re-run `bin/vibe init` in an interactive terminal, " \
                           "use `bin/vibe init --verify` to inspect current state, " \
                           "or follow `docs/integrations.md` for manual installation steps."

    # Open URL in default browser (cross-platform)
    # @param url [String] URL to open
    def open_url(url)
      case RbConfig::CONFIG["host_os"]
      when /darwin/
        system("open", url)
      when /linux/
        system("xdg-open", url)
      when /mswin|mingw|cygwin/
        system("start", url)
      else
        puts "Please visit: #{url}"
      end
    end

    # Ask yes/no question with default to no
    # @param question [String] Question to display
    # @return [Boolean] true if user answered yes, false otherwise
    # @raise [ValidationError] if input ends before response (EOF)
    def ask_yes_no(question)
      print "#{question} [y/N] "
      response = $stdin.gets
      if response.nil?
        raise ValidationError,
              "Input ended before a response was provided for '#{question}'. #{NON_INTERACTIVE_HINT}"
      end
      ["y", "yes"].include?(response.chomp.downcase)
    end

    # Ask user to choose from valid options
    # @param prompt [String] Prompt to display
    # @param valid_choices [Array<String>] Valid choices
    # @return [String] User's choice
    def ask_choice(prompt, valid_choices)
      ensure_interactive_setup_available!(prompt)
      loop do
        print "#{prompt}: "
        choice = read_prompt_response!(prompt).strip

        return choice if valid_choices.include?(choice)

        puts "   Invalid choice. Please choose from: #{valid_choices.join(', ')}"
      end
    end

    # Ensure interactive terminal is available for setup
    # @param prompt [String, nil] Optional prompt context for error message
    # @raise [ValidationError] if not running in interactive terminal
    def ensure_interactive_setup_available!(prompt = nil)
      return if $stdin.respond_to?(:tty?) && $stdin.tty?

      detail = prompt ? " when prompting for '#{prompt}'" : ""
      raise ValidationError,
            "bin/vibe init requires an interactive terminal#{detail}. #{NON_INTERACTIVE_HINT}"
    end

    private

    # Read response from prompt with EOF handling
    # @param prompt [String] Prompt context for error message
    # @return [String] User input
    # @raise [ValidationError] if input ends before response
    def read_prompt_response!(prompt)
      response = $stdin.gets
      return response unless response.nil?

      raise ValidationError,
            "Input ended before a response was provided for '#{prompt}'. #{NON_INTERACTIVE_HINT}"
    end
  end
end
