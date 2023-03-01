#!/usr/bin/env ruby
# frozen_string_literal: true

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
#   - rake
#   - sed
#   - echo
#   - bash
#
# 2. some aspects about your setup
#   - when entering a directory, no extra steps are needed to run rake-tasks
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

  attr_reader :all_wagons, :wagon

  def self.from_composition(composition)
    releaser = new([])
    releaser.determine_wagons(composition)
    releaser
  end

  def initialize(all_wagons)
    self.all_wagons = all_wagons

    notify 'Running in dry-run mode' if dry_run?
  end

  def usable?
    @all_wagons.is_a?(Array) && ENV['WAGONS'].split(' ').any?
  end

  def usage!
    abort("USAGE: #{$PROGRAM_NAME} $WAGONS or WAGONS='wagon1 wagon2' #{$PROGRAM_NAME}")
  end

  def untranslated_wagons
    %w[cevi jubla]
  end

  def all_wagons=(all_wagons)
    @all_wagons = all_wagons
    ENV['WAGONS'] ||= @all_wagons.to_a.join(' ') # make sure it is present

    @wagon = @all_wagons.first

    @all_wagons
  end

  def determine_wagons(composition)
    in_dir(hitobito_group_dir) do
      in_dir("ose_composition_#{composition}") do
        require 'pathname'

        self.all_wagons = Pathname.new('.').children.flat_map { |dep| dep.to_s.scan(/hitobito_(\w+)/).first }.compact
      end
    end
  end

  def run # rubocop:disable Metrics/MethodLength
    with_env({ 'OVERCOMMIT_DISABLE' => '1' }) do
      in_dir(hitobito_group_dir) do
        @all_wagons += infer_wagons if @all_wagons.one?
        notify "Releasing #{@all_wagons.join(', ')}"

        in_dir('hitobito') do
          fetch_code_and_tags
          @version = determine_version
          @message = new_version_message
        end

        prepare_core
        prepare_wagons
        update_composition

        # prepare_next_version if confirm(question: 'Add an unreleased-section to the CHANGELOGs again?')
      end
    end
  end

  def infer_wagons
    [].tap do |wagons|
      in_dir("hitobito_#{@wagon}") do
        wagons << Gem::Specification.load("hitobito_#{@wagon}.gemspec")
                                    .dependencies
                                    .flat_map { |dep| dep.name.scan(/hitobito_(\w+)/).first }.compact
      end
    end.flatten.compact
  end

  def prepare_core
    in_dir('hitobito') do
      break if existing_version_again?

      update_translations 'tx:pull'
      update_changelog
      update_version file: 'VERSION'

      release_version @version
    end
  end

  def prepare_wagons
    @all_wagons.each do |wagon|
      in_dir("hitobito_#{wagon}") do
        break if existing_version_again?

        update_translations 'app:tx:pull' unless untranslated_wagons.include?(wagon)
        update_changelog
        update_version file: "lib/hitobito_#{wagon}/version.rb"
        release_version @version
      end
    end
  end

  def update_composition
    in_dir("ose_composition_#{@wagon}") do
      fetch_code_and_tags
      update_submodules(branch: 'production')
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

  private

  def hitobito_group_dir
    if File.directory?("./ose_composition_#{@wagon}")
      Dir.pwd
    else
      File.expand_path('../..', __dir__)
    end
  end

  # well, do not execute, just output what would be done
  def dry_run?
    ENV['DRY_RUN'] == 'true' || false
  end

  # make output copy/pasteable
  def command_list?
    return false unless ENV['COMMAND_LIST'] == 'true'

    ENV['DRY_RUN'] = 'true'
    true
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    all_wagons = (ENV['WAGONS'] || ARGV.join(' ')).to_s.split(' ')
    # release = Release::Main.from_composition(all_wagons&.first)
    release = Release::Main.new(all_wagons)
    release.usage! unless release.usable?

    release.run
  rescue StandardError
    puts release.inspect
    raise
  end
end
