# frozen_string_literal: true

#  Copyright (c) 2020-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative './tooling'
require_relative './highlevel'
require_relative './lowlevel'
require_relative './world_monad'

# Wrapper around some shell-commands needed to release a new version of
# hitobito to production
#
# This script expects:
#
# 1. several programs in place and working
#   - git
#   - sed
#   - echo
#   - bash
#   - ruby
#
# 2. some aspects about your setup
#   - the transifex-client is installed and configured
#   - you are on linux (with a GNU sed)
#   - you have push access to the repositories
#   - you have a somewhat recent git (so that submodule foreach works)
#
# 3. work you did before
#   - each wagon/repo is in the state you want to release
#   - everything that should be released is committed
#
# 4. work you will do after
#   - the actual deployment is not managed (yet?)
#   - you need to start the jenkins-job
#   - or trigger things manually on openshift
#   - make sure that openshift is configured for what you want to release
#
# This script does not:
# - manage integration releases
# - trigger jenkins
# - pull, commit or manage code other than version-files and translations
#
# The following environment-variables are recognized
# - DRY_RUN=true
#   prevents execution of commands
# - COMMAND_LIST=true
#   sets DRY_RUN=true and outputs all commands
# - WAGON='space separated list of wagons'
#   select which wagons are handled
# - VERSION=anything
#   new version-number. skips calculating next version and the confirmation-question
#
class Release::Main
  include Release::Tooling
  include Release::Highlevel
  include Release::Lowlevel
  include Release::WorldMonad

  attr_reader :all_wagons, :wagon, :command_list
  attr_writer :composition_repo_dir, :hitobito_group_dir, :standard_answer
  attr_accessor :dry_run, :version

  def initialize(all_wagons)
    self.all_wagons = all_wagons
    @standard_answer = nil

    notify 'Running in dry-run mode' if dry_run?
  end

  def usable?
    !@version.nil? &&
      @all_wagons.is_a?(Array) &&
      ENV['WAGONS'].split(' ').any?
  end

  def usage!
    abort("USAGE: #{$PROGRAM_NAME} $WAGONS or WAGONS='wagon1 wagon2' #{$PROGRAM_NAME}")
  end

  def untranslated_wagons
    %w(cevi jubla)
  end

  def first_wagon=(first_wagon)
    self.all_wagons = sort_wagons(@all_wagons, first_wagon)

    @wagon # rubocop:disable Lint/Void a return value is not void
  end

  def all_wagons=(all_wagons)
    @all_wagons = all_wagons
    ENV['WAGONS'] ||= @all_wagons.to_a.join(' ') # make sure it is present

    @wagon = @all_wagons.first

    @all_wagons # rubocop:disable Lint/Void a return value is not void
  end

  def run
    with_env({ 'OVERCOMMIT_DISABLE' => '1' }) do
      in_dir(hitobito_group_dir) do
        # @all_wagons += infer_wagons if @all_wagons.one?
        notify "Releasing #{@all_wagons.join(', ')}"
        @message = new_version_message

        # in_dir('hitobito') do
        #   fetch_code_and_tags
        #   @version = determine_version
        #   @message = new_version_message
        # end
        notify @message

        prepare_core
        prepare_wagons
        update_composition

        # if confirm(question: 'Add an unreleased-section to the CHANGELOGs again?')
        #   prepare_next_version
        # end
      end
    end
  end

  def prepare_core
    in_dir('hitobito') do
      break if existing_version_again?

      update_translations
      update_changelog
      update_version file: 'VERSION'

      release_version @version
    end
  end

  def prepare_wagons
    @all_wagons.each do |wagon|
      in_dir("hitobito_#{wagon}") do
        break if existing_version_again?

        update_translations unless untranslated_wagons.include?(wagon)
        update_changelog
        update_version file: "lib/hitobito_#{wagon}/version.rb"
        release_version @version
      end
    end
  end

  def update_composition
    in_dir(composition_repo_dir) do
      unless working_in_composition_dir?
        fetch_code_and_tags
        update_submodules(branch: 'production')
      end

      update_submodule_content(to: @version)
      record_submodule_state
      release_version @version
    end
  end

  def prepare_next_version
    @all_wagons
      .map { |wagon| "hitobito_#{wagon}" }
      .prepend('hitobito')
      .each do |dir|
        in_dir(dir) do
          prepare_changelog
          execute 'git push origin'
        end
      end
  end

  def command_list=(setting)
    @dry_run = true if setting

    @command_list = !!setting
  end

  def composition_repo_dir
    @composition_repo_dir ||= "ose_composition_#{@wagon}"
  end

  def hitobito_group_dir
    @hitobito_group_dir ||= File.expand_path('../../../..', __dir__)
  end

  private

  # def infer_wagons
  #   [].tap do |wagons|
  #     in_dir("hitobito_#{@wagon}") do
  #       wagons << Gem::Specification.load("hitobito_#{@wagon}.gemspec")
  #                                   .dependencies
  #                                   .flat_map { |dep| dep.name.scan(/hitobito_(\w+)/).first }
  #                                   .compact
  #     end
  #   end.flatten.compact
  # end

  # well, do not execute, just output what would be done
  def dry_run?
    return @dry_run unless @dry_run.nil?

    false
  end

  # make output copy/pasteable
  def command_list?
    return @command_list unless @command_list.nil?

    false
  end

  def working_in_composition_dir?
    composition_repo_dir == hitobito_group_dir
  end
end
