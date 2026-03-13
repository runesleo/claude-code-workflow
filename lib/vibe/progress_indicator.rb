# frozen_string_literal: true

module Vibe
  # Progress indicator for long-running operations
  #
  # Usage:
  #   progress = ProgressIndicator.new("Loading skills")
  #   progress.start
  #   # ... do work ...
  #   progress.update(50, "Halfway done")
  #   # ... do more work ...
  #   progress.finish("Complete!")
  #
  class ProgressIndicator
    attr_reader :title, :current, :total, :start_time

    def initialize(title, total = nil)
      @title = title
      @total = total
      @current = 0
      @start_time = nil
      @running = false
    end

    # Start the progress indicator
    def start
      @start_time = Time.now
      @running = true
      @current = 0

      if tty?
        print "#{@title}..."
        $stdout.flush
      else
        puts "#{@title}..."
      end
    end

    # Update progress
    #
    # @param current [Integer] Current progress (if total set)
    # @param message [String] Optional status message
    def update(current = nil, message = nil)
      return unless @running

      @current = current if current

      if tty? && @total
        percentage = (@current.to_f / @total * 100).round
        bar = progress_bar(percentage)
        elapsed = Time.now - @start_time
        eta = calculate_eta(elapsed)

        print "\r#{@title}: #{bar} #{percentage}% (#{@current}/#{@total})"
        print " - #{message}" if message
        print " [ETA: #{eta}]" if eta
        $stdout.flush
      elsif message
        puts "  #{message}"
      end
    end

    # Increment progress by 1
    def increment(message = nil)
      update(@current + 1, message)
    end

    # Finish the progress indicator
    #
    # @param message [String] Final message
    def finish(message = "Complete")
      return unless @running

      elapsed = Time.now - @start_time
      duration = format_duration(elapsed)

      if tty?
        if @total
          bar = progress_bar(100)
          puts "\r#{@title}: #{bar} 100% (#{@total}/#{@total}) - #{message} (#{duration})"
        else
          puts "\r#{@title}... #{message} (#{duration})"
        end
      else
        puts "#{@title}: #{message} (#{duration})"
      end

      @running = false
    end

    # Show spinner for indeterminate progress
    #
    # @yield Block to execute
    def with_spinner
      start
      spinner_thread = Thread.new { run_spinner }

      begin
        result = yield
        finish("Done")
        result
      rescue StandardError => e
        finish("Failed")
        raise e
      ensure
        spinner_thread.kill if spinner_thread
      end
    end

    # Show progress bar for determinate progress
    #
    # @param total [Integer] Total items
    # @yield Block to execute with progress updates
    def with_progress(total)
      @total = total
      start

      begin
        result = yield(self)
        finish("Done")
        result
      rescue StandardError => e
        finish("Failed")
        raise e
      end
    end

    private

    def tty?
      $stdout.respond_to?(:tty?) && $stdout.tty?
    end

    def progress_bar(percentage, width = 30)
      filled = (width * percentage / 100.0).round
      empty = width - filled

      "[#{('=' * filled)}#{'>' if filled < width && percentage > 0}#{'.' * [empty - 1, 0].max}]"
    end

    def calculate_eta(elapsed)
      return nil unless @total && @current > 0

      rate = @current.to_f / elapsed
      remaining = @total - @current
      eta_seconds = remaining / rate

      format_duration(eta_seconds)
    end

    def format_duration(seconds)
      if seconds < 1
        "#{ (seconds * 1000).round }ms"
      elsif seconds < 60
        "#{seconds.round(1)}s"
      else
        minutes = (seconds / 60).floor
        secs = (seconds % 60).round
        "#{minutes}m#{secs}s"
      end
    end

    def run_spinner
      chars = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
      i = 0

      while @running
        char = chars[i % chars.length]
        print "\r#{@title} #{char}"
        $stdout.flush
        i += 1
        sleep 0.1
      end
    end
  end

  # Module-level helper methods
  module ProgressHelpers
    # Show progress for an enumerable
    #
    # @param enumerable [Enumerable] Collection to iterate
    # @param title [String] Progress title
    # @yield Block to execute for each item
    def with_progress(enumerable, title = "Processing")
      items = enumerable.to_a
      indicator = ProgressIndicator.new(title, items.length)

      indicator.with_progress(items.length) do |progress|
        items.each do |item|
          yield item
          progress.increment
        end
      end
    end

    # Show spinner while executing block
    #
    # @param title [String] Spinner title
    # @yield Block to execute
    def with_spinner(title = "Loading")
      indicator = ProgressIndicator.new(title)
      indicator.with_spinner { yield }
    end
  end
end
