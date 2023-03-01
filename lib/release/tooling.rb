# frozen_string_literal: true

module Release
  # preparatory help-tooling
  module Tooling
    private

    def current_version
      `git tag | grep '^[0-9]' | sort -Vr | head -n 1`.chomp
    end

    def all_versions
      `git tag | grep '^[0-9]'`.chomp.split
    end

    def determine_version
      return ENV['VERSION'] unless ENV['VERSION'].to_s.empty?

      suggestion = current_version
                   .split('.')
                   .yield_self { |parts| parts[0..-2] + [parts.last.succ] }
                   .join('.')

      ask('Next Version: ', suggestion)
    end

    def new_version_message
      "Update production to #{@version}"
    end

    def with_env(env_hash)
      previous = ENV.select { |env_key| env_hash.keys.include? env_key }
      env_hash.each { |key, value| ENV[key] = value.to_s }

      result = yield

      previous.each { |key, value| ENV[key] = value }

      result
    end

    def cli
      @cli ||= begin
        require 'highline'
        HighLine.new
      rescue LoadError
        abort(<<~MESSAGE)
          Please install "highline" to unlock the interactivity of this script
        MESSAGE
      end
    end

    def colorize
      @colorize ||= begin
        require 'pastel'
        Pastel.new
      rescue LoadError
        abort(<<~MESSAGE)
          Please install "pastel" to unlock colorized output of this script
        MESSAGE
      end
    end
  end
end
