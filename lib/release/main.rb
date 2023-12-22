# frozen_string_literal: true

#  Copyright (c) 2020-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative './tooling'
require_relative './highlevel'
require_relative './lowlevel'
require_relative './world_monad'
require_relative './commands'

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
#   - tx
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
# - WAGONS='space separated list of wagons'
#   select which wagons are handled
#
class Release::Main
  include Release::Tooling
  include Release::Highlevel
  include Release::Lowlevel
  include Release::WorldMonad
  include Release::Commands

  attr_reader :all_wagons, :wagon, :command_list
  attr_writer :composition_repo_dir, :hitobito_group_dir, :standard_answer, :stage
  attr_accessor :dry_run, :version, :message

  def initialize(all_wagons)
    self.all_wagons = all_wagons
    @standard_answer = nil
    @stage = :production

    notify 'Running in dry-run mode' if dry_run?
  end

  def usable?
    version_present? &&
      message_present? &&
      wagons_present? &&
      composition_known? &&
      helpers_present?
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

  def version_present?
    !@version.nil?
  end

  def message_present?
    !@message.nil?
  end

  def wagons_present?
    @all_wagons.is_a?(Array) && ENV['WAGONS'].split(' ').any?
  end

  def composition_known?
    !@composition_repo_dir&.empty? || !@wagon&.empty? # emulate .present?
  end

  def helpers_present?
    %w(git sed tx)
      .map { |cmd| `command -v #{cmd} > /dev/null && echo 'found'`.chomp }
      .reduce(true) { |memo, result| memo && result == 'found' }
  end
end
