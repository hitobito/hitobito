# frozen_string_literal: true

#  Copyright (c) 2023-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'pathname'
require_relative './main'

module Release
  class UpdateCommand < CmdParse::Command
    # Encapsulate the common things of a release-command, the name is used
    # for messages and descriptions.
    #
    # releaser_method should be one of
    # - update_integration
    # - update_production
    #
    # These are defined in the module Release::Commands
    def initialize(name, releaser_method)
      super(name, takes_commands: false)
      short_desc("Prepare composition-repo for #{name}-release")

      @releaser_method = releaser_method
    end

    def execute(version) # rubocop:disable Metrics/AbcSize
      releaser = Release::Main.new(all_wagons)

      releaser.hitobito_group_dir = releaser.composition_repo_dir = dir
      releaser.version            = version
      releaser.stage              = name.to_sym
      releaser.message            = "Update #{name} to #{version}"
      releaser.dry_run            = command_parser.data[:dry_run]
      releaser.command_list       = command_parser.data[:command_list]
      releaser.standard_answer    = true

      raise unless releaser.usable?

      releaser.send(@releaser_method.to_sym)
    end

    private

    def dir
      @dir ||= File.expand_path('../../..', __dir__)
    end

    def all_wagons
      Pathname.new(dir).children.flat_map do |dep|
        dep.to_s.scan(/hitobito_(\w+)/).first
      end.compact
    end
  end
end
