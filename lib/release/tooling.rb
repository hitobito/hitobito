# frozen_string_literal: true

#  Copyright (c) 2020-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Release
  # preparatory help-tooling
  module Tooling
    private

    def sort_wagons(all_wagons, first_wagon)
      all_wagons.reject { |wgn| wgn == first_wagon }.prepend(first_wagon)
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

    # rubocop:disable all
    def colorize
      @colorize ||= begin
        require 'pastel'
        Pastel.new(enabled: ENV.fetch('CI', false))
      rescue LoadError
        puts 'Please install "pastel" if you want to unlock colorized output of this script.'

        Class.new do
          def method_missing(_m, *args, &_block)
            @text = args[0] if args.kind_of?(Array)
            self
          end

          def to_s
            @text
          end

          def to_str
            @text
          end

          def to_ary
            [@text]
          end
        end.new
      end
    end
  end
end
