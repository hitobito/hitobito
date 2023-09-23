# frozen_string_literal: true

#  Copyright (c) 2023-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# rubocop:disable Rails

module Release
  module Commands
    # rubocop:disable Metrics/BlockLength
    def update_production # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      with_env({ 'OVERCOMMIT_DISABLE' => '1' }) do
        in_dir(hitobito_group_dir) do
          notify "Releasing #{@all_wagons.join(', ')}"
          @message ||= new_version_message

          notify @message

          in_dir('hitobito') do
            break if existing_version_again?

            update_translations
            update_changelog
            update_version file: 'VERSION'

            release_version @version
          end

          @all_wagons.each do |wagon|
            in_dir("hitobito_#{wagon}") do
              break if existing_version_again?

              update_translations
              update_changelog
              update_version file: "lib/hitobito_#{wagon}/version.rb"
              release_version @version
            end
          end

          in_dir(composition_repo_dir) do
            unless working_in_composition_dir?
              fetch_code_and_tags
              update_submodules(branch: 'production')
            end

            update_submodule_content(to: @version)
            record_submodule_state
            release_version @version
          end

          # if confirm(question: 'Add an unreleased-section to the CHANGELOGs again?')
          #   prepare_next_version
          # end
        end
      end
    end

    def update_integration # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      with_env({ 'OVERCOMMIT_DISABLE' => '1' }) do
        in_dir(hitobito_group_dir) do
          notify "Updating #{@all_wagons.join(', ')}"
          @message ||= new_version_message
          notify @message

          ['hitobito', *(@all_wagons.map { |wgn| "hitobito_#{wgn}" })].each do |dir|
            in_dir(dir) do
              update_translations
              push
            end
          end

          in_dir(composition_repo_dir) do
            unless working_in_composition_dir?
              fetch_code_and_tags
              update_submodules(branch: 'devel')
            end

            update_submodule_content(to: 'master')
            record_submodule_state
            push
          end
        end
      end
    end
    # rubocop:enable Metrics/BlockLength

    def current_version(stage = :production)
      `#{tag_lookup_cmd(stage)} | head -n 1`.chomp
    end

    def next_integration_version
      prod = current_version(:production)

      day_counter = days_since(prod)
      new_int = "#{prod}-#{day_counter}"

      if all_versions(:integration).include?(new_int)
        "#{new_int}-#{current_sha}"
      else
        new_int
      end
    end

    def next_version(style = :patch) # rubocop:disable Metrics/MethodLength
      incrementor = \
        case style.to_sym
        when :patch
          ->(parts) { parts[0..1] + [parts[2].succ] }
        when :current_month
          ->(parts) do
            current_month = Date.today.strftime('%Y-%m')
            parts[0..1] + [current_month]
          end
        end

      current_version(:production).split('.').then { |parts| incrementor[parts] }.join('.')
    end

    private

    def days_since(version)
      tag_date = `git log #{version} -1 --format="%ct"`.chomp
      (Time.now.utc.to_date - Time.at(tag_date.to_i).to_date).to_i
    end

    def current_sha
      `git rev-parse --short HEAD`
    end

    def all_versions(stage = :production)
      `#{tag_lookup_cmd(stage)}`.chomp.split
    end

    def tag_lookup_cmd(stage)
      "git tag --sort=-committerdate --list | grep -E '#{version_grep_pattern(stage)}'"
    end

    def version_grep_pattern(stage)
      case stage
      when :production  then '^[0-9][0-9.]+$' # 1.30.6
      when :integration then '^[0-9][0-9.]+-[0-9]+.*$' # 1.30.6-26 or 1.30.6-123-33b8937
      end
    end
  end
end

# rubocop:enable Rails
