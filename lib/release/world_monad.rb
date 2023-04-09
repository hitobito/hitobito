# frozen_string_literal: true

#  Copyright (c) 2020-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Release
  # internal central place to get input, send output or execute commands
  #
  # rubocop:disable Rails/Output this is not run inside rails
  module WorldMonad
    private

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

      if dry_run? || @assume_yes
        puts '-> assuming yes, due to dry-run or setting'
        return true
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
      result = execute cmd
      message = result ? success : failure

      visual_prefix = ' ->'
      puts [visual_prefix, message].compact.join(' ')

      result
    end

    def execute(cmd)
      visual_prefix = '==>' unless command_list?
      puts [visual_prefix, cmd].compact.join(' ')

      return true if dry_run?

      system(cmd).tap do |result|
        visual_prefix = ' ->'
        visual_suffix = result ? cmd_success : cmd_error
        puts [visual_prefix, cmd, visual_suffix].compact.join(' ')
      end
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
