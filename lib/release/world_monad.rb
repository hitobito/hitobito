# frozen_string_literal: true

#  Copyright (c) 2020-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'English'

module Release
  # internal central place to get input, send output or execute commands
  #
  # rubocop:disable Rails/Output this is not run inside rails
  module WorldMonad
    private

    def current_version(stage = :production)
      case stage.to_sym
      when :production then `version current production`
      when :integration then `version current integration`
      else
        raise 'Unsupported stage, should be production or integration'
      end.chomp.split
    end

    def all_versions(stage = :production)
      case stage.to_sym
      when :production then `version all production`
      when :integration then `version all integration`
      else
        raise 'Unsupported stage, should be production or integration'
      end.chomp.split
    end

    def ask(question, default)
      cli.ask(question) { |q| q.default = default }.chomp
    end

    def notify(message, prefix_only: false)
      if prefix_only
        puts colorize.cyan("= #{message}")
      else
        puts colorize.yellow("== #{message} ==") unless command_list?
      end
    end

    def confirm(question: 'continue?') # rubocop:disable Metrics/MethodLength
      puts "#{question} [Yn]"

      if dry_run? || @standard_answer == true
        puts '-> assuming yes, due to dry-run or setting'
        return true
      end
      if @standard_answer == false
        puts '-> assuming no, due to setting'
        return false
      end

      answer = begin
        $stdin.gets.chomp.downcase
      rescue Interrupt
        'n'
      end

      ['y', ''].include? answer
    end

    def confirm_and_execute(cmd, question: 'continue?')
      execute cmd if confirm(question: question)
    end

    def execute_check(cmd, success: 'so it seems', failure: 'not the case')
      result = execute cmd, allow_failure: true
      message = result ? success : failure

      visual_prefix = ' ->'
      puts [visual_prefix, message, cmd_success].compact.join(' ')

      result
    end

    def execute(cmd, allow_failure: false)
      visual_prefix = '==>' unless command_list?
      puts [visual_prefix, cmd].compact.join(' ')

      return true if dry_run?

      system(cmd).tap do |result|
        visual_prefix = ' ->'
        visual_suffix = result ? cmd_success : cmd_error
        puts [visual_prefix, cmd, visual_suffix].compact.join(' ')
      end.then { |result| handle_result(result, allow_failure: allow_failure) } # rubocop:disable Style/MultilineBlockChain
    end

    def handle_result(result, allow_failure: false)
      return true if result == true
      return result if allow_failure

      case result
      when false then warn 'Command exited with a non-zero exit-code'
      when nil then warn 'Command failed'
      end

      warn "Exitstatus: #{$CHILD_STATUS}"
      abort
    end

    def cmd_success
      colorize.green.bold('✓')
    end

    def cmd_error
      colorize.red.bold('⛌')
    end
  end
  # rubocop:enable Rails/Output
end
